# BabyBook 后端 API 文档

## 基础信息

- **基础 URL**: `https://your-railway-app.railway.app`
- **API 前缀**: `/api`
- **Swagger 文档**: `/api/docs`

---

## 接口清单

### 1. 订单接口

#### 1.1 创建订单

- **URL**: `POST /api/order/create`
- **Content-Type**: `application/json`
- **说明**: 用户选择绘本后，创建未支付订单

**请求参数**:

```json
{
  "bookId": "Book001",      // 绘本模板ID（Book001/Book002/Book003）
  "deviceId": "device_abc123", // 设备标识（iOS Keychain 存储）
  "imageUrl": "https://..."  // 可选：宝宝照片URL
}
```

**响应示例**:

```json
{
  "id": "uuid-order-id",
  "deviceId": "device_abc123",
  "bookId": "Book001",
  "bookName": "《这是我》",
  "amount": 12.99,
  "status": "UNPAID",
  "createdAt": "2026-06-23T10:00:00.000Z",
  "updatedAt": "2026-06-23T10:00:00.000Z"
}
```

#### 1.2 查询订单详情

- **URL**: `GET /api/order/:id`
- **说明**: 根据订单ID查询订单详情

**响应示例**:

```json
{
  "id": "uuid-order-id",
  "deviceId": "device_abc123",
  "bookId": "Book001",
  "bookName": "《这是我》",
  "amount": 12.99,
  "status": "SUCCESS",
  "createdAt": "2026-06-23T10:00:00.000Z",
  "updatedAt": "2026-06-23T10:05:00.000Z"
}
```

#### 1.3 查询订单列表

- **URL**: `GET /api/order?deviceId=device_abc123&status=PAID&page=1&limit=10`
- **说明**: 查询订单列表，支持按设备ID和状态筛选

**响应示例**:

```json
{
  "orders": [
    {
      "id": "uuid-order-id",
      "deviceId": "device_abc123",
      "bookId": "Book001",
      "bookName": "《这是我》",
      "amount": 12.99,
      "status": "PAID",
      "createdAt": "2026-06-23T10:00:00.000Z",
      "updatedAt": "2026-06-23T10:00:00.000Z"
    }
  ],
  "total": 1
}
```

#### 1.4 更新订单图片 URL

- **URL**: `PATCH /api/order/:id/image`
- **Content-Type**: `application/json`
- **说明**: 更新订单的宝宝照片 URL（支付前上传图片后使用）

**请求参数**:

```json
{
  "imageUrl": "https://..."  // 宝宝照片临时 URL
}
```

**响应示例**: 同 1.2

---

### 2. 支付接口

#### 2.1 验证 Apple IAP 支付

- **URL**: `POST /api/payment/verify`
- **Content-Type**: `application/json`
- **说明**: 客户端完成 Apple IAP 支付后，提交收据进行验证
- **关键逻辑**: 验证成功后，服务端自动创建 AI 生成任务

**请求参数**:

```json
{
  "orderId": "uuid-order-id",      // 订单ID
  "receiptData": "base64-receipt", // Apple 支付收据（Base64编码）
  "transactionId": "1000000123456789", // Apple 交易ID
  "imageUrl": "https://..."        // 宝宝照片URL（如之前未上传）
}
```

**响应示例（成功）**:

```json
{
  "success": true,
  "orderId": "uuid-order-id",
  "status": "GENERATING"
}
```

**响应示例（失败）**:

```json
{
  "success": false,
  "orderId": "uuid-order-id",
  "status": "UNPAID",
  "errorMessage": "支付验证失败"
}
```

---

### 3. 任务接口

#### 3.1 查询任务状态

- **URL**: `GET /api/task/:id`
- **说明**: 根据任务ID查询生成任务状态

**响应示例**:

```json
{
  "id": "uuid-task-id",
  "orderId": "uuid-order-id",
  "status": "RUNNING",     // PENDING / RUNNING / COMPLETED / FAILED / CANCELLED
  "progress": 65,          // 0-100
  "resultUrl": null,       // 生成完成后返回图片URL
  "errorMessage": null,
  "createdAt": "2026-06-23T10:01:00.000Z",
  "updatedAt": "2026-06-23T10:02:00.000Z"
}
```

#### 3.2 根据订单ID查询任务

- **URL**: `GET /api/task/order/:orderId`
- **说明**: 根据订单ID查询关联的任务状态（iOS 端常用）

**响应示例**: 同 3.1

#### 3.3 取消任务

- **URL**: `POST /api/task/:id/cancel`
- **说明**: 取消正在进行的生成任务

**响应示例**:

```json
{
  "success": true,
  "taskId": "uuid-task-id",
  "status": "CANCELLED"
}
```

---

### 4. 绘本接口

#### 4.1 获取绘本下载信息

- **URL**: `GET /api/book/:orderId/download`
- **说明**: 获取绘本图片下载信息

**响应示例**:

```json
{
  "imageUrl": "https://generated-image-url.png",
  "bookName": "《这是我》",
  "status": "SUCCESS"
}
```

#### 4.2 下载绘本图片

- **URL**: `GET /api/book/:orderId/image`
- **说明**: 直接下载绘本九宫格图片（返回二进制数据）
- **Content-Type**: `image/png`
- **Content-Disposition**: `attachment; filename="book_{orderId}.png"`

---

### 5. 上传接口

#### 5.1 上传宝宝照片

- **URL**: `POST /api/upload/image`
- **Content-Type**: `multipart/form-data`
- **说明**: 上传宝宝照片到临时存储，返回图片 URL
- **限制**: 仅支持 JPG、PNG、GIF、WebP，最大 10MB

**请求参数**:

```
image: 文件 (multipart/form-data)
```

**响应示例**:

```json
{
  "success": true,
  "imageUrl": "https://your-api.com/api/upload/image/baby-1234567890.jpg",
  "filename": "baby-1234567890.jpg",
  "size": 1024000
}
```

#### 5.2 删除临时图片

- **URL**: `DELETE /api/upload/image/:filename`
- **说明**: 删除临时上传的图片（生成完成后调用）

**响应示例**:

```json
{
  "success": true,
  "message": "图片已删除"
}
```

---

## 订单状态流转

```
UNPAID（未支付）
  → 用户完成 Apple IAP 支付
  → POST /api/payment/verify
    → 验证成功
      → PAID（已支付）
      → 自动创建生成任务
        → GENERATING（生成中）
          → AI 生成成功
            → SUCCESS（生成成功）
          → AI 生成失败（自动重试2次）
            → 仍失败 → FAILED（生成失败）
    → 验证失败
      → 保持 UNPAID
```

---

## iOS 端调用流程

### 完整购买流程

```swift
// 1. 创建订单
let order = await createOrder(bookId: "Book001", deviceId: deviceId)

// 2. 调用 Apple IAP 支付
let transaction = await purchase(productId: "book_001")

// 3. 验证支付（同时上传宝宝照片）
let result = await verifyPayment(
    orderId: order.id,
    receiptData: receipt,
    transactionId: transaction.id,
    imageUrl: babyPhotoUrl
)

// 4. 轮询任务状态（支付成功后立即开始）
while true {
    let task = await getTaskByOrderId(orderId: order.id)
    if task.status == "COMPLETED" {
        // 下载绘本图片
        let imageUrl = task.resultUrl
        break
    } else if task.status == "FAILED" {
        // 显示失败提示，建议联系客服
        break
    }
    // 每 3 秒轮询一次
    await Task.sleep(3_000_000_000)
}
```

### 恢复购买流程（App 重启后）

```swift
// 1. 查询该设备的未完成订单
let orders = await getOrders(deviceId: deviceId, status: "PAID")

// 2. 对每个 PAID 订单，检查是否有进行中的任务
for order in orders {
    let task = await getTaskByOrderId(orderId: order.id)
    if task?.status == "RUNNING" || task?.status == "PENDING" {
        // 继续轮询
        continuePolling(taskId: task!.id)
    } else if task == nil {
        // 任务未创建，可能需要重新验证支付
    }
}
```

---

## 错误码说明

| HTTP 状态码 | 说明 |
|------------|------|
| 200 | 请求成功 |
| 201 | 创建成功 |
| 400 | 参数错误或业务逻辑错误 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 数据隐私说明

1. **宝宝照片**：上传后仅用于 AI 生成，生成完成后立即删除
2. **绘本图片**：生成后立即删除，不保存
3. **PDF 文件**：仅保存在用户本地 iOS Documents 目录，不上传云端
4. **保留数据**：仅保存订单记录（order_id, device_id, book_id, payment_id, amount, status, 时间戳）

---

## 技术栈

- **框架**: NestJS 11
- **数据库**: PostgreSQL 16
- **ORM**: TypeORM 0.3.20
- **部署**: Railway + Docker
- **AI**: 豆包 Seedream 5.0 Lite
