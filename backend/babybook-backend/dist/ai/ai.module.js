"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const ai_service_1 = require("./ai.service");
const mock_ai_service_1 = require("./mock-ai.service");
const aiServiceProvider = {
    provide: ai_service_1.AiService,
    useFactory: (configService) => {
        const useMock = configService.get('MOCK_AI_GENERATION') === 'true';
        if (useMock) {
            return new mock_ai_service_1.MockAiService(configService);
        }
        return new ai_service_1.AiService(configService);
    },
    inject: [config_1.ConfigService],
};
let AiModule = class AiModule {
};
exports.AiModule = AiModule;
exports.AiModule = AiModule = __decorate([
    (0, common_1.Module)({
        imports: [config_1.ConfigModule],
        providers: [aiServiceProvider, mock_ai_service_1.MockAiService],
        exports: [ai_service_1.AiService],
    })
], AiModule);
//# sourceMappingURL=ai.module.js.map