# BabyBook（宝贝绘本）
## Design System v1.0

> 产品定位：
>
> 面向 1~3 岁儿童家庭的 AI 个性化绘本定制 App。
>
> 用户上传 1 张宝宝照片，即可在 1 分钟内生成专属绘本。

---

# 1. Design Philosophy

## 品牌关键词

- 温暖（Warm）
- 治愈（Healing）
- 童趣（Playful）
- 收藏感（Keepsake）
- 绘本感（Storybook）
- 高品质（Premium）
- 陪伴感（Companion）

---

## 视觉定位

儿童绘本 × 轻3D插画 × 母婴品牌

核心页面的设计和视觉参考设计稿地址： /Users/wang/Documents/Vibe coding/【新】宝贝绘本/design/design.png

目标感受：

- 像收到一本宝宝成长纪念册
- 像一本值得收藏的绘本
- 像宝宝专属成长礼物

而不是：

- AI工具
- 教育培训产品
- 儿童游戏
- 科技产品

---

# 2. Visual Style

## Style Name

Warm Storybook 3D

暖色系绘本收藏风

---

## 风格特征

### 整体气质

- 温暖
- 柔和
- 干净
- 留白充足
- 高级感

### 视觉元素

- 云朵
- 草地
- 热气球
- 小熊
- 小兔子
- 星星
- 书本
- 树叶

### 插画风格

- 3D儿童绘本风
- Q版比例
- 圆润造型
- 柔和光影
- 低复杂度细节

禁止：

- 写实风
- 科技风
- 二次元风
- 扁平互联网插画

---

# 3. Color System

## Brand Colors

### Primary

Baby Orange

```css
#F28C28
```

用途：

- CTA按钮
- 价格标签
- 进度条
- 高亮信息

---

### Secondary

Warm Cream

```css
#F6D7A7
```

用途：

- 插画辅助色
- 卡片背景
- 装饰元素

---

### Success

```css
#8BC34A
```

用途：

- 支付成功
- 完成状态
- 成功提示

---

## Background

### App Background

```css
#FFF9F2
```

---

### Page Background

```css
#FFFDF9
```

---

## Text Colors

### Primary Text

```css
#222222
```

---

### Secondary Text

```css
#666666
```

---

### Tertiary Text

```css
#999999
```

---

## Border

```css
#F0E8DE
```

---

## Divider

```css
#F5F0E8
```

---

# 4. Typography

## Font Family

### Chinese

```text
PingFang SC
```

### English

```text
SF Pro Display
```

Fallback：

```text
SF Pro Display
PingFang SC
sans-serif
```

---

## Font Scale

### H1

页面主标题

```css
font-size: 32px;
font-weight: 700;
line-height: 40px;
```

---

### H2

模块标题

```css
font-size: 24px;
font-weight: 700;
line-height: 32px;
```

---

### H3

卡片标题

```css
font-size: 18px;
font-weight: 600;
line-height: 26px;
```

---

### Body

正文

```css
font-size: 16px;
font-weight: 500;
line-height: 24px;
```

---

### Caption

辅助说明

```css
font-size: 12px;
font-weight: 400;
line-height: 18px;
```

---

# 5. Radius System

## Card Radius

```css
24px
```

---

## Book Cover Radius

```css
28px
```

---

## Button Radius

```css
999px
```

---

## Modal Radius

```css
32px
```

---

# 6. Shadow System

## Default Card Shadow

```css
box-shadow: 0 8px 30px rgba(0,0,0,0.06);
```

---

## Hover Card Shadow

```css
box-shadow: 0 12px 40px rgba(0,0,0,0.08);
```

---

设计原则：

像云朵漂浮感

不要出现重阴影

---

# 7. Spacing System

统一采用 8pt Grid

## Scale

```text
4
8
12
16
24
32
48
64
```

---

## Page Padding

```css
24px
```

---

## Module Gap

```css
24px
```

---

## Card Internal Padding

```css
16px
```

---

# 8. Button System

## Primary Button

高度：

```css
56px
```

背景：

```css
#F28C28
```

文字：

```css
#FFFFFF
font-size:16px;
font-weight:600;
```

圆角：

```css
999px
```

---

## Secondary Button

背景：

```css
#FFFFFF
```

边框：

```css
1px solid #F28C28
```

文字：

```css
#F28C28
```

---

## Disabled Button

背景：

```css
#E5E5E5
```

文字：

```css
#999999
```

---

# 9. Card System

## Book Card

比例：

```text
3:4
```

样式：

```css
background:#FFFFFF;
border-radius:28px;
box-shadow:0 8px 30px rgba(0,0,0,0.06);
```

内容结构：

- 封面图
- 绘本标题
- 页数
- 标签
- 价格

---

## Feature Card

样式：

```css
background:#FFFFFF;
border-radius:24px;
```

内容：

- 图标
- 标题
- 描述

---

# 10. Illustration Guidelines

## 首页

插画占比：

```text
30%
```

元素：

- 热气球
- 云朵
- 小熊
- 草地

---

## 上传页

插画占比：

```text
20%
```

元素：

- 相框
- 星星
- 小动物

---

## 生成页

插画占比：

```text
50%
```

元素：

- 小熊看书
- 小兔阅读
- 云朵
- 星星

---

## 成功页

插画占比：

```text
40%
```

元素：

- 小熊
- 奖章
- 星星

---

# 11. Motion System

## 页面切换

```css
duration:300ms;
curve:ease-out;
```

---

## Button Click

```css
scale:0.96;
duration:150ms;
```

---

## Progress Animation

圆环持续旋转

数字缓动增长

---

## Success Animation

- 勾选弹出
- 小熊轻微跳动
- 星星散开

```css
duration:600ms;
```

---

# 12. Layout Rules

## Safe Area

遵循 iOS Safe Area

---

## 页面结构

统一：

1. Navigation Bar
2. Hero Section
3. Content Section
4. CTA Section

---

## 页面留白原则

大留白

避免信息拥挤

每个页面只保留一个核心操作

---

# 13. Vibe Coding Rules

Claude Code / Cursor / Lovable / Bolt 必须遵守：

1. 所有页面背景使用 #FFF9F2
2. 所有主按钮使用 #F28C28
3. 大量留白
4. 优先圆角卡片
5. 优先插画而非图标
6. 不使用科技蓝
7. 不使用渐变紫
8. 不使用深色模式
9. 不使用复杂导航
10. 不出现 AI 工具感设计

---

# 14. Design Success Criteria

如果最终效果看起来：

❌ 像 AI 工具

❌ 像教育 App

❌ 像儿童游戏

❌ 像互联网运营产品

✅ 像一本值得收藏十年的宝宝成长纪念绘本

则设计达标。

---

# 15. SwiftUI Implementation Notes

推荐：

```swift
NavigationStack
ScrollView
LazyVGrid
AsyncImage
PhotosPicker
PDFKit
StoreKit2
```

统一设计Token：

```swift
PrimaryColor = Color(hex:"#F28C28")

BackgroundColor = Color(hex:"#FFF9F2")

CardRadius = 24

ButtonHeight = 56

PagePadding = 24
```

所有页面直接引用 Design Token。

禁止硬编码颜色和间距。