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
Object.defineProperty(exports, "__esModule", { value: true });
exports.UpdateTaskStatusDto = exports.CreateTaskDto = exports.TaskResponseDto = void 0;
const class_validator_1 = require("class-validator");
const swagger_1 = require("@nestjs/swagger");
const enums_1 = require("../../common/enums");
class TaskResponseDto {
    id;
    orderId;
    status;
    progress;
    resultUrl;
    errorMessage;
    createdAt;
    updatedAt;
}
exports.TaskResponseDto = TaskResponseDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: '任务ID' }),
    __metadata("design:type", String)
], TaskResponseDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '订单ID' }),
    __metadata("design:type", String)
], TaskResponseDto.prototype, "orderId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '任务状态', enum: enums_1.TaskStatus }),
    __metadata("design:type", String)
], TaskResponseDto.prototype, "status", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '生成进度（0-100）' }),
    __metadata("design:type", Number)
], TaskResponseDto.prototype, "progress", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '生成结果图片URL' }),
    __metadata("design:type", String)
], TaskResponseDto.prototype, "resultUrl", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '错误信息' }),
    __metadata("design:type", String)
], TaskResponseDto.prototype, "errorMessage", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '创建时间' }),
    __metadata("design:type", Date)
], TaskResponseDto.prototype, "createdAt", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '更新时间' }),
    __metadata("design:type", Date)
], TaskResponseDto.prototype, "updatedAt", void 0);
class CreateTaskDto {
    orderId;
}
exports.CreateTaskDto = CreateTaskDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: '订单ID' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateTaskDto.prototype, "orderId", void 0);
class UpdateTaskStatusDto {
    status;
    progress;
    resultUrl;
    errorMessage;
}
exports.UpdateTaskStatusDto = UpdateTaskStatusDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: '任务状态', enum: enums_1.TaskStatus }),
    (0, class_validator_1.IsEnum)(enums_1.TaskStatus),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdateTaskStatusDto.prototype, "status", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '生成进度（0-100）' }),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Number)
], UpdateTaskStatusDto.prototype, "progress", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '结果图片URL' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], UpdateTaskStatusDto.prototype, "resultUrl", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '错误信息' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], UpdateTaskStatusDto.prototype, "errorMessage", void 0);
//# sourceMappingURL=task.dto.js.map