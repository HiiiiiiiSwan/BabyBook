import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { UploadController } from './upload.controller';

/**
 * 图片上传模块
 * 处理宝宝照片的临时上传
 */
@Module({
  imports: [ConfigModule],
  controllers: [UploadController],
})
export class UploadModule {}
