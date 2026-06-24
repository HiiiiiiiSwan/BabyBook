"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var TaskService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.TaskService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const schedule_1 = require("@nestjs/schedule");
const task_entity_1 = require("./entities/task.entity");
const order_entity_1 = require("../order/entities/order.entity");
const enums_1 = require("../common/enums");
const ai_service_1 = require("../ai/ai.service");
let TaskService = TaskService_1 = class TaskService {
    taskRepository;
    orderRepository;
    aiService;
    logger = new common_1.Logger(TaskService_1.name);
    maxRetries = 2;
    constructor(taskRepository, orderRepository, aiService) {
        this.taskRepository = taskRepository;
        this.orderRepository = orderRepository;
        this.aiService = aiService;
    }
    async createTask(orderId) {
        const order = await this.orderRepository.findOne({ where: { id: orderId } });
        if (!order) {
            throw new common_1.NotFoundException('订单不存在');
        }
        const existingTask = await this.taskRepository.findOne({
            where: { orderId },
        });
        if (existingTask) {
            this.logger.log(`订单 ${orderId} 已存在任务，跳过创建`);
            return existingTask;
        }
        const task = this.taskRepository.create({
            orderId,
            status: enums_1.TaskStatus.PENDING,
            progress: 0,
        });
        const savedTask = await this.taskRepository.save(task);
        this.logger.log(`任务已创建: ${savedTask.id}, 订单: ${orderId}`);
        order.status = enums_1.OrderStatus.GENERATING;
        await this.orderRepository.save(order);
        this.executeTask(savedTask.id).catch(error => {
            this.logger.error(`任务执行异常: ${error.message}`);
        });
        return savedTask;
    }
    async findById(id) {
        const task = await this.taskRepository.findOne({
            where: { id },
            relations: ['order'],
        });
        if (!task) {
            throw new common_1.NotFoundException('任务不存在');
        }
        return this.toResponseDto(task);
    }
    async findByOrderId(orderId) {
        const task = await this.taskRepository.findOne({
            where: { orderId },
            relations: ['order'],
        });
        if (!task) {
            return null;
        }
        return this.toResponseDto(task);
    }
    async updateStatus(id, dto) {
        const task = await this.taskRepository.findOne({ where: { id } });
        if (!task) {
            throw new common_1.NotFoundException('任务不存在');
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
    async cancelTask(id) {
        const task = await this.taskRepository.findOne({ where: { id } });
        if (!task) {
            throw new common_1.NotFoundException('任务不存在');
        }
        if (task.status === enums_1.TaskStatus.COMPLETED) {
            throw new Error('任务已完成，无法取消');
        }
        task.status = enums_1.TaskStatus.CANCELLED;
        return await this.taskRepository.save(task);
    }
    async executeTask(taskId) {
        const task = await this.taskRepository.findOne({
            where: { id: taskId },
            relations: ['order'],
        });
        if (!task || task.status === enums_1.TaskStatus.CANCELLED) {
            return;
        }
        task.status = enums_1.TaskStatus.RUNNING;
        task.startedAt = new Date();
        task.progress = 10;
        await this.taskRepository.save(task);
        try {
            this.logger.log(`开始执行任务: ${taskId}, 订单: ${task.orderId}`);
            const order = task.order;
            if (!order || !order.imageUrl) {
                throw new Error('订单信息不完整，缺少宝宝照片');
            }
            task.progress = 30;
            await this.taskRepository.save(task);
            const resultUrl = await this.aiService.generateBookImage({
                bookId: order.bookId,
                imageUrl: order.imageUrl,
            });
            task.progress = 80;
            await this.taskRepository.save(task);
            task.status = enums_1.TaskStatus.COMPLETED;
            task.progress = 100;
            task.resultUrl = resultUrl;
            task.completedAt = new Date();
            await this.taskRepository.save(task);
            order.status = enums_1.OrderStatus.SUCCESS;
            order.resultImageUrl = resultUrl;
            order.completedAt = new Date();
            await this.orderRepository.save(order);
            this.logger.log(`任务完成: ${taskId}, 结果: ${resultUrl}`);
        }
        catch (error) {
            this.logger.error(`任务执行失败: ${taskId}, 错误: ${error.message}`);
            task.status = enums_1.TaskStatus.FAILED;
            task.errorMessage = error.message;
            task.retryCount += 1;
            await this.taskRepository.save(task);
            const order = task.order;
            order.retryCount = task.retryCount;
            order.errorMessage = error.message;
            if (task.retryCount >= this.maxRetries) {
                order.status = enums_1.OrderStatus.FAILED;
                this.logger.error(`任务 ${taskId} 重试次数已达上限，标记为失败`);
            }
            await this.orderRepository.save(order);
        }
    }
    async retryFailedTasks() {
        const failedTasks = await this.taskRepository.find({
            where: {
                status: enums_1.TaskStatus.FAILED,
                retryCount: (0, typeorm_2.LessThan)(this.maxRetries),
            },
            relations: ['order'],
        });
        if (failedTasks.length > 0) {
            this.logger.log(`发现 ${failedTasks.length} 个失败任务，开始重试`);
        }
        for (const task of failedTasks) {
            this.logger.log(`重试任务: ${task.id}, 当前重试次数: ${task.retryCount}`);
            task.status = enums_1.TaskStatus.PENDING;
            task.errorMessage = undefined;
            await this.taskRepository.save(task);
            const order = task.order;
            order.status = enums_1.OrderStatus.GENERATING;
            await this.orderRepository.save(order);
            this.executeTask(task.id).catch(error => {
                this.logger.error(`重试任务执行异常: ${error.message}`);
            });
        }
    }
    async handleTimeoutTasks() {
        const timeoutThreshold = new Date(Date.now() - 300 * 1000);
        const timeoutTasks = await this.taskRepository.find({
            where: {
                status: enums_1.TaskStatus.RUNNING,
                startedAt: (0, typeorm_2.LessThan)(timeoutThreshold),
            },
            relations: ['order'],
        });
        for (const task of timeoutTasks) {
            this.logger.warn(`任务超时: ${task.id}`);
            task.status = enums_1.TaskStatus.FAILED;
            task.errorMessage = '任务执行超时';
            task.retryCount += 1;
            await this.taskRepository.save(task);
            const order = task.order;
            order.errorMessage = '任务执行超时';
            if (task.retryCount >= this.maxRetries) {
                order.status = enums_1.OrderStatus.FAILED;
            }
            await this.orderRepository.save(order);
        }
    }
    toResponseDto(task) {
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
};
exports.TaskService = TaskService;
__decorate([
    (0, schedule_1.Cron)('*/2 * * * *'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], TaskService.prototype, "retryFailedTasks", null);
__decorate([
    (0, schedule_1.Cron)('0 */5 * * * *'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], TaskService.prototype, "handleTimeoutTasks", null);
exports.TaskService = TaskService = TaskService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(task_entity_1.Task)),
    __param(1, (0, typeorm_1.InjectRepository)(order_entity_1.Order)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        ai_service_1.AiService])
], TaskService);
//# sourceMappingURL=task.service.js.map