import axios from 'axios';
import * as fs from 'fs';
import * as path from 'path';

// 从环境变量读取配置
const DOUBAO_API_URL = process.env.DOUBAO_API_URL || 'https://ark.cn-beijing.volces.com/api/v3/images/generations';
const DOUBAO_MODEL = process.env.DOUBAO_MODEL || 'doubao-seedream-5-0-260128';
const API_KEY = process.env.DOUBAO_API_KEY;

if (!API_KEY) {
  console.error('错误：未设置 DOUBAO_API_KEY 环境变量');
  process.exit(1);
}

// 路径配置（相对于项目根目录）
const PROJECT_ROOT = path.resolve(__dirname, '../../..');
const TEMPLATE_PATH = path.join(PROJECT_ROOT, 'templates/color_recognition/all-none.png');
const BABY_PHOTO_PATH = process.env.BABY_PHOTO_PATH || path.join(PROJECT_ROOT, 'templates/babyimage2.png');
const OUTPUT_PATH = path.join(PROJECT_ROOT, 'uploads/grid-generated-color-recognition-test.png');

// 确保输出目录存在
const outputDir = path.dirname(OUTPUT_PATH);
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// 《认识颜色》专用 Prompt（与 ai.service.ts 中 buildColorRecognitionPrompt 保持一致）
const PROMPT = `【任务：将九宫格模板中的红色占位区域替换为同一个宝宝的真实照片，每个格子展示宝宝与一种颜色互动】

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
- 人物肤色：完全匹配图2宝宝的肤色
- 光线：柔和自然光，明亮干净，专业摄影棚效果
- 整体色调：明亮、干净、温暖
- 高清8k，真实皮肤纹理，能看到毛孔和发丝细节
- 这必须是同一个宝宝，不能每个格子变成不同的人
- 表情自然、可爱、天真的微笑表情（参考图2宝宝的表情特点）
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

async function generateColorRecognitionBook() {
  console.log('🎨 开始生成《认识颜色》绘本九宫格...');
  console.log(`📁 模板路径: ${TEMPLATE_PATH}`);
  console.log(`📁 宝宝照片路径: ${BABY_PHOTO_PATH}`);
  console.log(`📁 输出路径: ${OUTPUT_PATH}`);

  // 1. 检查文件是否存在
  if (!fs.existsSync(TEMPLATE_PATH)) {
    console.error(`❌ 模板文件不存在: ${TEMPLATE_PATH}`);
    process.exit(1);
  }
  if (!fs.existsSync(BABY_PHOTO_PATH)) {
    console.error(`❌ 宝宝照片不存在: ${BABY_PHOTO_PATH}`);
    process.exit(1);
  }

  // 2. 读取图片转 Base64
  console.log('📖 读取模板图片...');
  const templateBase64 = fs.readFileSync(TEMPLATE_PATH).toString('base64');
  console.log('👶 读取宝宝照片...');
  const babyBase64 = fs.readFileSync(BABY_PHOTO_PATH).toString('base64');

  // 3. 构建请求体（2图参考模式）
  const requestBody = {
    model: DOUBAO_MODEL,
    prompt: PROMPT,
    size: '1K',  // 1024x1024，MVP 阶段优先保证生成成功率
    watermark: true,
    sequential_image_generation: 'disabled',
    response_format: 'url',
    stream: false,
    image: [
      `data:image/png;base64,${templateBase64}`,  // 图1：模板图
      `data:image/png;base64,${babyBase64}`     // 图2：宝宝照片
    ]
  };

  console.log('🚀 调用豆包 Seedream 5.0 API...');
  console.log(`   模型: ${DOUBAO_MODEL}`);
  console.log(`   模式: 2图参考（模板 + 宝宝照片）`);
  console.log(`   尺寸: 1K (1024×1024)`);
  console.log(`   超时: 300秒`);

  // 4. 调用 API
  const startTime = Date.now();
  try {
    const response = await axios.post(
      DOUBAO_API_URL,
      requestBody,
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${API_KEY}`,
        },
        timeout: 300000, // 300秒超时
      }
    );

    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    console.log(`✅ API 调用成功！耗时 ${duration} 秒`);

    // 5. 解析响应
    const imageUrl = response.data?.data?.[0]?.url;
    if (!imageUrl) {
      console.error('❌ 响应中未找到图片 URL');
      console.error('响应内容:', JSON.stringify(response.data, null, 2));
      process.exit(1);
    }

    console.log(`🖼️  图片 URL: ${imageUrl.substring(0, 80)}...`);

    // 6. 下载图片
    console.log('⬇️  下载生成结果...');
    const imageResponse = await axios.get(imageUrl, {
      responseType: 'arraybuffer',
      timeout: 60000,
    });

    // 7. 保存到本地
    fs.writeFileSync(OUTPUT_PATH, imageResponse.data);
    const fileSize = (fs.statSync(OUTPUT_PATH).size / 1024 / 1024).toFixed(2);
    console.log(`💾 保存成功: ${OUTPUT_PATH}`);
    console.log(`📊 文件大小: ${fileSize} MB`);
    console.log('🎉 生成完成！');

  } catch (error: any) {
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    console.error(`❌ 生成失败！耗时 ${duration} 秒`);

    if (error.response) {
      console.error('API 错误响应:', error.response.status);
      console.error('错误详情:', JSON.stringify(error.response.data, null, 2));
    } else if (error.request) {
      console.error('请求未收到响应（可能超时）');
    } else {
      console.error('请求错误:', error.message);
    }
    process.exit(1);
  }
}

// 执行生成
generateColorRecognitionBook();
