import { Controller, Get, Post, Param, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { TaskService } from './task.service';
import { TaskResponseDto, UpdateTaskStatusDto } from './dto/task.dto';

@ApiTags('任务')
@Controller('api/task')
export class TaskController {
  constructor(private readonly taskService: TaskService) {}

  @Get(':id')
  @ApiOperation({ summary: '查询任务状态' })
  @ApiResponse({ status: 200, description: '查询成功', type: TaskResponseDto })
  @ApiResponse({ status: 404, description: '任务不存在' })
  async findById(@Param('id') id: string): Promise<TaskResponseDto> {
    return this.taskService.findById(id);
  }

  @Get('order/:orderId')
  @ApiOperation({ summary: '根据订单ID查询任务状态' })
  @ApiResponse({ status: 200, description: '查询成功', type: TaskResponseDto })
  async findByOrderId(@Param('orderId') orderId: string): Promise<TaskResponseDto | null> {
    return this.taskService.findByOrderId(orderId);
  }

  @Post(':id/cancel')
  @ApiOperation({ summary: '取消任务' })
  @ApiResponse({ status: 200, description: '取消成功' })
  async cancelTask(@Param('id') id: string): Promise<any> {
    const task = await this.taskService.cancelTask(id);
    return { success: true, taskId: task.id, status: task.status };
  }
}
