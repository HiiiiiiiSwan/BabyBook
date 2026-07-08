import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import * as fs from 'fs';
import * as path from 'path';
import { BookTemplate } from '../common/enums';

/**
 * AI 生成请求参数
 */
interface GenerateImageParams {
  bookId: BookTemplate;
  imageUrl: string; // 宝宝照片 URL（后端 uploads/temp 目录）
}

/**
 * AI 生成结果
 */
export interface GenerateImageResult {
  resultUrl: string; // AI 返回的图片 URL
  localPath: string; // 本地临时保存路径
}

/**
 * 豆包 Seedream API 响应
 */
interface SeedreamResponse {
  data?: {
    url?: string;
    image_url?: string;
    images?: string[];
  }[];
  error?: {
    code: string;
    message: string;
  };
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly apiKey: string;
  private readonly apiUrl: string;
  private readonly modelName: string;

  constructor(private configService: ConfigService) {
    this.apiKey = this.configService.get<string>('DOUBAO_API_KEY', '');
    this.apiUrl = this.configService.get<string>(
      'DOUBAO_API_URL',
      'https://ark.cn-beijing.volces.com/api/v3/images/generations',
    );
    this.modelName = this.configService.get<string>('DOUBAO_MODEL', 'doubao-seedream-5-0-260128');
  }

  /**
   * 生成绘本九宫格图片
   * 核心业务：单本绘本仅调用一次生图模型，输出单张 1920×1920 九宫格图片
   *
   * 流程：
   * 1. 读取空白模板图（all-none.png）转 Base64
   * 2. 读取宝宝照片转 Base64
   * 3. 构建中文 Prompt（参考 ai_grid_generation_guide.md）
   * 4. 调用豆包 Seedream 5.0 多图参考模式（2图：模板 + 宝宝照片）
   * 5. 下载保存结果
   */
  async generateBookImage(params: GenerateImageParams): Promise<GenerateImageResult> {
    const { bookId, imageUrl } = params;
    const stageStart = this.now();
    const totalStart = stageStart;

    if (!this.apiKey) {
      throw new Error('豆包 API Key 未配置');
    }

    // 1. 获取模板路径
    const templatePath = this.getTemplatePath(bookId);
    if (!fs.existsSync(templatePath)) {
      throw new Error(`模板文件不存在: ${templatePath}`);
    }

    // 2. 读取模板图转 Base64
    const templateBase64 = await fs.promises.readFile(templatePath)
      .then(b => b.toString('base64'));
    this.logger.log(`[AI 生成耗时] 读取模板图完成: ${this.elapsed(totalStart)}ms, 路径: ${templatePath}`);

    // 3. 从 URL 下载宝宝照片并转 Base64
    this.logger.log(`正在下载宝宝照片: ${imageUrl}`);
    const downloadStart = this.now();
    const babyPhotoBase64 = await this.downloadImageToBase64(imageUrl);
    this.logger.log(`[AI 生成耗时] 下载宝宝照片完成: ${this.elapsed(downloadStart)}ms, Base64 长度: ${babyPhotoBase64.length}`);

    // 4. 构建 Prompt
    const prompt = this.buildPrompt(bookId);

    this.logger.log(`开始生成绘本图片: ${bookId}, 模型: ${this.modelName}, 尺寸: 1920×1920`);
    this.logger.log(`模板: ${templatePath}`);

    try {
      // 5. 构建请求体（严格按豆包 API 格式，2图参考模式）
      const requestBody = {
        model: this.modelName,
        prompt: prompt,
        sequential_image_generation: 'disabled',
        response_format: 'url',
        size: '1920x1920', // 在满足豆包最小像素限制（3686400）的前提下降低分辨率，缩短生成耗时
        stream: false,
        watermark: true,
        // 多图参考模式：2张图 — 模板 + 宝宝照片
        image: [
          `data:image/png;base64,${templateBase64}`,
          `data:image/png;base64,${babyPhotoBase64}`,
        ],
      };

      const aiStart = this.now();
      const response = await axios.post<SeedreamResponse>(
        this.apiUrl,
        requestBody,
        {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.apiKey}`,
          },
          timeout: 600000, // 600 秒（10 分钟）超时：AI 生成九宫格实测需 1~5 分钟，预留充足余量
        },
      );
      this.logger.log(`[AI 生成耗时] 豆包 API 返回完成: ${this.elapsed(aiStart)}ms`);

      if (response.data.error) {
        throw new Error(`AI 生成失败: ${response.data.error.message} (code: ${response.data.error.code})`);
      }

      // 获取生成的图片 URL
      const resultUrl =
        response.data.data?.[0]?.url ||
        response.data.data?.[0]?.image_url ||
        response.data.data?.[0]?.images?.[0];

      if (!resultUrl) {
        this.logger.error(`API 响应: ${JSON.stringify(response.data)}`);
        throw new Error('AI 生成返回结果为空');
      }

      this.logger.log(`绘本图片生成成功: ${resultUrl.substring(0, 60)}...`);

      // 下载保存结果到本地
      const saveStart = this.now();
      const outputDir = path.join(process.cwd(), 'uploads', 'generated');
      if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
      }
      const outputPath = path.join(outputDir, `book_${bookId}_${Date.now()}.png`);
      await this.saveImageToFile(resultUrl, outputPath);
      this.logger.log(`[AI 生成耗时] 下载并保存结果图完成: ${this.elapsed(saveStart)}ms, 路径: ${outputPath}`);
      this.logger.log(`[AI 生成耗时] 全流程总耗时: ${this.elapsed(totalStart)}ms`);

      return { resultUrl, localPath: outputPath };
    } catch (error) {
      this.logger.error(`AI 生成失败: ${error.message}`);
      if (error.response) {
        this.logger.error(`API 响应状态: ${error.response.status}`);
        this.logger.error(`API 响应数据: ${JSON.stringify(error.response.data)}`);
      }
      throw new Error(`AI 生成失败: ${error.message}`);
    }
  }

  /**
   * 获取模板文件路径
   * 支持多环境：Docker 容器 /app/templates、本地开发相对路径等
   */
  private getTemplatePath(bookId: BookTemplate): string {
    const dirNames: Record<BookTemplate, string> = {
      [BookTemplate.SELF_INTRO]: 'self_intro',
      [BookTemplate.DREAM_JOB]: 'dream_job',
      [BookTemplate.COLOR_RECOGNITION]: 'color_recognition',
    };
    const dirName = dirNames[bookId];

    const candidates = [
      // Docker 生产环境：模板复制到 /app/templates
      path.join(process.cwd(), 'templates', dirName, 'all-none.png'),
      // 本地开发：从 backend/babybook-backend 向上到项目根
      path.join(process.cwd(), '..', '..', 'templates', dirName, 'all-none.png'),
      // 本地运行构建产物：从 dist/src 向上到项目根
      path.join(process.cwd(), '..', '..', '..', 'templates', dirName, 'all-none.png'),
    ];

    for (const candidate of candidates) {
      if (fs.existsSync(candidate)) {
        return candidate;
      }
    }

    // 均不存在时返回第一个候选，触发标准“模板文件不存在”错误
    return candidates[0];
  }

  /**
   * 构建绘本生成 Prompt
   * 根据绘本模板生成对应的九宫格内容描述
   * 参考 ai_grid_generation_guide.md 的详细 Prompt 模板
   */
  private buildPrompt(bookId: BookTemplate): string {
    // 当前 MVP 阶段只启用《这是我》绘本
    // 其他绘本 Prompt 已准备好，效果验证后可直接复用

    const prompts: Record<BookTemplate, string> = {
      [BookTemplate.SELF_INTRO]: this.buildSelfIntroPrompt(),
      [BookTemplate.DREAM_JOB]: this.buildDreamJobPrompt(),
      [BookTemplate.COLOR_RECOGNITION]: this.buildColorRecognitionPrompt(),
    };

    return prompts[bookId] || this.buildSelfIntroPrompt();
  }

  /**
   * 《这是我》身体认知绘本 Prompt
   * 参考 ai_grid_generation_guide.md 的完整 Prompt 模板
   */
  private buildSelfIntroPrompt(): string {
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

  /**
   * 《我长大想做什么》职业认知绘本 Prompt
   * 效果验证后启用
   */
  private buildDreamJobPrompt(): string {
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

  /**
   * 《认识颜色》颜色认知绘本 Prompt
   * 每个格子严格对应一种颜色，无封面/封底/总结页
   */
  private buildColorRecognitionPrompt(): string {
    return `【任务：将九宫格模板中的红色占位区域替换为同一个宝宝的真实照片】

图1是九宫格模板，每个格子左侧有编号、颜色名称、颜料图标、中英说明文字，右侧大块红色区域是占位区。
图2是参考宝宝照片。

核心任务：将图1中每个格子的红色占位区域替换为图2中的同一个宝宝形象，每个格子只展示一种主题颜色，宝宝穿着该颜色衣服并手持该颜色代表性物品。

【重要：九宫格不是封面，没有总结页】
这9个格子是9个独立的颜色认知页，从左到右、从上到下依次是：红色、橙色、黄色、绿色、蓝色、紫色、粉色、棕色、灰色。
- 格子1绝对不能做成封面，不能出现"认识颜色"大标题、彩虹拱门、多色汇聚
- 格子9绝对不能做成封底/总结页，不能出现彩虹、烟花、多色元素汇聚
- 每个格子只突出一种纯色主题

【九宫格布局说明】（3×3网格，从上到下、从左到右，每个格子只突出一种颜色）：

第1行：
- 格子1（左上）：编号① Red 红色 — 宝宝穿着红色上衣，双手捧着一个鲜艳的红苹果，周围可点缀一朵红色小花。主题色必须是纯正红色，不能是彩虹或多色。
- 格子2（中上）：编号② Orange 橙色 — 宝宝穿着橙色上衣或橙色围兜，双手握着一根橙色胡萝卜，周围可点缀一个橙子。主题色必须是纯正橙色，不能偏红或偏黄。
- 格子3（右上）：编号③ Yellow 黄色 — 宝宝穿着黄色上衣，手里拿着一朵黄色向日葵或一根黄色香蕉，周围可点缀黄色小星星。主题色必须是明亮黄色。

第2行：
- 格子4（左中）：编号④ Green 绿色 — 宝宝穿着绿色上衣，手触摸绿色树叶或青苹果，周围可点缀一只绿色小青蛙。主题色必须是自然绿色。
- 格子5（正中）：编号⑤ Blue 蓝色 — 宝宝穿着蓝色上衣，仰望蓝色天空，周围可点缀蓝色鲸鱼、蓝色小鸟或蓝色气球。主题色必须是天蓝色/正蓝色。
- 格子6（右中）：编号⑥ Purple 紫色 — 宝宝穿着紫色上衣，双手捧着一串紫色葡萄，周围可点缀紫色小花。主题色必须是葡萄紫/正紫色。

第3行：
- 格子7（左下）：编号⑦ Pink 粉色 — 宝宝穿着粉色上衣，手里握着一朵粉色小花或抱着粉色小猪玩偶，周围可点缀粉色糖果。主题色必须是柔和粉色。
- 格子8（中下）：编号⑧ Brown 棕色 — 宝宝穿着棕色上衣，怀里抱着一只棕色泰迪熊，周围可点缀棕色树干或巧克力。主题色必须是温暖棕色。
- 格子9（右下）：编号⑨ Gray 灰色 — 宝宝穿着灰色上衣，手里抱着一只灰色小象玩偶，周围可点缀灰色石头或灰色云朵。主题色必须是中性灰色，不能是彩虹、白色或多色总结。

【颜色准确性要求】（非常重要）：
- 每个格子的主体颜色必须纯正、饱和、准确，不能偏离标准色值
- 红色格子只能有红色元素（红苹果、红花、红衣），禁止混入橙色或粉色
- 橙色格子只能有橙色元素（胡萝卜、橙子、橙衣），禁止偏红或变成红色
- 灰色格子只能是灰色元素（灰象、灰石、灰云、灰衣），禁止出现彩虹、太阳、彩色气球
- 宝宝衣服颜色必须与格子主题色一致
- 背景道具颜色必须与主题色一致，不能混用其他颜色

【人物要求】（所有格子共用同一个宝宝）：
- 真实摄影风格，柔和自然光，商业儿童摄影质感
- 人物肤色：白皙偏粉，带有婴儿健康红润感（即使参考图偏黄也要调整为白皙粉嫩）
- 光线：柔和自然光，明亮干净，专业摄影棚效果
- 整体色调：明亮、干净、温暖
- 高清8k，真实皮肤纹理，能看到毛孔和发丝细节
- 这必须是同一个宝宝，不能每个格子变成不同的人
- 表情自然、可爱、天真的微笑表情
- 每个格子中宝宝人物尽量完整展示（至少展示上半身），面向镜头或自然侧向颜色物品
- 宝宝与颜色物品的互动必须自然、可爱，手部姿势清晰可见

【必须保留的模板内容】（绝对不变）：
- 所有编号（①②③④⑤⑥⑦⑧⑨）的位置、颜色、样式必须完全保留
- 所有英文标题（Red, Orange, Yellow, Green, Blue, Purple, Pink, Brown, Gray）必须完全保留
- 所有中文标题（红色、橙色、黄色、绿色、蓝色、紫色、粉色、棕色、灰色）必须完全保留
- 所有颜料图标（红色、橙色、黄色、绿色、蓝色、紫色、粉色、棕色、灰色颜料 splash）必须完全保留
- 所有英文说明文字（This is red. I see red everywhere! / This is orange. I like orange carrots. 等）必须完全保留，不得修改拼写
- 所有中文说明文字（这是红色。我到处都能看到红色！/ 这是橙色。我喜欢橙色的胡萝卜。等）必须完全保留
- 模板背景颜色（米色/奶油色）必须完全保留
- 格子之间的分隔线必须完全保留

【背景要求】（非常重要）：
- 人物背景必须是透明（alpha通道），不是白色或任何颜色
- 人物边缘必须自然融入模板背景，不能有任何白色边框、灰色边框或光晕
- 人物必须与模板背景颜色完全一致，看起来像原本就是模板的一部分
- 人物边缘不能有锯齿、模糊、光晕等痕迹
- 人物光影必须与模板整体光影一致

【禁止】：
- 禁止输出红色背景（红色只是占位区颜色，不是最终背景）
- 禁止人物背景为白色、灰色或任何颜色（必须是透明）
- 禁止人物边缘有白色边框、灰色边框、光晕
- 禁止改变任何文字内容、位置、字体、颜色，禁止拼写错误
- 禁止遮挡编号、标题、图标和说明文字
- 禁止添加照片框、白色边框
- 禁止卡通或插画风格
- 禁止每个格子生成不同的宝宝（必须是同一个宝宝）
- 禁止拼贴感、合成感、贴图感
- 禁止格子1做成封面、禁止格子9做成总结页/彩虹页
- 禁止任何格子混入多种主题色，每个格子只能有一种主色
- 禁止灰色格子出现彩虹、彩色元素或"结束"氛围`;
  }

  /**
   * 从 URL 下载图片并转为 Base64
   */
  private async downloadImageToBase64(imageUrl: string): Promise<string> {
    try {
      // 只要是本服务上传的图片（URL 含 /api/upload/image/，无论前缀是 localhost
      // 还是生产域名），一律优先读本地文件，绕开 HTTP 认证（DeviceAuthGuard 会返回 401）
      if (imageUrl.includes('/api/upload/image/')) {
        const filename = imageUrl.split('/').pop()?.split('?')[0] || '';
        if (filename) {
          const localPath = path.join(process.cwd(), 'uploads', 'temp', filename);
          if (fs.existsSync(localPath)) {
            const buffer = await fs.promises.readFile(localPath);
            return buffer.toString('base64');
          }
          this.logger.warn(`本地图片文件不存在，回退远程下载: ${localPath}`);
        }
      }

      // 从远程 URL 下载
      const response = await axios.get(imageUrl, {
        responseType: 'arraybuffer',
        timeout: 30000,
      });
      return Buffer.from(response.data).toString('base64');
    } catch (error) {
      this.logger.error(`下载宝宝照片失败: ${error.message}`);
      throw new Error(`下载宝宝照片失败: ${error.message}`);
    }
  }

  /**
   * 下载生成的图片到本地保存
   */
  private async saveImageToFile(url: string, outputPath: string): Promise<void> {
    const response = await axios.get(url, {
      responseType: 'arraybuffer',
      timeout: 60000,
    });
    await fs.promises.writeFile(outputPath, response.data);
  }

  /**
   * 获取当前时间戳（毫秒）
   */
  private now(): number {
    return Date.now();
  }

  /**
   * 计算从给定时间戳开始的耗时（毫秒）
   */
  private elapsed(start: number): number {
    return Date.now() - start;
  }
}
