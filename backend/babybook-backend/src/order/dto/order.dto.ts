import { IsEnum, IsNotEmpty, IsString, IsOptional, IsInt, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BookTemplate } from '../../common/enums';

/**
 * 创建订单请求 DTO
 */
export class CreateOrderDto {
  @ApiProperty({ description: '绘本模板ID', enum: BookTemplate, example: 'Book001' })
  @IsEnum(BookTemplate)
  @IsNotEmpty()
  bookId: BookTemplate;

  @ApiProperty({ description: '设备标识', example: 'device_abc123' })
  @IsString()
  @IsNotEmpty()
  deviceId: string;

  @ApiPropertyOptional({ description: '宝宝照片URL（可选，可在支付后上传）' })
  @IsString()
  @IsOptional()
  imageUrl?: string;
}

/**
 * 订单响应 DTO
 */
export class OrderResponseDto {
  @ApiProperty({ description: '订单ID' })
  id: string;

  @ApiProperty({ description: '设备标识' })
  deviceId: string;

  @ApiProperty({ description: '绘本模板ID' })
  bookId: string;

  @ApiProperty({ description: '绘本名称' })
  bookName: string;

  @ApiProperty({ description: '订单金额' })
  amount: number;

  @ApiProperty({ description: '订单状态' })
  status: string;

  @ApiProperty({ description: '创建时间' })
  createdAt: Date;

  @ApiProperty({ description: '更新时间', nullable: true })
  updatedAt: Date;
}

/**
 * 更新订单图片 URL DTO
 */
export class UpdateOrderImageDto {
  @ApiProperty({ description: '宝宝照片URL' })
  @IsString()
  @IsNotEmpty()
  imageUrl: string;
}

/**
 * 查询订单列表请求 DTO
 */
export class QueryOrdersDto {
  @ApiPropertyOptional({ description: '设备标识', example: 'device_abc123' })
  @IsString()
  @IsOptional()
  deviceId?: string;

  @ApiPropertyOptional({ description: '订单状态', example: 'PAID' })
  @IsString()
  @IsOptional()
  status?: string;

  @ApiPropertyOptional({ description: '页码', default: 1 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  page?: number = 1;

  @ApiPropertyOptional({ description: '每页数量', default: 10 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @IsOptional()
  limit?: number = 10;
}
