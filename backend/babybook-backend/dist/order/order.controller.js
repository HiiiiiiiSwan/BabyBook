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
exports.OrderController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const order_service_1 = require("./order.service");
const order_dto_1 = require("./dto/order.dto");
let OrderController = class OrderController {
    orderService;
    constructor(orderService) {
        this.orderService = orderService;
    }
    async create(createOrderDto) {
        return this.orderService.create(createOrderDto);
    }
    async findById(id) {
        return this.orderService.findById(id);
    }
    async findAll(query) {
        return this.orderService.findAll(query);
    }
    async updateImage(id, updateImageDto) {
        const order = await this.orderService.findOneEntity(id);
        order.imageUrl = updateImageDto.imageUrl;
        const updated = await this.orderService['orderRepository'].save(order);
        return this.orderService['toResponseDto'](updated);
    }
};
exports.OrderController = OrderController;
__decorate([
    (0, common_1.Post)('create'),
    (0, swagger_1.ApiOperation)({ summary: '创建订单' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: '订单创建成功', type: order_dto_1.OrderResponseDto }),
    (0, swagger_1.ApiResponse)({ status: 400, description: '参数错误' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [order_dto_1.CreateOrderDto]),
    __metadata("design:returntype", Promise)
], OrderController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, swagger_1.ApiOperation)({ summary: '查询订单详情' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: '查询成功', type: order_dto_1.OrderResponseDto }),
    (0, swagger_1.ApiResponse)({ status: 404, description: '订单不存在' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], OrderController.prototype, "findById", null);
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: '查询订单列表' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: '查询成功' }),
    __param(0, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [order_dto_1.QueryOrdersDto]),
    __metadata("design:returntype", Promise)
], OrderController.prototype, "findAll", null);
__decorate([
    (0, common_1.Patch)(':id/image'),
    (0, swagger_1.ApiOperation)({ summary: '更新订单图片URL' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: '更新成功', type: order_dto_1.OrderResponseDto }),
    (0, swagger_1.ApiResponse)({ status: 404, description: '订单不存在' }),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, order_dto_1.UpdateOrderImageDto]),
    __metadata("design:returntype", Promise)
], OrderController.prototype, "updateImage", null);
exports.OrderController = OrderController = __decorate([
    (0, swagger_1.ApiTags)('订单'),
    (0, common_1.Controller)('api/order'),
    __metadata("design:paramtypes", [order_service_1.OrderService])
], OrderController);
//# sourceMappingURL=order.controller.js.map