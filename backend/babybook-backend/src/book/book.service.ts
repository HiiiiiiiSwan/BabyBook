import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from '../order/entities/order.entity';
import { OrderStatus } from '../common/enums';
import axios from 'axios';

/**
 * 绘本服务
 * 处理 PDF 下载和绘本数据管理
 */
@Injectable()
export class BookService {
  private readonly logger = new Logger(BookService.name);

  constructor(
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
  ) {}

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
   * 获取绘本下载信息
   * 返回生成的九宫格图片 URL（由客户端下载后本地制作 PDF）
   */
  async getBookDownloadInfo(orderId: string): Promise<{ imageUrl: string; bookName: string; status: string }> {
    const order = await this.orderRepository.findOne({ where: { id: orderId } });
    if (!order) {
      throw new NotFoundException('订单不存在');
    }

    if (order.status !== OrderStatus.SUCCESS) {
      throw new NotFoundException('绘本尚未生成完成');
    }

    if (!order.resultImageUrl) {
      throw new NotFoundException('绘本图片不存在');
    }

    return {
      imageUrl: order.resultImageUrl,
      bookName: order.bookName,
      status: order.status,
    };
  }

  /**
   * 获取绘本图片数据（用于直接下载）
   */
  async getBookImage(orderId: string): Promise<Buffer> {
    const order = await this.orderRepository.findOne({ where: { id: orderId } });
    if (!order || !order.resultImageUrl) {
      throw new NotFoundException('绘本图片不存在');
    }

    try {
      const response = await axios.get(order.resultImageUrl, {
        responseType: 'arraybuffer',
        timeout: 30000,
      });
      return Buffer.from(response.data);
    } catch (error) {
      this.logger.error(`下载绘本图片失败: ${error.message}`);
      throw new NotFoundException('绘本图片下载失败');
    }
  }
}
