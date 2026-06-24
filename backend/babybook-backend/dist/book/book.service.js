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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var BookService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.BookService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const order_entity_1 = require("../order/entities/order.entity");
const enums_1 = require("../common/enums");
const axios_1 = __importDefault(require("axios"));
let BookService = BookService_1 = class BookService {
    orderRepository;
    logger = new common_1.Logger(BookService_1.name);
    constructor(orderRepository) {
        this.orderRepository = orderRepository;
    }
    async getBookDownloadInfo(orderId) {
        const order = await this.orderRepository.findOne({ where: { id: orderId } });
        if (!order) {
            throw new common_1.NotFoundException('订单不存在');
        }
        if (order.status !== enums_1.OrderStatus.SUCCESS) {
            throw new common_1.NotFoundException('绘本尚未生成完成');
        }
        if (!order.resultImageUrl) {
            throw new common_1.NotFoundException('绘本图片不存在');
        }
        return {
            imageUrl: order.resultImageUrl,
            bookName: order.bookName,
            status: order.status,
        };
    }
    async getBookImage(orderId) {
        const order = await this.orderRepository.findOne({ where: { id: orderId } });
        if (!order || !order.resultImageUrl) {
            throw new common_1.NotFoundException('绘本图片不存在');
        }
        try {
            const response = await axios_1.default.get(order.resultImageUrl, {
                responseType: 'arraybuffer',
                timeout: 30000,
            });
            return Buffer.from(response.data);
        }
        catch (error) {
            this.logger.error(`下载绘本图片失败: ${error.message}`);
            throw new common_1.NotFoundException('绘本图片下载失败');
        }
    }
};
exports.BookService = BookService;
exports.BookService = BookService = BookService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(order_entity_1.Order)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], BookService);
//# sourceMappingURL=book.service.js.map