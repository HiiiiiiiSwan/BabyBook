import { Controller, Get, Param, Res, HttpStatus, UseGuards, Req, UnauthorizedException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import type { Response } from 'express';
import { BookService } from './book.service';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import type { Request } from 'express';

@ApiTags('绘本')
@Controller('api/book')
export class BookController {
  constructor(private readonly bookService: BookService) {}

  @Get(':orderId/download')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '获取绘本下载信息' })
  @ApiResponse({ status: 200, description: '获取成功' })
  @ApiResponse({ status: 404, description: '绘本不存在或未生成完成' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async getDownloadInfo(@Param('orderId') orderId: string, @Req() req: Request) {
    // 验证设备权限
    const deviceId = req['deviceId'];
    const order = await this.bookService.getOrder(orderId);
    if (order.deviceId !== deviceId) {
      throw new UnauthorizedException('无权访问此绘本');
    }
    return this.bookService.getBookDownloadInfo(orderId);
  }

  @Get(':orderId/image')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '下载绘本图片' })
  @ApiResponse({ status: 200, description: '下载成功' })
  @ApiResponse({ status: 404, description: '图片不存在' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async downloadImage(@Param('orderId') orderId: string, @Res() res: Response, @Req() req: Request) {
    try {
      // 验证设备权限
      const deviceId = req['deviceId'];
      const order = await this.bookService.getOrder(orderId);
      if (order.deviceId !== deviceId) {
        throw new UnauthorizedException('无权访问此绘本');
      }

      const imageBuffer = await this.bookService.getBookImage(orderId);
      res.setHeader('Content-Type', 'image/png');
      res.setHeader('Content-Disposition', `attachment; filename="book_${orderId}.png"`);
      res.send(imageBuffer);
    } catch (error) {
      res.status(HttpStatus.NOT_FOUND).json({ message: error.message });
    }
  }
}
