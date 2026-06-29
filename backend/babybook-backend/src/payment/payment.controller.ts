import { Controller, Post, Body, UseGuards, Req, UnauthorizedException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PaymentService } from './payment.service';
import { VerifyPaymentDto, PaymentResponseDto } from './dto/payment.dto';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import { Request } from 'express';

@ApiTags('支付')
@Controller('api/payment')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  @Post('verify')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '验证 Apple IAP 支付', description: '支付成功后服务端自动创建生成任务' })
  @ApiResponse({ status: 200, description: '验证成功', type: PaymentResponseDto })
  @ApiResponse({ status: 400, description: '验证失败或参数错误' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async verifyPayment(@Body() dto: VerifyPaymentDto, @Req() req: Request): Promise<PaymentResponseDto> {
    // 验证设备权限：只能验证自己订单的支付
    const deviceId = req['deviceId'];

    // 获取订单信息并验证权限
    const order = await this.paymentService.getOrder(dto.orderId);
    if (order.deviceId !== deviceId) {
      throw new UnauthorizedException('无权访问此订单');
    }

    return this.paymentService.verifyPayment(dto);
  }
}
