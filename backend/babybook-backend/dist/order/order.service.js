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
exports.OrderService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const order_entity_1 = require("./entities/order.entity");
const enums_1 = require("../common/enums");
const BOOK_TEMPLATES = {
    [enums_1.BookTemplate.SELF_INTRO]: { name: '《这是我》', price: 12.99 },
    [enums_1.BookTemplate.DREAM_JOB]: { name: '《我长大想做什么》', price: 12.99 },
    [enums_1.BookTemplate.COLOR_RECOGNITION]: { name: '《认识颜色》', price: 12.99 },
};
let OrderService = class OrderService {
    orderRepository;
    constructor(orderRepository) {
        this.orderRepository = orderRepository;
    }
    async create(createOrderDto) {
        const { bookId, deviceId, imageUrl } = createOrderDto;
        const template = BOOK_TEMPLATES[bookId];
        if (!template) {
            throw new common_1.BadRequestException('无效的绘本模板ID');
        }
        const order = this.orderRepository.create({
            deviceId,
            bookId,
            bookName: template.name,
            amount: template.price,
            status: enums_1.OrderStatus.UNPAID,
            imageUrl: imageUrl || undefined,
        });
        const savedOrder = await this.orderRepository.save(order);
        return this.toResponseDto(savedOrder);
    }
    async findById(id) {
        const order = await this.orderRepository.findOne({ where: { id } });
        if (!order) {
            throw new common_1.NotFoundException('订单不存在');
        }
        return this.toResponseDto(order);
    }
    async findAll(query) {
        const { deviceId, status, page = 1, limit = 10 } = query;
        const where = {};
        if (deviceId) {
            where.deviceId = deviceId;
        }
        if (status) {
            where.status = status;
        }
        const [orders, total] = await this.orderRepository.findAndCount({
            where,
            order: { createdAt: 'DESC' },
            skip: (page - 1) * limit,
            take: limit,
        });
        return {
            orders: orders.map(order => this.toResponseDto(order)),
            total,
        };
    }
    async updateStatus(id, status, updates) {
        const order = await this.orderRepository.findOne({ where: { id } });
        if (!order) {
            throw new common_1.NotFoundException('订单不存在');
        }
        order.status = status;
        if (updates) {
            Object.assign(order, updates);
        }
        return await this.orderRepository.save(order);
    }
    async findOneEntity(id) {
        const order = await this.orderRepository.findOne({ where: { id } });
        if (!order) {
            throw new common_1.NotFoundException('订单不存在');
        }
        return order;
    }
    toResponseDto(order) {
        return {
            id: order.id,
            deviceId: order.deviceId,
            bookId: order.bookId,
            bookName: order.bookName,
            amount: Number(order.amount),
            status: order.status,
            createdAt: order.createdAt,
            updatedAt: order.updatedAt,
        };
    }
};
exports.OrderService = OrderService;
exports.OrderService = OrderService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(order_entity_1.Order)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], OrderService);
//# sourceMappingURL=order.service.js.map