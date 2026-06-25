import { ConfigService } from '@nestjs/config';
export declare class MockAiService {
    private configService;
    constructor(configService: ConfigService);
    generateBookImage(params: {
        bookId: string;
        imageUrl: string;
    }): Promise<string>;
    private delay;
}
