# 九宫格绘本 AI 生成方案（以《这是我》绘本为例，可复用其他绘本）

## 一、生成流程架构

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   空白模板图     │     │   用户宝宝照片   │     │   豆包 Seedream │
│  (all-none.png)  │ +   │  (baby-photo)   │ ──▶ │   5.0 多图参考  │
│  3×3 九宫格布局  │     │  真实宝宝照片    │     │   一次生成9页   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │  grid-generated  │
                                               │     .png        │
                                               │  完整九宫格绘本  │
                                               └─────────────────┘
```

**核心优势：一次 API 调用生成 9 页内容，节省 9 倍费用**

---

## 二、文件清单

| 文件 | 路径 | 用途 |
|------|------|------|
| 空白模板 | `templates/self_intro/all-none.png` | 九宫格布局占位图 |
| 参考效果图 | `templates/self_intro/all.png` | 生成效果参考 |
| 宝宝照片 | `templates/babyimage.png` | 人物特征参考（后续替换为用户上传照片） |
| 生成脚本 | `backend/scripts/generate-grid-book.ts` | 完整可运行脚本 |
| 输出目录 | `uploads/grid-generated.png` | 生成结果保存位置 |

---

## 三、API 接入配置

### 3.1 环境变量
```bash
# 豆包 Seedream 5.0
DOUBAO_API_KEY=ark-xxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 3.2 API 端点
```
URL: https://ark.cn-beijing.volces.com/api/v3/images/generations
模型: doubao-seedream-5-0-260128
尺寸: 2048×2048px（1:1 方形输出）
超时: 300 秒（九宫格生成较慢）
```

### 3.3 请求格式
```typescript
const requestBody = {
  model: 'doubao-seedream-5-0-260128',
  prompt: prompt,           // 详细生成指令
  size: '2K',               // 输出尺寸
  watermark: true,          // 水印（豆包要求）
  sequential_image_generation: 'disabled',
  response_format: 'url',
  stream: false,
  image: [                  // 多图参考（关键！）
    'data:image/png;base64,templateBase64',  // 模板图
    'data:image/png;base64,babyBase64'        // 宝宝照片
  ]
};
```

---

## 四、核心 Prompt 模板

### 4.1 完整 Prompt 结构

```
【任务：将九宫格模板中的红色占位区域替换为同一个宝宝的真实照片】

图1是九宫格模板，每个格子左侧有编号、图标、文字说明，右侧红色区域是占位区。
图2是参考宝宝照片。

核心任务：将图1中每个格子的红色区域替换为图2中的同一个宝宝形象，
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
- 禁止格子9（脚）中脚趾数量不是5个，必须严格5个脚趾
```

---

## 五、关键技巧总结

### 5.1 多图参考模式（核心）
```typescript
// 同时传入两张图，豆包会自动理解关系
requestBody.image = [
  templateBase64,  // 图1：模板（告诉AI布局结构）
  babyBase64       // 图2：人物（告诉AI宝宝长相）
];
```

### 5.2 肤色强制调整技巧
即使参考照片偏黄，也要在 Prompt 中明确要求：
```
人物肤色：白皙偏粉，带有婴儿健康红润感
（即使参考图偏黄也要调整为白皙粉嫩）
```

### 5.3 身体部位精确控制
每个格子独立描述姿势和展示内容：
```
- 格子8（肚子）：宝宝穿着露肚装或衣服撩起露出肚子
- 格子9（脚）：脚趾数量必须是5个，排列自然整齐
```

### 5.4 模板元素保护
明确列出所有必须保留的元素，防止AI覆盖：
```
- 编号、标题、图标、说明文字、虚线箭头
- 背景颜色、分隔线
```

---

## 六、可复用脚本（完整代码）

```typescript
import axios from 'axios';
import * as fs from 'fs';

const DOUBAO_API_URL = 'https://ark.cn-beijing.volces.com/api/v3/images/generations';
const DOUBAO_MODEL = 'doubao-seedream-5-0-260128';

async function generateGridBook(
  templatePath: string,    // 空白九宫格模板
  babyPhotoPath: string,  // 宝宝照片
  outputPath: string,     // 输出路径
  apiKey: string          // 豆包 API Key
) {
  // 1. 读取图片转 Base64
  const templateBase64 = await fs.promises.readFile(templatePath)
    .then(b => b.toString('base64'));
  const babyBase64 = await fs.promises.readFile(babyPhotoPath)
    .then(b => b.toString('base64'));

  // 2. 构建 Prompt（使用上面的完整模板）
  const prompt = `【任务：将九宫格模板中的红色占位区域...`;

  // 3. 调用 API
  const response = await axios.post(
    DOUBAO_API_URL,
    {
      model: DOUBAO_MODEL,
      prompt,
      size: '2K',
      watermark: true,
      sequential_image_generation: 'disabled',
      response_format: 'url',
      stream: false,
      image: [
        `data:image/png;base64,${templateBase64}`,
        `data:image/png;base64,${babyBase64}`
      ]
    },
    {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      timeout: 300000,
    }
  );

  // 4. 下载保存结果
  const imageUrl = response.data.data[0].url;
  const imageData = await axios.get(imageUrl, {
    responseType: 'arraybuffer',
    timeout: 60000
  });
  await fs.promises.writeFile(outputPath, imageData.data);

  return outputPath;
}
```

