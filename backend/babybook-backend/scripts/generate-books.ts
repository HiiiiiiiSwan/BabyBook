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
const BABY_PHOTO_PATH = path.join(PROJECT_ROOT, 'templates/babyimage2.png');

// 绘本配置
const BOOKS = [
  {
    name: '我长大想做什么',
    id: 'dream_job',
    templatePath: path.join(PROJECT_ROOT, 'templates/dream_job/all-none.png'),
    outputPath: path.join(PROJECT_ROOT, 'uploads/grid-generated-dream-job.png'),
    prompt: `【任务：将九宫格模板中的红色占位区域替换为同一个宝宝的真实照片，宝宝扮演不同职业角色】

图1是九宫格模板，每个格子左侧有编号、职业名称、图标、文字说明，右侧红色区域是占位区。
图2是参考宝宝照片，提供宝宝的人物形象特征。

核心任务：将图1中每个格子的红色区域替换为图2中的同一个宝宝形象，
每个格子展示宝宝扮演不同职业角色的场景。

【九宫格布局说明】（3×3网格，从上到下、从左到右）：

第1行：
- 格子1（左上）：编号① Doctor 医生 — 宝宝穿着医生白大褂，戴着听诊器，扮演小医生
- 格子2（中上）：编号② Teacher 老师 — 宝宝戴着眼镜，拿着教鞭或书本，扮演小老师
- 格子3（右上）：编号③ Astronaut 宇航员 — 宝宝穿着宇航服，戴着宇航头盔，扮演小宇航员

第2行：
- 格子4（左中）：编号④ Police Officer 警察 — 宝宝穿着警服，戴着警帽，扮演小警察
- 格子5（正中）：编号⑤ Athlete 运动员 — 宝宝穿着运动服，抱着足球，扮演小运动员
- 格子6（右中）：编号⑥ Scientist 科学家 — 宝宝穿着白大褂，戴着护目镜，拿着试管，扮演小科学家

第3行：
- 格子7（左下）：编号⑦ Chef 厨师 — 宝宝穿着厨师服，戴着厨师帽，拿着锅铲，扮演小厨师
- 格子8（中下）：编号⑧ Writer 作家 — 宝宝戴着贝雷帽，拿着钢笔和笔记本，扮演小作家
- 格子9（右下）：编号⑨ Musician 音乐家 — 宝宝戴着领结，拿着尤克里里或小提琴，扮演小音乐家

【人物要求】（所有格子共用同一个宝宝）：
- 真实摄影风格，柔和自然光，商业儿童摄影质感
- 人物肤色：完全匹配图2宝宝的肤色
- 光线：柔和自然光，明亮干净，专业摄影棚效果
- 整体色调：明亮、干净、温暖
- 高清8k，真实皮肤纹理，能看到毛孔和发丝细节
- 这必须是同一个宝宝，不能每个格子变成不同的人
- 表情自然、可爱、天真的微笑表情（参考图2宝宝的表情特点）
- 每个格子中宝宝人物尽量完整展示（至少展示上半身或全身）
- 职业服装必须真实、精致、有细节，不能粗糙或卡通化
- 宝宝穿着的职业服装必须合身，看起来像真的在扮演该职业

【必须保留的模板内容】（绝对不变）：
- 所有编号（①②③④⑤⑥⑦⑧⑨）的位置、颜色、样式必须完全保留
- 所有英文标题（Doctor, Teacher, Astronaut, Police Officer, Athlete, Scientist, Chef, Writer, Musician）必须完全保留
- 所有中文标题（医生、老师、宇航员、警察、运动员、科学家、厨师、作家、音乐家）必须完全保留
- 所有图标（听诊器、ABC、火箭、警徽、足球、试管、厨师帽、书本、音符）必须完全保留
- 所有英文说明文字（I help people...）必须完全保留
- 所有中文说明文字（我帮助病人...）必须完全保留
- 所有虚线箭头从编号指向宝宝对应的职业道具必须完全保留
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
- 禁止职业服装粗糙、不合身或卡通化`
  },
  {
    name: '认识颜色',
    id: 'color_recognition',
    templatePath: path.join(PROJECT_ROOT, 'templates/color_recognition/all-none.png'),
    outputPath: path.join(PROJECT_ROOT, 'uploads/grid-generated-color-recognition.png'),
    prompt: `【任务：将九宫格模板中的红色占位区域替换为同一个宝宝的真实照片，每个格子展示宝宝与不同颜色物品互动】

图1是九宫格模板，每个格子左侧有编号、颜色名称、图标、文字说明，右侧红色区域是占位区。
图2是参考宝宝照片，提供宝宝的人物形象特征。

核心任务：将图1中每个格子的红色区域替换为图2中的同一个宝宝形象，
每个格子展示宝宝穿着对应颜色的衣服，或与对应颜色的物品互动。

【九宫格布局说明】（3×3网格，从上到下、从左到右）：

第1行：
- 格子1（左上）：编号① Red 红色 — 宝宝穿着红色衣服，或拿着红色物品（如红苹果、红花）
- 格子2（中上）：编号② Orange 橙色 — 宝宝穿着橙色衣服，或拿着橙色物品（如橙子、胡萝卜）
- 格子3（右上）：编号③ Yellow 黄色 — 宝宝穿着黄色衣服，或拿着黄色物品（如向日葵、香蕉）

第2行：
- 格子4（左中）：编号④ Green 绿色 — 宝宝穿着绿色衣服，或拿着绿色物品（如绿叶、青苹果）
- 格子5（正中）：编号⑤ Blue 蓝色 — 宝宝穿着蓝色衣服，或拿着蓝色物品（如蓝天、蓝气球）
- 格子6（右中）：编号⑥ Purple 紫色 — 宝宝穿着紫色衣服，或拿着紫色物品（如葡萄、紫花）

第3行：
- 格子7（左下）：编号⑦ Pink 粉色 — 宝宝穿着粉色衣服，或拿着粉色物品（如粉花、粉色玩具）
- 格子8（中下）：编号⑧ Brown 棕色 — 宝宝穿着棕色衣服，或拿着棕色物品（如泰迪熊、巧克力）
- 格子9（右下）：编号⑨ Gray 灰色 — 宝宝穿着灰色衣服，或拿着灰色物品（如灰色大象、灰色石头）

【人物要求】（所有格子共用同一个宝宝）：
- 真实摄影风格，柔和自然光，商业儿童摄影质感
- 人物肤色：完全匹配图2宝宝的肤色
- 光线：柔和自然光，明亮干净，专业摄影棚效果
- 整体色调：明亮、干净、温暖
- 高清8k，真实皮肤纹理，能看到毛孔和发丝细节
- 这必须是同一个宝宝，不能每个格子变成不同的人
- 表情自然、可爱、天真的微笑表情（参考图2宝宝的表情特点）
- 每个格子中宝宝人物尽量完整展示（至少展示上半身或全身）
- 颜色必须鲜艳、纯正、饱和度高，符合该颜色的标准色值
- 宝宝与颜色物品的互动必须自然、可爱

【必须保留的模板内容】（绝对不变）：
- 所有编号（①②③④⑤⑥⑦⑧⑨）的位置、颜色、样式必须完全保留
- 所有英文标题（Red, Orange, Yellow, Green, Blue, Purple, Pink, Brown, Gray）必须完全保留
- 所有中文标题（红色、橙色、黄色、绿色、蓝色、紫色、粉色、棕色、灰色）必须完全保留
- 所有图标（红花、橙花、黄花、绿叶、蓝花、紫花、粉花、棕花、灰花）必须完全保留
- 所有英文说明文字（This is red...）必须完全保留
- 所有中文说明文字（这是红色...）必须完全保留
- 所有虚线箭头从编号指向宝宝或颜色物品必须完全保留
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
- 禁止颜色暗淡、不饱和或偏离标准色值`
  }
];

async function generateBook(book: typeof BOOKS[0]) {
  console.log(`\n🎨 开始生成《${book.name}》绘本九宫格...`);
  console.log(`📁 模板路径: ${book.templatePath}`);
  console.log(`📁 宝宝照片路径: ${BABY_PHOTO_PATH}`);
  console.log(`📁 输出路径: ${book.outputPath}`);

  // 1. 检查文件是否存在
  if (!fs.existsSync(book.templatePath)) {
    console.error(`❌ 模板文件不存在: ${book.templatePath}`);
    return false;
  }
  if (!fs.existsSync(BABY_PHOTO_PATH)) {
    console.error(`❌ 宝宝照片不存在: ${BABY_PHOTO_PATH}`);
    return false;
  }

  // 2. 读取图片转 Base64
  console.log('📖 读取模板图片...');
  const templateBase64 = fs.readFileSync(book.templatePath).toString('base64');
  console.log('👶 读取宝宝照片...');
  const babyBase64 = fs.readFileSync(BABY_PHOTO_PATH).toString('base64');

  // 3. 构建请求体（2图参考模式）
  const requestBody = {
    model: DOUBAO_MODEL,
    prompt: book.prompt,
    size: '2K',  // 2048x2048
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
  console.log(`   尺寸: 2K (2048×2048)`);
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
      return false;
    }

    console.log(`🖼️  图片 URL: ${imageUrl.substring(0, 80)}...`);

    // 6. 下载图片
    console.log('⬇️  下载生成结果...');
    const imageResponse = await axios.get(imageUrl, {
      responseType: 'arraybuffer',
      timeout: 60000,
    });

    // 7. 保存到本地
    fs.writeFileSync(book.outputPath, imageResponse.data);
    const fileSize = (fs.statSync(book.outputPath).size / 1024 / 1024).toFixed(2);
    console.log(`💾 保存成功: ${book.outputPath}`);
    console.log(`📊 文件大小: ${fileSize} MB`);
    console.log('🎉 生成完成！');
    return true;

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
    return false;
  }
}

async function main() {
  console.log('========================================');
  console.log('  开始生成 2 本绘本');
  console.log('  宝宝照片: babyimage2.png');
  console.log('========================================');

  for (const book of BOOKS) {
    const success = await generateBook(book);
    if (!success) {
      console.error(`《${book.name}》生成失败，跳过下一本...`);
    }
    // 每本之间等待 2 秒，避免触发 API 限制
    await new Promise(resolve => setTimeout(resolve, 2000));
  }

  console.log('\n========================================');
  console.log('  所有绘本生成完成！');
  console.log('========================================');
}

// 执行生成
main();
