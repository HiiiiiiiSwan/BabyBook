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
exports.UploadController = void 0;
const common_1 = require("@nestjs/common");
const platform_express_1 = require("@nestjs/platform-express");
const swagger_1 = require("@nestjs/swagger");
const fs_1 = require("fs");
const config_1 = require("@nestjs/config");
const multer = require('multer');
const storage = multer.diskStorage({
    destination: './uploads/temp',
    filename: (req, file, callback) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const ext = file.originalname ? file.originalname.substring(file.originalname.lastIndexOf('.')) : '.jpg';
        callback(null, `baby-${uniqueSuffix}${ext}`);
    },
});
const imageFileFilter = (req, file, callback) => {
    if (!file.originalname.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
        return callback(new Error('仅支持 JPG、PNG、GIF、WebP 格式的图片'), false);
    }
    callback(null, true);
};
let UploadController = class UploadController {
    configService;
    constructor(configService) {
        this.configService = configService;
    }
    async uploadImage(file) {
        if (!file) {
            throw new Error('上传文件为空');
        }
        const baseUrl = this.configService.get('BASE_URL', 'http://localhost:3000');
        const imageUrl = `${baseUrl}/api/upload/image/${file.filename}`;
        return {
            success: true,
            imageUrl,
            filename: file.filename,
            size: file.size,
        };
    }
    async getImage(filename, res) {
        const filePath = `./uploads/temp/${filename}`;
        if (!(0, fs_1.existsSync)(filePath)) {
            throw new common_1.NotFoundException('图片不存在');
        }
        res.sendFile(filePath, { root: '.' });
    }
    async deleteImage(filename) {
        const filePath = `./uploads/temp/${filename}`;
        if ((0, fs_1.existsSync)(filePath)) {
            (0, fs_1.unlinkSync)(filePath);
        }
        return { success: true, message: '图片已删除' };
    }
};
exports.UploadController = UploadController;
__decorate([
    (0, common_1.Post)('image'),
    (0, swagger_1.ApiOperation)({ summary: '上传宝宝照片' }),
    (0, swagger_1.ApiConsumes)('multipart/form-data'),
    (0, swagger_1.ApiResponse)({ status: 201, description: '上传成功' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: '文件格式错误' }),
    (0, common_1.UseInterceptors)((0, platform_express_1.FileInterceptor)('image', {
        storage: storage,
        fileFilter: imageFileFilter,
        limits: {
            fileSize: 10 * 1024 * 1024,
        },
    })),
    __param(0, (0, common_1.UploadedFile)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], UploadController.prototype, "uploadImage", null);
__decorate([
    (0, common_1.Get)('image/:filename'),
    (0, swagger_1.ApiOperation)({ summary: '获取上传的图片' }),
    __param(0, (0, common_1.Param)('filename')),
    __param(1, (0, common_1.Res)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", Promise)
], UploadController.prototype, "getImage", null);
__decorate([
    (0, common_1.Delete)('image/:filename'),
    (0, swagger_1.ApiOperation)({ summary: '删除临时图片' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: '删除成功' }),
    __param(0, (0, common_1.Param)('filename')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UploadController.prototype, "deleteImage", null);
exports.UploadController = UploadController = __decorate([
    (0, swagger_1.ApiTags)('上传'),
    (0, common_1.Controller)('api/upload'),
    __metadata("design:paramtypes", [config_1.ConfigService])
], UploadController);
//# sourceMappingURL=upload.controller.js.map