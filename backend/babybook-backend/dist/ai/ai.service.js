"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
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
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
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
        this.modelName = this.configService.get('DOUBAO_MODEL', 'doubao-seedream-5-0-260128');
    }
    async generateBookImage(params) {
        const { bookId, imageUrl } = params;
        if (!this.apiKey) {
            throw new Error('豆包 API Key 未配置');
        }
        const templatePath = this.getTemplatePath(bookId);
        if (!fs.existsSync(templatePath)) {
            throw new Error(`模板文件不存在: ${templatePath}`);
        }
        const templateBase64 = await fs.promises.readFile(templatePath)
            .then(b => b.toString('base64'));
        this.logger.log(`正在下载宝宝照片: ${imageUrl}`);
        const babyPhotoBase64 = await this.downloadImageToBase64(imageUrl);
        this.logger.log(`宝宝照片下载完成，Base64 长度: ${babyPhotoBase64.length}`);
        const prompt = this.buildPrompt(bookId);
        this.logger.log(`开始生成绘本图片: ${bookId}, 模型: ${this.modelName}`);
        this.logger.log(`模板: ${templatePath}`);
        try {
            const requestBody = {
                model: this.modelName,
                prompt: prompt,
                sequential_image_generation: 'disabled',
                response_format: 'url',
                size: '2K',
                stream: false,
                watermark: true,
                image: [
                    `data:image/png;base64,${templateBase64}`,
                    `data:image/png;base64,${babyPhotoBase64}`,
                ],
            };
            const response = await axios_1.default.post(this.apiUrl, requestBody, {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.apiKey}`,
                },
                timeout: 300000,
            });
            if (response.data.error) {
                throw new Error(`AI 生成失败: ${response.data.error.message} (code: ${response.data.error.code})`);
            }
            const resultUrl = response.data.data?.[0]?.url ||
                response.data.data?.[0]?.image_url ||
                response.data.data?.[0]?.images?.[0];
            if (!resultUrl) {
                this.logger.error(`API 响应: ${JSON.stringify(response.data)}`);
                throw new Error('AI 生成返回结果为空');
            }
            this.logger.log(`绘本图片生成成功: ${resultUrl.substring(0, 60)}...`);
            const outputDir = path.join(process.cwd(), 'uploads', 'generated');
            if (!fs.existsSync(outputDir)) {
                fs.mkdirSync(outputDir, { recursive: true });
            }
            const outputPath = path.join(outputDir, `book_${bookId}_${Date.now()}.png`);
            await this.saveImageToFile(resultUrl, outputPath);
            this.logger.log(`图片已保存到: ${outputPath}`);
            return resultUrl;
        }
        catch (error) {
            this.logger.error(`AI 生成失败: ${error.message}`);
            if (error.response) {
                this.logger.error(`API 响应状态: ${error.response.status}`);
                this.logger.error(`API 响应数据: ${JSON.stringify(error.response.data)}`);
            }
            throw new Error(`AI 生成失败: ${error.message}`);
        }
    }
    getTemplatePath(bookId) {
        const projectRoot = path.join(process.cwd(), '..', '..');
        const templatePaths = {
            [enums_1.BookTemplate.SELF_INTRO]: path.join(projectRoot, 'templates', 'self_intro', 'all-none.png'),
            [enums_1.BookTemplate.DREAM_JOB]: path.join(projectRoot, 'templates', 'dream_job', 'all-none.png'),
            [enums_1.BookTemplate.COLOR_RECOGNITION]: path.join(projectRoot, 'templates', 'color_recognition', 'all-none.png'),
        };
        let templatePath = templatePaths[bookId];
        if (!fs.existsSync(templatePath)) {
            const altRoot = path.join(process.cwd(), '..');
            const altPaths = {
                [enums_1.BookTemplate.SELF_INTRO]: path.join(altRoot, 'templates', 'self_intro', 'all-none.png'),
                [enums_1.BookTemplate.DREAM_JOB]: path.join(altRoot, 'templates', 'dream_job', 'all-none.png'),
                [enums_1.BookTemplate.COLOR_RECOGNITION]: path.join(altRoot, 'templates', 'color_recognition', 'all-none.png'),
            };
            templatePath = altPaths[bookId];
        }
        return templatePath;
    }
    buildPrompt(bookId) {
        const prompts = {
            [enums_1.BookTemplate.SELF_INTRO]: this.buildSelfIntroPrompt(),
            [enums_1.BookTemplate.DREAM_JOB]: this.buildDreamJobPrompt(),
            [enums_1.BookTemplate.COLOR_RECOGNITION]: this.buildColorRecognitionPrompt(),
        };
        return prompts[bookId] || this.buildSelfIntroPrompt();
    }
    buildSelfIntroPrompt() {
        return `【任务：将九宫格模板中的红色占位区域替换为同一个宝宝的真实照片】

图1是九宫格模板，每个格子左侧有编号、图标、文字说明，右侧红色区域是占位区。
图2是参考宝宝照片。

核心任务：将图1中每个格子的红色区域替换为图2中的同一个宝宝形象，每个格子展示宝宝不同的身体部位特写。

【九宫格布局说明】（3×3网格，从上到下、从左到右）：

第1行：
- 格子1（左上）：编号① Head 头 — 宝宝头部特写，面向镜头，展示完整的头部、耳朵、脖子、肩膀
- 格子2（中上）：编号② Eye 眼睛 — 宝宝眼睛特写，面向镜头，展示完整的眼睛、眉毛、部分脸部
- 格子3（右上）：编号③ Ear 耳朵 — 宝宝耳朵特写，侧脸或正面，展示完整的耳朵和周围区域

第2行：
- 格子4（左中）：编号④ Nose 鼻子 — 宝宝鼻子特写，面向镜头，展示完整的鼻子和周围区域
- 格子5（正中）：编号⑤ Mouth 嘴巴 — 宝宝嘴巴特写，微笑表情，展示完整的嘴巴和周围区域
- 格子6（右中）：编号⑥ Neck 脖子 — 宝宝脖子特写，展示完整的脖子和周围区域

第3行：
- 格子7（左下）：编号⑦ Hand 手 — 宝宝手部特写，展示完整的手掌、手指，宝宝穿着浅色衣物，手臂自然伸展
- 格子8（中下）：编号⑧ Tummy 肚子 — 宝宝肚子特写，展示完整的肚子和肚脐，宝宝穿着露肚装或衣服撩起露出肚子，肚子圆润可爱
- 格子9（右下）：编号⑨ Foot 脚 — 宝宝脚部特写，展示完整的脚掌、脚趾，脚趾数量必须是5个，排列自然整齐

【人物要求】（所有格子共用同一个宝宝）：
- 真实摄影风格，柔和自然光，商业儿童摄影质感
- 人物肤色：白皙偏粉，带有婴儿健康红润感（即使参考图偏黄也要调整为白皙粉嫩）
- 光线：柔和自然光，明亮干净，专业摄影棚效果
- 整体色调：明亮、干净、温暖
- 高清8k，真实皮肤纹理，能看到毛孔和发丝细节
- 这必须是同一个宝宝，不能每个格子变成不同的人
- 表情自然、可爱、天真的微笑表情
- 每个格子中宝宝人物尽量完整展示（至少展示上半身或全身），同时强化对应部位特写
- 格子8（肚子）宝宝必须穿着露肚装或衣服撩起，完整展示圆润可爱的肚子和肚脐
- 格子9（脚）脚趾数量必须是5个，排列自然整齐，不能多也不能少

【必须保留的模板内容】（绝对不变）：
- 所有编号（①②③④⑤⑥⑦⑧⑨）的位置、颜色、样式必须完全保留
- 所有英文标题（Head, Eye, Ear, Nose, Mouth, Neck, Hand, Tummy, Foot）必须完全保留
- 所有中文标题（头、眼睛、耳朵、鼻子、嘴巴、脖子、手、肚子、脚）必须完全保留
- 所有图标（头部、眼睛、耳朵、鼻子、嘴巴、脖子、手、肚子、脚的简笔图标）必须完全保留
- 所有英文说明文字（This is my...）必须完全保留
- 所有中文说明文字（这是我的...）必须完全保留
- 所有虚线箭头从编号指向宝宝对应的身体部位必须完全保留
- 模板背景颜色（米色/奶油色）必须完全保留
- 格子之间的分隔线必须完全保留

【背景要求】（非常重要）：
- 人物背景必须是透明（alpha通道），不是白色或任何颜色
- 人物边缘必须自然融入模板背景，不能有任何白色边框、灰色边框或光晕
- 人物必须与模板背景颜色完全一致，看起来像原本就是模板的一部分
- 人物边缘不能有锯齿、模糊、光晕等痕迹
- 人物光影必须与模板整体光影一致

【禁止】：
- 禁止输出红色背景
- 禁止人物背景为白色、灰色或任何颜色（必须是透明）
- 禁止人物边缘有白色边框、灰色边框、光晕
- 禁止改变任何文字内容、位置、字体、颜色
- 禁止改变任何图标、箭头位置
- 禁止遮挡编号和说明文字
- 禁止添加照片框、白色边框
- 禁止卡通或插画风格
- 禁止每个格子生成不同的宝宝（必须是同一个宝宝）
- 禁止拼贴感、合成感、贴图感
- 禁止格子8（肚子）中宝宝衣服遮挡肚子，必须露出肚子
- 禁止格子9（脚）中脚趾数量不是5个，必须严格5个脚趾`;
    }
    buildDreamJobPrompt() {
        return `【任务：将九宫格模板中的红色占位区域替换为同一个宝宝的真实照片】

图1是九宫格模板，每个格子左侧有编号、图标、文字说明，右侧红色区域是占位区。
图2是参考宝宝照片。

核心任务：将图1中每个格子的红色区域替换为图2中的同一个宝宝形象，每个格子展示宝宝扮演不同职业的造型。

【九宫格布局说明】（3×3网格，从上到下、从左到右）：

第1行：
- 格子1（左上）：编号① Doctor 医生 — 宝宝穿着医生白大褂，戴着听诊器，扮演医生
- 格子2（中上）：编号② Teacher 老师 — 宝宝戴着眼镜，拿着教鞭或书本，扮演老师
- 格子3（右上）：编号③ Astronaut 宇航员 — 宝宝穿着宇航服，戴着头盔，扮演宇航员

第2行：
- 格子4（左中）：编号④ Police Officer 警察 — 宝宝穿着警服，戴着警帽，扮演警察
- 格子5（正中）：编号⑤ Athlete 运动员 — 宝宝穿着运动服，抱着足球，扮演运动员
- 格子6（右中）：编号⑥ Scientist 科学家 — 宝宝穿着实验服，戴着护目镜，拿着试管，扮演科学家

第3行：
- 格子7（左下）：编号⑦ Chef 厨师 — 宝宝穿着厨师服，戴着厨师帽，拿着锅铲，扮演厨师
- 格子8（中下）：编号⑧ Writer 作家 — 宝宝戴着贝雷帽，拿着笔和本子，扮演作家
- 格子9（右下）：编号⑨ Musician 音乐家 — 宝宝穿着正装，拿着小提琴或吉他，扮演音乐家

【人物要求】（所有格子共用同一个宝宝）：
- 真实摄影风格，柔和自然光，商业儿童摄影质感
- 人物肤色：白皙偏粉，带有婴儿健康红润感（即使参考图偏黄也要调整为白皙粉嫩）
- 光线：柔和自然光，明亮干净，专业摄影棚效果
- 整体色调：明亮、干净、温暖
- 高清8k，真实皮肤纹理
- 这必须是同一个宝宝，不能每个格子变成不同的人
- 表情自然、可爱、天真的微笑表情
- 每个格子中宝宝人物尽量完整展示（至少展示上半身或全身）
- 职业服装要真实、精致，符合宝宝身材比例

【必须保留的模板内容】（绝对不变）：
- 所有编号（①②③④⑤⑥⑦⑧⑨）的位置、颜色、样式必须完全保留
- 所有英文标题（Doctor, Teacher, Astronaut, Police Officer, Athlete, Scientist, Chef, Writer, Musician）必须完全保留
- 所有中文标题（医生、老师、宇航员、警察、运动员、科学家、厨师、作家、音乐家）必须完全保留
- 所有图标（听诊器、ABC、火箭、警徽、足球、试管、厨师帽、书本、音符）必须完全保留
- 所有英文说明文字（I help people..., I teach..., I explore...）必须完全保留
- 所有中文说明文字（我帮助病人..., 我教知识..., 我探索太空...）必须完全保留
- 所有虚线箭头从编号指向宝宝对应的职业道具必须完全保留
- 模板背景颜色（米色/奶油色）必须完全保留
- 格子之间的分隔线必须完全保留

【背景要求】：
- 人物背景必须是透明（alpha通道）
- 人物边缘必须自然融入模板背景，不能有任何白色边框、灰色边框或光晕
- 人物必须与模板背景颜色完全一致

【禁止】：
- 禁止输出红色背景
- 禁止人物背景为白色、灰色或任何颜色（必须是透明）
- 禁止改变任何文字内容、位置、字体、颜色
- 禁止卡通或插画风格
- 禁止每个格子生成不同的宝宝（必须是同一个宝宝）
- 禁止拼贴感、合成感、贴图感`;
    }
    buildColorRecognitionPrompt() {
        return `【任务：将九宫格模板中的红色占位区域替换为同一个宝宝的真实照片】

图1是九宫格模板，每个格子展示一种颜色主题，右侧红色区域是占位区。
图2是参考宝宝照片。

核心任务：将图1中每个格子的红色区域替换为图2中的同一个宝宝形象，每个格子展示宝宝与该颜色主题的互动场景。

【九宫格布局说明】（3×3网格，从上到下、从左到右）：

第1行：
- 格子1（左上）：封面 — 宝宝与彩虹合影，标题"认识颜色"
- 格子2（中上）：红色 Red — 宝宝拿着红苹果、红色气球， surrounded by 红色元素
- 格子3（右上）：橙色 Orange — 宝宝抱着橙子，周围有橙色太阳、橙色猫咪

第2行：
- 格子4（左中）：黄色 Yellow — 宝宝拿着香蕉，周围有黄色星星、黄色小鸭子
- 格子5（正中）：绿色 Green — 宝宝触摸绿色树叶，周围有绿色青蛙、绿色大树
- 格子6（右中）：蓝色 Blue — 宝宝仰望蓝色天空，周围有蓝色鲸鱼、蓝色小鸟

第3行：
- 格子7（左下）：紫色 Purple — 宝宝拿着紫葡萄，周围有紫色蝴蝶、紫色花朵
- 格子8（中下）：粉色 Pink — 宝宝抱着粉色小猪，周围有粉色花朵、粉色糖果
- 格子9（右下）：彩虹总结 — 宝宝站在彩虹下，周围汇聚所有颜色元素

【人物要求】（所有格子共用同一个宝宝）：
- 真实摄影风格，柔和自然光，商业儿童摄影质感
- 人物肤色：白皙偏粉，带有婴儿健康红润感（即使参考图偏黄也要调整为白皙粉嫩）
- 光线：柔和自然光，明亮干净，专业摄影棚效果
- 整体色调：明亮、干净、温暖
- 高清8k，真实皮肤纹理
- 这必须是同一个宝宝，不能每个格子变成不同的人
- 表情自然、可爱、天真的微笑表情
- 每个格子中宝宝人物尽量完整展示
- 颜色元素要鲜艳但柔和，符合儿童绘本风格

【必须保留的模板内容】（绝对不变）：
- 所有编号的位置、颜色、样式必须完全保留
- 所有颜色标题（Red/红, Orange/橙, Yellow/黄, Green/绿, Blue/蓝, Purple/紫, Pink/粉）必须完全保留
- 所有图标必须完全保留
- 所有说明文字必须完全保留
- 模板背景颜色必须完全保留
- 格子之间的分隔线必须完全保留

【背景要求】：
- 人物背景必须是透明（alpha通道）
- 人物边缘必须自然融入模板背景

【禁止】：
- 禁止输出红色背景
- 禁止人物背景为白色、灰色或任何颜色（必须是透明）
- 禁止改变任何文字内容、位置、字体、颜色
- 禁止卡通或插画风格
- 禁止每个格子生成不同的宝宝（必须是同一个宝宝）
- 禁止拼贴感、合成感、贴图感`;
    }
    async downloadImageToBase64(imageUrl) {
        try {
            if (imageUrl.startsWith('/api/upload/')) {
                const filename = imageUrl.split('/').pop() || '';
                if (filename) {
                    const localPath = path.join(process.cwd(), 'uploads', 'temp', filename);
                    if (fs.existsSync(localPath)) {
                        const buffer = await fs.promises.readFile(localPath);
                        return buffer.toString('base64');
                    }
                }
            }
            const response = await axios_1.default.get(imageUrl, {
                responseType: 'arraybuffer',
                timeout: 30000,
            });
            return Buffer.from(response.data).toString('base64');
        }
        catch (error) {
            this.logger.error(`下载宝宝照片失败: ${error.message}`);
            throw new Error(`下载宝宝照片失败: ${error.message}`);
        }
    }
    async saveImageToFile(url, outputPath) {
        const response = await axios_1.default.get(url, {
            responseType: 'arraybuffer',
            timeout: 60000,
        });
        await fs.promises.writeFile(outputPath, response.data);
    }
};
exports.AiService = AiService;
exports.AiService = AiService = AiService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [config_1.ConfigService])
], AiService);
//# sourceMappingURL=ai.service.js.map