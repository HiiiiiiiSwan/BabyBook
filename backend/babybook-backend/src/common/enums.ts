/**
 * 订单状态枚举
 * 状态流转: UNPAID → PAID → GENERATING → SUCCESS / FAILED
 */
export enum OrderStatus {
  UNPAID = 'UNPAID',       // 未支付
  PAID = 'PAID',           // 已支付
  GENERATING = 'GENERATING', // 生成中
  SUCCESS = 'SUCCESS',     // 生成成功
  FAILED = 'FAILED',       // 生成失败
  REFUND = 'REFUND',       // 已退款
}

/**
 * 绘本模板枚举
 */
export enum BookTemplate {
  SELF_INTRO = 'Book001',      // 《这是我》身体认知
  DREAM_JOB = 'Book002',       // 《我长大想做什么》职业认知
  COLOR_RECOGNITION = 'Book003', // 《认识颜色》颜色认知
}

/**
 * 生成任务状态枚举
 */
export enum TaskStatus {
  PENDING = 'PENDING',     // 等待执行
  RUNNING = 'RUNNING',       // 执行中
  COMPLETED = 'COMPLETED',   // 完成
  FAILED = 'FAILED',         // 失败
  CANCELLED = 'CANCELLED',   // 已取消
}
