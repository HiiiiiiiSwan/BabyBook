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
exports.BookController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const book_service_1 = require("./book.service");
let BookController = class BookController {
    bookService;
    constructor(bookService) {
        this.bookService = bookService;
    }
    async getDownloadInfo(orderId) {
        return this.bookService.getBookDownloadInfo(orderId);
    }
    async downloadImage(orderId, res) {
        try {
            const imageBuffer = await this.bookService.getBookImage(orderId);
            res.setHeader('Content-Type', 'image/png');
            res.setHeader('Content-Disposition', `attachment; filename="book_${orderId}.png"`);
            res.send(imageBuffer);
        }
        catch (error) {
            res.status(common_1.HttpStatus.NOT_FOUND).json({ message: error.message });
        }
    }
};
exports.BookController = BookController;
__decorate([
    (0, common_1.Get)(':orderId/download'),
    (0, swagger_1.ApiOperation)({ summary: '获取绘本下载信息' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: '获取成功' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: '绘本不存在或未生成完成' }),
    __param(0, (0, common_1.Param)('orderId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], BookController.prototype, "getDownloadInfo", null);
__decorate([
    (0, common_1.Get)(':orderId/image'),
    (0, swagger_1.ApiOperation)({ summary: '下载绘本图片' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: '下载成功' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: '图片不存在' }),
    __param(0, (0, common_1.Param)('orderId')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], BookController.prototype, "downloadImage", null);
exports.BookController = BookController = __decorate([
    (0, swagger_1.ApiTags)('绘本'),
    (0, common_1.Controller)('api/book'),
    __metadata("design:paramtypes", [book_service_1.BookService])
], BookController);
//# sourceMappingURL=book.controller.js.map