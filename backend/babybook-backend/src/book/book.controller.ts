import { Controller, Get, Param, Res, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import type { Response } from 'express';
import { BookService } from './book.service';

@ApiTags('绘本')
@Controller('api/book')
export class BookController {
  constructor(private readonly bookService: BookService) {}

  @Get(':orderId/download')
  @ApiOperation({ summary: '获取绘本下载信息' })
  @ApiResponse({ status: 200, description: '获取成功' })
  @ApiResponse({ status: 404, description: '绘本不存在或未生成完成' })
  async getDownloadInfo(@Param('orderId') orderId: string) {
    return this.bookService.getBookDownloadInfo(orderId);
  }

  @Get(':orderId/image')
  @ApiOperation({ summary: '下载绘本图片' })
  @ApiResponse({ status: 200, description: '下载成功' })
  @ApiResponse({ status: 404, description: '图片不存在' })
  async downloadImage(@Param('orderId') orderId: string, @Res() res: Response) {
    try {
      const imageBuffer = await this.bookService.getBookImage(orderId);
      res.setHeader('Content-Type', 'image/png');
      res.setHeader('Content-Disposition', `attachment; filename="book_${orderId}.png"`);
      res.send(imageBuffer);
    } catch (error) {
      res.status(HttpStatus.NOT_FOUND).json({ message: error.message });
    }
  }
}
