import type { Response } from 'express';
import { ConfigService } from '@nestjs/config';
export declare class UploadController {
    private readonly configService;
    constructor(configService: ConfigService);
    uploadImage(file: any): Promise<{
        success: boolean;
        imageUrl: string;
        filename: any;
        size: any;
    }>;
    getImage(filename: string, res: Response): Promise<void>;
    deleteImage(filename: string): Promise<{
        success: boolean;
        message: string;
    }>;
}
