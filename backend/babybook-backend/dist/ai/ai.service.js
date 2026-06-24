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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
var AiService_1;
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const axios_1 = __importDefault(require("axios"));
const enums_1 = require("../common/enums");
let AiService = AiService_1 = class AiService {
    configService;
    logger = new common_1.Logger(AiService_1.name);
    apiKey;
    apiUrl;
    modelName;
    constructor(configService) {
        this.configService = configService;
        this.apiKey = this.configService.get('DOUBAO_API_KEY', '');
        this.apiUrl = this.configService.get('DOUBAO_API_URL', 'https://ark.cn-beijing.volces.com/api/v3/images/generations');
        this.modelName = this.configService.get('DOUBAO_MODEL', 'seedream-5.0-lite');
    }
    async generateBookImage(params) {
        const { bookId, imageUrl } = params;
        if (!this.apiKey) {
            throw new Error('豆包 API Key 未配置');
        }
        const prompt = this.buildPrompt(bookId);
        this.logger.log(`开始生成绘本图片: ${bookId}, 模型: ${this.modelName}`);
        try {
            const requestBody = {
                model: this.modelName,
                prompt: prompt,
                reference_images: [
                    {
                        image_url: imageUrl,
                        reference_type: 'character',
                    },
                ],
                width: 2048,
                height: 2048,
                response_format: 'url',
            };
            const response = await axios_1.default.post(this.apiUrl, requestBody, {
                headers: {
                    Authorization: `Bearer ${this.apiKey}`,
                    'Content-Type': 'application/json',
                },
                timeout: 300000,
            });
            if (response.data.error) {
                throw new Error(`AI 生成失败: ${response.data.error.message}`);
            }
            const resultUrl = response.data.data?.image_url ||
                response.data.data?.images?.[0];
            if (!resultUrl) {
                throw new Error('AI 生成返回结果为空');
            }
            this.logger.log(`绘本图片生成成功: ${resultUrl.substring(0, 50)}...`);
            return resultUrl;
        }
        catch (error) {
            this.logger.error(`AI 生成失败: ${error.message}`);
            throw new Error(`AI 生成失败: ${error.message}`);
        }
    }
    buildPrompt(bookId) {
        const basePrompt = 'Create a warm storybook 3D illustration in a 3x3 grid layout (2048x2048). ' +
            'Each cell contains one page of a children\'s picture book. ' +
            'Style: Warm Storybook 3D, cute chibi proportions, rounded shapes, soft lighting, low complexity details. ' +
            'The main character is the baby from the reference photo. ' +
            'Background elements: clouds, grass, hot air balloons, teddy bears, rabbits, stars, books, leaves. ';
        const bookPrompts = {
            [enums_1.BookTemplate.SELF_INTRO]: basePrompt +
                'Theme: Body awareness "This is Me". ' +
                'Page 1: Cover with title "This is Me" and the baby. ' +
                'Page 2: "This is my head" - baby touching head. ' +
                'Page 3: "This is my eyes" - baby pointing to eyes. ' +
                'Page 4: "This is my nose" - baby touching nose. ' +
                'Page 5: "This is my mouth" - baby smiling. ' +
                'Page 6: "This is my ears" - baby touching ears. ' +
                'Page 7: "This is my hands" - baby waving hands. ' +
                'Page 8: "This is my feet" - baby showing feet. ' +
                'Page 9: "I love myself" - baby hugging self. ' +
                'Color palette: warm orange #F28C28, cream #FFF9F2, soft green.',
            [enums_1.BookTemplate.DREAM_JOB]: basePrompt +
                'Theme: Career awareness "What I Want to Be When I Grow Up". ' +
                'Page 1: Cover with title and the baby in a graduation cap. ' +
                'Page 2: "I want to be a doctor" - baby with stethoscope. ' +
                'Page 3: "I want to be a teacher" - baby with books. ' +
                'Page 4: "I want to be a chef" - baby with chef hat. ' +
                'Page 5: "I want to be an astronaut" - baby in space suit. ' +
                'Page 6: "I want to be a firefighter" - baby with helmet. ' +
                'Page 7: "I want to be a scientist" - baby with microscope. ' +
                'Page 8: "I want to be an artist" - baby with paintbrush. ' +
                'Page 9: "I can be anything" - baby surrounded by all professions. ' +
                'Color palette: warm orange #F28C28, sky blue, soft yellow.',
            [enums_1.BookTemplate.COLOR_RECOGNITION]: basePrompt +
                'Theme: Color recognition "Learning Colors". ' +
                'Page 1: Cover with title "Learning Colors" and rainbow. ' +
                'Page 2: "Red" - red apple, red balloon, red flower. ' +
                'Page 3: "Orange" - orange fruit, orange sun, orange cat. ' +
                'Page 4: "Yellow" - yellow banana, yellow star, yellow duck. ' +
                'Page 5: "Green" - green leaf, green frog, green tree. ' +
                'Page 6: "Blue" - blue sky, blue whale, blue bird. ' +
                'Page 7: "Purple" - purple grape, purple butterfly, purple flower. ' +
                'Page 8: "Pink" - pink pig, pink flower, pink candy. ' +
                'Page 9: "All colors together" - rainbow with the baby. ' +
                'Color palette: vibrant but soft, pastel backgrounds.',
        };
        return bookPrompts[bookId] || basePrompt;
    }
};
exports.AiService = AiService;
exports.AiService = AiService = AiService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], AiService);
//# sourceMappingURL=ai.service.js.map