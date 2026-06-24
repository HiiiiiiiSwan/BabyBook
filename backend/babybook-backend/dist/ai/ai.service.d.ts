import { ConfigService } from '@nestjs/config';
import { BookTemplate } from '../common/enums';
interface GenerateImageParams {
    bookId: BookTemplate;
    imageUrl: string;
}
export declare class AiService {
    private configService;
    private readonly logger;
    private readonly apiKey;
    private readonly apiUrl;
    private readonly modelName;
    constructor(configService: ConfigService);
    generateBookImage(params: GenerateImageParams): Promise<string>;
    private buildPrompt;
}
export {};
