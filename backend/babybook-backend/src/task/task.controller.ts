import { Controller, Get, Post, Param, Body, UseGuards, Req, UnauthorizedException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { TaskService } from './task.service';
import { TaskResponseDto, UpdateTaskStatusDto } from './dto/task.dto';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import { Request } from 'express';

@ApiTags('任务')
@Controller('api/task')
export class TaskController {
  constructor(private readonly taskService: TaskService) {}

  @Get(':id')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '查询任务状态' })
  @ApiResponse({ status: 200, description: '查询成功', type: TaskResponseDto })
  @ApiResponse({ status: 404, description: '任务不存在' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async findById(@Param('id') id: string, @Req() req: Request): Promise<TaskResponseDto> {
    const task = await this.taskService.findById(id);
    // 验证设备权限
    const deviceId = req['deviceId'];
    const order = await this.taskService.getOrderByTaskId(id);
    if (order.deviceId !== deviceId) {
      throw new UnauthorizedException('无权访问此任务');
    }
    return task;
  }

  @Get('order/:orderId')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '根据订单ID查询任务状态' })
  @ApiResponse({ status: 200, description: '查询成功', type: TaskResponseDto })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async findByOrderId(@Param('orderId') orderId: string, @Req() req: Request): Promise<TaskResponseDto | null> {
    const task = await this.taskService.findByOrderId(orderId);
    if (task) {
      // 验证设备权限
      const deviceId = req['deviceId'];
      const order = await this.taskService.getOrderByTaskId(task.id);
      if (order.deviceId !== deviceId) {
        throw new UnauthorizedException('无权访问此任务');
      }
    }
    return task;
  }

  @Post(':id/cancel')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '取消任务' })
  @ApiResponse({ status: 200, description: '取消成功' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async cancelTask(@Param('id') id: string, @Req() req: Request): Promise<any> {
    // 验证设备权限
    const deviceId = req['deviceId'];
    const order = await this.taskService.getOrderByTaskId(id);
    if (order.deviceId !== deviceId) {
      throw new UnauthorizedException('无权访问此任务');
    }
    const task = await this.taskService.cancelTask(id);
    return { success: true, taskId: task.id, status: task.status };
  }
}
