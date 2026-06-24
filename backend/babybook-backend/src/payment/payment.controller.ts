import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PaymentService } from './payment.service';
import { VerifyPaymentDto, PaymentResponseDto } from './dto/payment.dto';

@ApiTags('支付')
@Controller('api/payment')
export class PaymentController {
  constructor(private readonly paymentService: PaymentService) {}

  @Post('verify')
  @ApiOperation({ summary: '验证 Apple IAP 支付', description: '支付成功后服务端自动创建生成任务' })
  @ApiResponse({ status: 200, description: '验证成功', type: PaymentResponseDto })
  @ApiResponse({ status: 400, description: '验证失败或参数错误' })
  async verifyPayment(@Body() dto: VerifyPaymentDto): Promise<PaymentResponseDto> {
    return this.paymentService.verifyPayment(dto);
  }
}
