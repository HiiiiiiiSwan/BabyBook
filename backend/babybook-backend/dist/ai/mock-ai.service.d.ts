import { ConfigService } from '@nestjs/config';
export declare class MockAiService {
    private configService;
    constructor(configService: ConfigService);
    generateBookImage(params: any): Promise<string>;
    private delay;
}
