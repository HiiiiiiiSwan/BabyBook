import { IsNotEmpty, IsString, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { TaskStatus } from '../../common/enums';

/**
 * 查询任务状态响应 DTO
 */
export class TaskResponseDto {
  @ApiProperty({ description: '任务ID' })
  id: string;

  @ApiProperty({ description: '订单ID' })
  orderId: string;

  @ApiProperty({ description: '任务状态', enum: TaskStatus })
  status: TaskStatus;

  @ApiProperty({ description: '生成进度（0-100）' })
  progress: number;

  @ApiPropertyOptional({ description: '生成结果图片URL' })
  resultUrl?: string;

  @ApiPropertyOptional({ description: '错误信息' })
  errorMessage?: string;

  @ApiProperty({ description: '创建时间' })
  createdAt: Date;

  @ApiProperty({ description: '更新时间' })
  updatedAt: Date;
}

/**
 * 创建任务请求 DTO（内部使用）
 */
export class CreateTaskDto {
  @ApiProperty({ description: '订单ID' })
  @IsString()
  @IsNotEmpty()
  orderId: string;
}

/**
 * 更新任务状态 DTO
 */
export class UpdateTaskStatusDto {
  @ApiProperty({ description: '任务状态', enum: TaskStatus })
  @IsEnum(TaskStatus)
  @IsNotEmpty()
  status: TaskStatus;

  @ApiPropertyOptional({ description: '生成进度（0-100）' })
  @IsOptional()
  progress?: number;

  @ApiPropertyOptional({ description: '结果图片URL' })
  @IsString()
  @IsOptional()
  resultUrl?: string;

  @ApiPropertyOptional({ description: '错误信息' })
  @IsString()
  @IsOptional()
  errorMessage?: string;
}
