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
exports.QueryOrdersDto = exports.UpdateOrderImageDto = exports.OrderResponseDto = exports.CreateOrderDto = void 0;
const class_validator_1 = require("class-validator");
const class_transformer_1 = require("class-transformer");
const swagger_1 = require("@nestjs/swagger");
const enums_1 = require("../../common/enums");
class CreateOrderDto {
    bookId;
    deviceId;
    imageUrl;
}
exports.CreateOrderDto = CreateOrderDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: '绘本模板ID', enum: enums_1.BookTemplate, example: 'Book001' }),
    (0, class_validator_1.IsEnum)(enums_1.BookTemplate),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateOrderDto.prototype, "bookId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '设备标识', example: 'device_abc123' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], CreateOrderDto.prototype, "deviceId", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '宝宝照片URL（可选，可在支付后上传）' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], CreateOrderDto.prototype, "imageUrl", void 0);
class OrderResponseDto {
    id;
    deviceId;
    bookId;
    bookName;
    amount;
    status;
    createdAt;
    updatedAt;
}
exports.OrderResponseDto = OrderResponseDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: '订单ID' }),
    __metadata("design:type", String)
], OrderResponseDto.prototype, "id", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '设备标识' }),
    __metadata("design:type", String)
], OrderResponseDto.prototype, "deviceId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '绘本模板ID' }),
    __metadata("design:type", String)
], OrderResponseDto.prototype, "bookId", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '绘本名称' }),
    __metadata("design:type", String)
], OrderResponseDto.prototype, "bookName", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '订单金额' }),
    __metadata("design:type", Number)
], OrderResponseDto.prototype, "amount", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '订单状态' }),
    __metadata("design:type", String)
], OrderResponseDto.prototype, "status", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '创建时间' }),
    __metadata("design:type", Date)
], OrderResponseDto.prototype, "createdAt", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: '更新时间', nullable: true }),
    __metadata("design:type", Date)
], OrderResponseDto.prototype, "updatedAt", void 0);
class UpdateOrderImageDto {
    imageUrl;
}
exports.UpdateOrderImageDto = UpdateOrderImageDto;
__decorate([
    (0, swagger_1.ApiProperty)({ description: '宝宝照片URL' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], UpdateOrderImageDto.prototype, "imageUrl", void 0);
class QueryOrdersDto {
    deviceId;
    status;
    page = 1;
    limit = 10;
}
exports.QueryOrdersDto = QueryOrdersDto;
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '设备标识', example: 'device_abc123' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], QueryOrdersDto.prototype, "deviceId", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '订单状态', example: 'PAID' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], QueryOrdersDto.prototype, "status", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '页码', default: 1 }),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Number)
], QueryOrdersDto.prototype, "page", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ description: '每页数量', default: 10 }),
    (0, class_transformer_1.Type)(() => Number),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(1),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", Number)
], QueryOrdersDto.prototype, "limit", void 0);
//# sourceMappingURL=order.dto.js.map