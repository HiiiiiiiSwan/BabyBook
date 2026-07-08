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
const TEMPLATE_PATH = path.join(PROJECT_ROOT, 'templates/self_intro/all-none.png');
const BABY_PHOTO_PATH = path.join(PROJECT_ROOT, 'templates/babyimage2.png');
const OUTPUT_PATH = path.join(PROJECT_ROOT, 'uploads/grid-generated-test-baby2.png');

// 确保输出目录存在
const outputDir = path.dirname(OUTPUT_PATH);
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

// 完整 Prompt（2图参考模式：模板图 + 宝宝照片）
const PROMPT = `【任务：将九宫格模板中的红色占位区域替换为同一个宝宝的真实照片】

图1是九宫格模板，每个格子左侧有编号、图标、文字说明，右侧红色区域是占位区。
图2是参考宝宝照片。

核心任务：将图1中每个格子的红色占位区域替换为图2中的同一个宝宝形象，
每个格子展示宝宝不同的身体部位特写。

【九宫格布局说明】（3×3网格，从上到下、从左到右）：

第1行：
- 格子1（左上）：编号① Head 头 — 宝宝头部特写，面向镜头，
  展示完整的头部、耳朵、脖子、肩膀
- 格子2（中上）：编号② Eye 眼睛 — 宝宝眼睛特写，面向镜头，
  展示完整的眼睛、眉毛、部分脸部
- 格子3（右上）：编号③ Ear 耳朵 — 宝宝耳朵特写，侧脸或正面，
  展示完整的耳朵和周围区域

第2行：
- 格子4（左中）：编号④ Nose 鼻子 — 宝宝鼻子特写，面向镜头，
  展示完整的鼻子和周围区域
- 格子5（正中）：编号⑤ Mouth 嘴巴 — 宝宝嘴巴特写，微笑表情，
  展示完整的嘴巴和周围区域
- 格子6（右中）：编号⑥ Neck 脖子 — 宝宝脖子特写，
  展示完整的脖子和周围区域

第3行：
- 格子7（左下）：编号⑦ Hand 手 — 宝宝手部特写，展示完整的手掌、手指，
  宝宝穿着浅色衣物，手臂自然伸展
- 格子8（中下）：编号⑧ Tummy 肚子 — 宝宝肚子特写，展示完整的肚子和肚脐，
  宝宝穿着露肚装或衣服撩起露出肚子，肚子圆润可爱
- 格子9（右下）：编号⑨ Foot 脚 — 宝宝脚部特写，展示完整的脚掌、脚趾，
  脚趾数量必须是5个，排列自然整齐

【人物要求】（所有格子共用同一个宝宝）：
- 真实摄影风格，柔和自然光，商业儿童摄影质感
- 人物肤色：白皙偏粉，带有婴儿健康红润感
  （即使参考图偏黄也要调整为白皙粉嫩）
- 光线：柔和自然光，明亮干净，专业摄影棚效果
- 整体色调：明亮、干净、温暖
- 高清8k，真实皮肤纹理，能看到毛孔和发丝细节
- 这必须是同一个宝宝，不能每个格子变成不同的人
- 表情自然、可爱、天真的微笑表情
- 每个格子中宝宝人物尽量完整展示（至少展示上半身或全身），
  同时强化对应部位特写
- 格子8（肚子）宝宝必须穿着露肚装或衣服撩起，
  完整展示圆润可爱的肚子和肚脐
- 格子9（脚）脚趾数量必须是5个，排列自然整齐，不能多也不能少

【必须保留的模板内容】（绝对不变）：
- 所有编号（①②③④⑤⑥⑦⑧⑨）的位置、颜色、样式必须完全保留
- 所有英文标题（Head, Eye, Ear, Nose, Mouth, Neck, Hand, Tummy, Foot）
  必须完全保留
- 所有中文标题（头、眼睛、耳朵、鼻子、嘴巴、脖子、手、肚子、脚）
  必须完全保留
- 所有图标（头部、眼睛、耳朵、鼻子、嘴巴、脖子、手、肚子、脚的简笔图标）
  必须完全保留
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

async function generateGridBook() {
  console.log('🎨 开始生成《这是我》绘本九宫格...');
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
    size: '1920x1920',  // 在满足豆包最小像素限制（3686400）的前提下降低分辨率，缩短生成耗时
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
  console.log(`   尺寸: 1920×1920`);
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
generateGridBook();
