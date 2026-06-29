import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { Cron, CronExpression } from '@nestjs/schedule';
import { Task } from './entities/task.entity';
import { Order } from '../order/entities/order.entity';
import { TaskStatus, OrderStatus } from '../common/enums';
import { TaskResponseDto, CreateTaskDto, UpdateTaskStatusDto } from './dto/task.dto';
import { AiService } from '../ai/ai.service';

@Injectable()
export class TaskService {
  private readonly logger = new Logger(TaskService.name);
  private readonly maxRetries = 2; // 最大重试次数

  constructor(
    @InjectRepository(Task)
    private taskRepository: Repository<Task>,
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
    private aiService: AiService,
  ) {}

  /**
   * 创建生成任务
   */
  async createTask(orderId: string): Promise<Task> {
    const order = await this.orderRepository.findOne({ where: { id: orderId } });
    if (!order) {
      throw new NotFoundException('订单不存在');
    }

    // 检查是否已存在任务
    const existingTask = await this.taskRepository.findOne({
      where: { orderId },
    });
    if (existingTask) {
      this.logger.log(`订单 ${orderId} 已存在任务，跳过创建`);
      return existingTask;
    }

    const task = this.taskRepository.create({
      orderId,
      status: TaskStatus.PENDING,
      progress: 0,
    });

    const savedTask = await this.taskRepository.save(task);
    this.logger.log(`任务已创建: ${savedTask.id}, 订单: ${orderId}`);

    // 更新订单状态为生成中
    order.status = OrderStatus.GENERATING;
    await this.orderRepository.save(order);

    // 立即触发执行（异步，不阻塞响应）
    this.executeTask(savedTask.id).catch(error => {
      this.logger.error(`任务执行异常: ${error.message}`);
    });

    return savedTask;
  }

  /**
   * 查询任务状态
   */
  async findById(id: string): Promise<TaskResponseDto> {
    const task = await this.taskRepository.findOne({
      where: { id },
      relations: ['order'],
    });
    if (!task) {
      throw new NotFoundException('任务不存在');
    }
    return this.toResponseDto(task);
  }

  /**
   * 根据任务ID获取关联订单（供控制器验证设备权限使用）
   */
  async getOrderByTaskId(taskId: string): Promise<Order> {
    const task = await this.taskRepository.findOne({
      where: { id: taskId },
      relations: ['order'],
    });
    if (!task || !task.order) {
      throw new NotFoundException('任务不存在或关联订单已删除');
    }
    return task.order;
  }

  /**
   * 根据订单ID查询任务
   */
  async findByOrderId(orderId: string): Promise<TaskResponseDto | null> {
    const task = await this.taskRepository.findOne({
      where: { orderId },
      relations: ['order'],
    });
    if (!task) {
      return null;
    }
    return this.toResponseDto(task);
  }

  /**
   * 更新任务状态
   */
  async updateStatus(id: string, dto: UpdateTaskStatusDto): Promise<Task> {
    const task = await this.taskRepository.findOne({ where: { id } });
    if (!task) {
      throw new NotFoundException('任务不存在');
    }

    task.status = dto.status;
    if (dto.progress !== undefined) {
      task.progress = dto.progress;
    }
    if (dto.resultUrl) {
      task.resultUrl = dto.resultUrl;
    }
    if (dto.errorMessage) {
      task.errorMessage = dto.errorMessage;
    }

    return await this.taskRepository.save(task);
  }

  /**
   * 取消任务
   */
  async cancelTask(id: string): Promise<Task> {
    const task = await this.taskRepository.findOne({ where: { id } });
    if (!task) {
      throw new NotFoundException('任务不存在');
    }

    if (task.status === TaskStatus.COMPLETED) {
      throw new Error('任务已完成，无法取消');
    }

    task.status = TaskStatus.CANCELLED;
    return await this.taskRepository.save(task);
  }

  /**
   * 执行生成任务（核心逻辑）
   */
  private async executeTask(taskId: string): Promise<void> {
    const task = await this.taskRepository.findOne({
      where: { id: taskId },
      relations: ['order'],
    });
    if (!task || task.status === TaskStatus.CANCELLED) {
      return;
    }

    // 标记为执行中
    task.status = TaskStatus.RUNNING;
    task.startedAt = new Date();
    task.progress = 10;
    await this.taskRepository.save(task);

    try {
      this.logger.log(`开始执行任务: ${taskId}, 订单: ${task.orderId}`);

      // 获取订单信息
      const order = task.order;
      if (!order || !order.imageUrl) {
        throw new Error('订单信息不完整，缺少宝宝照片');
      }

      // 更新进度
      task.progress = 30;
      await this.taskRepository.save(task);

      // 调用 AI 生成九宫格图片
      const resultUrl = await this.aiService.generateBookImage({
        bookId: order.bookId,
        imageUrl: order.imageUrl,
      });

      // 更新进度
      task.progress = 80;
      await this.taskRepository.save(task);

      // 更新任务完成状态
      task.status = TaskStatus.COMPLETED;
      task.progress = 100;
      task.resultUrl = resultUrl;
      task.completedAt = new Date();
      await this.taskRepository.save(task);

      // 更新订单状态为成功
      order.status = OrderStatus.SUCCESS;
      order.resultImageUrl = resultUrl;
      order.completedAt = new Date();
      await this.orderRepository.save(order);

      this.logger.log(`任务完成: ${taskId}, 结果: ${resultUrl}`);
    } catch (error) {
      this.logger.error(`任务执行失败: ${taskId}, 错误: ${error.message}`);

      task.status = TaskStatus.FAILED;
      task.errorMessage = error.message;
      task.retryCount += 1;
      await this.taskRepository.save(task);

      // 更新订单状态
      const order = task.order;
      order.retryCount = task.retryCount;
      order.errorMessage = error.message;

      // 如果重试次数未达上限，保持 GENERATING 状态等待重试
      // 如果已达上限，标记为 FAILED
      if (task.retryCount >= this.maxRetries) {
        order.status = OrderStatus.FAILED;
        this.logger.error(`任务 ${taskId} 重试次数已达上限，标记为失败`);
      }
      await this.orderRepository.save(order);
    }
  }

  /**
   * 定时任务：重试失败的任务（每 2 分钟执行一次）
   */
  @Cron('*/2 * * * *')
  async retryFailedTasks(): Promise<void> {
    const failedTasks = await this.taskRepository.find({
      where: {
        status: TaskStatus.FAILED,
        retryCount: LessThan(this.maxRetries),
      },
      relations: ['order'],
    });

    if (failedTasks.length > 0) {
      this.logger.log(`发现 ${failedTasks.length} 个失败任务，开始重试`);
    }

    for (const task of failedTasks) {
      this.logger.log(`重试任务: ${task.id}, 当前重试次数: ${task.retryCount}`);
      // 重置为 PENDING 状态，重新执行
      task.status = TaskStatus.PENDING;
      task.errorMessage = undefined;
      await this.taskRepository.save(task);

      // 更新订单状态回 GENERATING
      const order = task.order;
      order.status = OrderStatus.GENERATING;
      await this.orderRepository.save(order);

      // 异步执行
      this.executeTask(task.id).catch(error => {
        this.logger.error(`重试任务执行异常: ${error.message}`);
      });
    }
  }

  /**
   * 定时任务：处理超时任务（每 5 分钟执行一次）
   * 超过 300 秒（5 分钟）仍在 RUNNING 状态的任务，视为超时
   */
  @Cron('0 */5 * * * *')
  async handleTimeoutTasks(): Promise<void> {
    const timeoutThreshold = new Date(Date.now() - 300 * 1000); // 5 分钟前

    const timeoutTasks = await this.taskRepository.find({
      where: {
        status: TaskStatus.RUNNING,
        startedAt: LessThan(timeoutThreshold),
      },
      relations: ['order'],
    });

    for (const task of timeoutTasks) {
      this.logger.warn(`任务超时: ${task.id}`);
      task.status = TaskStatus.FAILED;
      task.errorMessage = '任务执行超时';
      task.retryCount += 1;
      await this.taskRepository.save(task);

      const order = task.order;
      order.errorMessage = '任务执行超时';
      if (task.retryCount >= this.maxRetries) {
        order.status = OrderStatus.FAILED;
      }
      await this.orderRepository.save(order);
    }
  }

  /**
   * 转换为响应 DTO
   */
  private toResponseDto(task: Task): TaskResponseDto {
    return {
      id: task.id,
      orderId: task.orderId,
      status: task.status,
      progress: task.progress,
      resultUrl: task.resultUrl,
      errorMessage: task.errorMessage,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    };
  }
}
