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
Object.defineProperty(exports, "__esModule", { value: true });
exports.TaskController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const task_service_1 = require("./task.service");
const task_dto_1 = require("./dto/task.dto");
let TaskController = class TaskController {
    taskService;
    constructor(taskService) {
        this.taskService = taskService;
    }
    async findById(id) {
        return this.taskService.findById(id);
    }
    async findByOrderId(orderId) {
        return this.taskService.findByOrderId(orderId);
    }
    async cancelTask(id) {
        const task = await this.taskService.cancelTask(id);
        return { success: true, taskId: task.id, status: task.status };
    }
};
exports.TaskController = TaskController;
__decorate([
    (0, common_1.Get)(':id'),
    (0, swagger_1.ApiOperation)({ summary: '查询任务状态' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: '查询成功', type: task_dto_1.TaskResponseDto }),
    (0, swagger_1.ApiResponse)({ status: 404, description: '任务不存在' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], TaskController.prototype, "findById", null);
__decorate([
    (0, common_1.Get)('order/:orderId'),
    (0, swagger_1.ApiOperation)({ summary: '根据订单ID查询任务状态' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: '查询成功', type: task_dto_1.TaskResponseDto }),
    __param(0, (0, common_1.Param)('orderId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], TaskController.prototype, "findByOrderId", null);
__decorate([
    (0, common_1.Post)(':id/cancel'),
    (0, swagger_1.ApiOperation)({ summary: '取消任务' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: '取消成功' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], TaskController.prototype, "cancelTask", null);
exports.TaskController = TaskController = __decorate([
    (0, swagger_1.ApiTags)('任务'),
    (0, common_1.Controller)('api/task'),
    __metadata("design:paramtypes", [task_service_1.TaskService])
], TaskController);
//# sourceMappingURL=task.controller.js.map