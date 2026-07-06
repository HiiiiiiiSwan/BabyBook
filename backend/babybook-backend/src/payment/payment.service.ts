import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import axios from 'axios';
import { Order } from '../order/entities/order.entity';
import { OrderStatus } from '../common/enums';
import { VerifyPaymentDto, PaymentResponseDto } from './dto/payment.dto';
import { TaskService } from '../task/task.service';

/**
 * Apple IAP 验证响应
 */
interface AppleVerifyResponse {
  status: number;
  receipt?: any;
  latest_receipt_info?: any[];
  environment?: 'Sandbox' | 'Production';
}

@Injectable()
export class PaymentService {
  private readonly logger = new Logger(PaymentService.name);
  private readonly appleVerifyUrl: string;
  private readonly appleSandboxUrl: string;

  constructor(
    private configService: ConfigService,
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
    private taskService: TaskService,
  ) {
    // Apple 支付验证地址
    this.appleVerifyUrl = 'https://buy.itunes.apple.com/verifyReceipt';
    this.appleSandboxUrl = 'https://sandbox.itunes.apple.com/verifyReceipt';
  }

  /**
   * 获取订单信息（供控制器验证设备权限使用）
   */
  async getOrder(orderId: string): Promise<Order> {
    const order = await this.orderRepository.findOne({ where: { id: orderId } });
    if (!order) {
      throw new NotFoundException('订单不存在');
    }
    return order;
  }

  /**
   * 验证 Apple IAP 支付
   * 支付成功后自动创建生成任务
   */
  async verifyPayment(dto: VerifyPaymentDto): Promise<PaymentResponseDto> {
    const { orderId, receiptData, transactionId, imageUrl } = dto;

    // 1. 查询订单
    const order = await this.orderRepository.findOne({ where: { id: orderId } });
    if (!order) {
      throw new NotFoundException('订单不存在');
    }

    if (order.status !== OrderStatus.UNPAID) {
      throw new BadRequestException('订单状态不正确，无法重复支付');
    }

    // 2. 校验 transactionId 是否已被其他订单使用
    const existingOrder = await this.orderRepository.findOne({
      where: { paymentId: transactionId },
    });
    if (existingOrder) {
      throw new BadRequestException('该交易已完成支付，请勿重复提交');
    }

    // 3. 验证 Apple 收据
    const isValid = await this.verifyAppleReceipt(receiptData, transactionId);
    if (!isValid) {
      throw new BadRequestException('支付验证失败');
    }

    // 3. 更新订单状态为已支付
    order.status = OrderStatus.PAID;
    order.paymentId = transactionId;
    order.receiptData = receiptData;
    order.paidAt = new Date();
    if (imageUrl) {
      order.imageUrl = imageUrl;
    }

    await this.orderRepository.save(order);
    this.logger.log(`订单 ${orderId} 支付验证成功，交易ID: ${transactionId}`);

    // 4. 【关键】支付成功后自动创建生成任务
    // 这是业务核心要求：用户可能在支付后关闭 App、崩溃、断网、锁屏
    // 服务端自动创建任务确保生成流程不受影响
    try {
      await this.taskService.createTask(orderId);
      this.logger.log(`订单 ${orderId} 生成任务已自动创建`);
    } catch (error) {
      this.logger.error(`订单 ${orderId} 创建生成任务失败: ${error.message}`);
      // 即使任务创建失败，订单仍保持 PAID 状态，由定时任务重试
    }

    return {
      success: true,
      orderId: order.id,
      status: order.status,
    };
  }

  /**
   * 验证 Apple 收据
   * 支持 StoreKit2 JWS 收据（真机/Sandbox）和旧版 base64 receipt
   */
  private async verifyAppleReceipt(receiptData: string, transactionId: string): Promise<boolean> {
    try {
      // StoreKit2 真机/Sandbox 返回的是 JWS 格式（三段 base64url）
      // 先尝试解析 JWS payload 并校验 transactionId
      const jwtPayload = this.parseJWSPayload(receiptData);
      if (jwtPayload) {
        const jwtTransactionId = jwtPayload.transactionId || jwtPayload.originalTransactionId;
        if (jwtTransactionId === transactionId) {
          this.logger.log(`StoreKit2 JWS 收据校验通过，transactionId: ${transactionId}`);
          return true;
        }
        this.logger.warn(`JWS 中的 transactionId 不匹配: ${jwtTransactionId} != ${transactionId}`);
        return false;
      }

      // 旧版 StoreKit base64 receipt 走 verifyReceipt
      // 先请求生产环境
      let response = await this.requestAppleVerify(this.appleVerifyUrl, receiptData);

      // 状态码 21007 表示是沙盒收据，需要切换到沙盒环境验证
      if (response.status === 21007) {
        this.logger.log('检测到沙盒收据，切换到沙盒环境验证');
        response = await this.requestAppleVerify(this.appleSandboxUrl, receiptData);
      }

      // 状态码 0 表示验证成功
      if (response.status !== 0) {
        this.logger.warn(`Apple 验证失败，状态码: ${response.status}`);
        return false;
      }

      // 检查交易ID是否匹配
      const receipts = response.latest_receipt_info || response.receipt?.in_app || [];
      const matchedTransaction = receipts.find(
        (item: any) => item.transaction_id === transactionId || item.original_transaction_id === transactionId
      );

      if (!matchedTransaction) {
        this.logger.warn(`未找到匹配的交易ID: ${transactionId}`);
        return false;
      }

      return true;
    } catch (error) {
      this.logger.error(`Apple 验证请求失败: ${error.message}`);
      return false;
    }
  }

  /**
   * 解析 StoreKit2 JWS 收据的 payload（不验证签名，仅用于开发环境）
   */
  private parseJWSPayload(receiptData: string): any {
    const parts = receiptData.split('.');
    if (parts.length !== 3) {
      return null;
    }
    try {
      // base64url 解码 payload
      const base64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
      const pad = base64.length % 4;
      const padded = pad ? base64 + '='.repeat(4 - pad) : base64;
      const payload = Buffer.from(padded, 'base64').toString('utf8');
      return JSON.parse(payload);
    } catch (error) {
      this.logger.warn(`解析 JWS payload 失败: ${error.message}`);
      return null;
    }
  }

  /**
   * 请求 Apple 验证服务器
   */
  private async requestAppleVerify(url: string, receiptData: string): Promise<AppleVerifyResponse> {
    const password = this.configService.get<string>('APPLE_SHARED_SECRET');
    const payload: any = { 'receipt-data': receiptData };
    if (password) {
      payload.password = password;
    }

    const response = await axios.post(url, payload, {
      headers: { 'Content-Type': 'application/json' },
      timeout: 30000,
    });

    return response.data;
  }
}
