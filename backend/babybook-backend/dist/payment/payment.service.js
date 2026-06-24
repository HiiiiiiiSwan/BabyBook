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
var PaymentService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const axios_1 = __importDefault(require("axios"));
const order_entity_1 = require("../order/entities/order.entity");
const enums_1 = require("../common/enums");
const task_service_1 = require("../task/task.service");
let PaymentService = PaymentService_1 = class PaymentService {
    configService;
    orderRepository;
    taskService;
    logger = new common_1.Logger(PaymentService_1.name);
    appleVerifyUrl;
    appleSandboxUrl;
    constructor(configService, orderRepository, taskService) {
        this.configService = configService;
        this.orderRepository = orderRepository;
        this.taskService = taskService;
        this.appleVerifyUrl = 'https://buy.itunes.apple.com/verifyReceipt';
        this.appleSandboxUrl = 'https://sandbox.itunes.apple.com/verifyReceipt';
    }
    async verifyPayment(dto) {
        const { orderId, receiptData, transactionId, imageUrl } = dto;
        const order = await this.orderRepository.findOne({ where: { id: orderId } });
        if (!order) {
            throw new common_1.NotFoundException('订单不存在');
        }
        if (order.status !== enums_1.OrderStatus.UNPAID) {
            throw new common_1.BadRequestException('订单状态不正确，无法重复支付');
        }
        const isValid = await this.verifyAppleReceipt(receiptData, transactionId);
        if (!isValid) {
            throw new common_1.BadRequestException('支付验证失败');
        }
        order.status = enums_1.OrderStatus.PAID;
        order.paymentId = transactionId;
        order.receiptData = receiptData;
        order.paidAt = new Date();
        if (imageUrl) {
            order.imageUrl = imageUrl;
        }
        await this.orderRepository.save(order);
        this.logger.log(`订单 ${orderId} 支付验证成功，交易ID: ${transactionId}`);
        try {
            await this.taskService.createTask(orderId);
            this.logger.log(`订单 ${orderId} 生成任务已自动创建`);
        }
        catch (error) {
            this.logger.error(`订单 ${orderId} 创建生成任务失败: ${error.message}`);
        }
        return {
            success: true,
            orderId: order.id,
            status: order.status,
        };
    }
    async verifyAppleReceipt(receiptData, transactionId) {
        try {
            let response = await this.requestAppleVerify(this.appleVerifyUrl, receiptData);
            if (response.status === 21007) {
                this.logger.log('检测到沙盒收据，切换到沙盒环境验证');
                response = await this.requestAppleVerify(this.appleSandboxUrl, receiptData);
            }
            if (response.status !== 0) {
                this.logger.warn(`Apple 验证失败，状态码: ${response.status}`);
                return false;
            }
            const receipts = response.latest_receipt_info || response.receipt?.in_app || [];
            const matchedTransaction = receipts.find((item) => item.transaction_id === transactionId || item.original_transaction_id === transactionId);
            if (!matchedTransaction) {
                this.logger.warn(`未找到匹配的交易ID: ${transactionId}`);
                return false;
            }
            return true;
        }
        catch (error) {
            this.logger.error(`Apple 验证请求失败: ${error.message}`);
            return false;
        }
    }
    async requestAppleVerify(url, receiptData) {
        const password = this.configService.get('APPLE_SHARED_SECRET');
        const payload = { 'receipt-data': receiptData };
        if (password) {
            payload.password = password;
        }
        const response = await axios_1.default.post(url, payload, {
            headers: { 'Content-Type': 'application/json' },
            timeout: 30000,
        });
        return response.data;
    }
};
exports.PaymentService = PaymentService;
exports.PaymentService = PaymentService = PaymentService_1 = __decorate([
    (0, common_1.Injectable)(),
    __param(1, (0, typeorm_1.InjectRepository)(order_entity_1.Order)),
    __metadata("design:paramtypes", [config_1.ConfigService,
        typeorm_2.Repository,
        task_service_1.TaskService])
], PaymentService);
//# sourceMappingURL=payment.service.js.map