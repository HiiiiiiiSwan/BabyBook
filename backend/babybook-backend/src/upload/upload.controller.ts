import { Controller, Post, UseInterceptors, UploadedFile, Get, Param, Res, NotFoundException, Delete, UseGuards, Req, UnauthorizedException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiOperation, ApiResponse, ApiConsumes } from '@nestjs/swagger';
import type { Response } from 'express';
import { existsSync, unlinkSync } from 'fs';
import { ConfigService } from '@nestjs/config';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import { Request } from 'express';

/**
 * 图片上传配置
 */
const multer = require('multer');

const storage = multer.diskStorage({
  destination: './uploads/temp',
  filename: (req: any, file: any, callback: any) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const ext = file.originalname ? file.originalname.substring(file.originalname.lastIndexOf('.')) : '.jpg';
    callback(null, `baby-${uniqueSuffix}${ext}`);
  },
});

/**
 * 文件过滤器 - 仅允许图片
 */
const imageFileFilter = (req: any, file: any, callback: any) => {
  if (!file.originalname.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
    return callback(new Error('仅支持 JPG、PNG、GIF、WebP 格式的图片'), false);
  }
  callback(null, true);
};

/**
 * 图片上传控制器
 * 处理宝宝照片的临时上传和获取
 * 生成完成后立即删除，符合数据最小化原则
 */
@ApiTags('上传')
@Controller('api/upload')
export class UploadController {
  constructor(private readonly configService: ConfigService) {}

  /**
   * 上传宝宝照片
   */
  @Post('image')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '上传宝宝照片' })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({ status: 201, description: '上传成功' })
  @ApiResponse({ status: 400, description: '文件格式错误' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  @UseInterceptors(
    FileInterceptor('image', {
      storage: storage,
      fileFilter: imageFileFilter,
      limits: {
        fileSize: 10 * 1024 * 1024, // 10MB 限制
      },
    }),
  )
  async uploadImage(@UploadedFile() file: any, @Req() req: Request) {
    if (!file) {
      throw new Error('上传文件为空');
    }

    // 构建临时访问 URL
    const baseUrl = this.configService.get('BASE_URL', 'http://localhost:3000');
    const imageUrl = `${baseUrl}/api/upload/image/${file.filename}`;

    return {
      success: true,
      imageUrl,
      filename: file.filename,
      size: file.size,
    };
  }

  /**
   * 获取上传的图片
   */
  @Get('image/:filename')
  @ApiOperation({ summary: '获取上传的图片' })
  async getImage(@Param('filename') filename: string, @Res() res: Response) {
    const filePath = `./uploads/temp/${filename}`;

    if (!existsSync(filePath)) {
      throw new NotFoundException('图片不存在');
    }

    res.sendFile(filePath, { root: '.' });
  }

  /**
   * 删除临时图片
   * 生成完成后调用，符合数据最小化原则
   */
  @Delete('image/:filename')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '删除临时图片' })
  @ApiResponse({ status: 200, description: '删除成功' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async deleteImage(@Param('filename') filename: string, @Req() req: Request) {
    const filePath = `./uploads/temp/${filename}`;

    if (existsSync(filePath)) {
      unlinkSync(filePath);
    }

    return { success: true, message: '图片已删除' };
  }
}
