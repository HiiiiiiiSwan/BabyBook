import { IsNotEmpty, IsString, IsNumber, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * 支付验证请求 DTO
 */
export class VerifyPaymentDto {
  @ApiProperty({ description: '订单ID', example: 'uuid-order-id' })
  @IsString()
  @IsNotEmpty()
  orderId: string;

  @ApiProperty({ description: 'Apple 支付收据（Base64编码）', example: 'base64-receipt-data' })
  @IsString()
  @IsNotEmpty()
  receiptData: string;

  @ApiProperty({ description: 'Apple 交易ID', example: '1000000123456789' })
  @IsString()
  @IsNotEmpty()
  transactionId: string;

  @ApiPropertyOptional({ description: '宝宝照片URL' })
  @IsString()
  @IsOptional()
  imageUrl?: string;
}

/**
 * 支付验证响应 DTO
 */
export class PaymentResponseDto {
  @ApiProperty({ description: '是否验证成功' })
  success: boolean;

  @ApiProperty({ description: '订单ID' })
  orderId: string;

  @ApiProperty({ description: '订单状态' })
  status: string;

  @ApiPropertyOptional({ description: '错误信息' })
  errorMessage?: string;
}
