import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';
import { OrderStatus, BookTemplate } from '../../common/enums';

/**
 * 订单实体
 * 记录用户的绘本定制订单信息
 */
@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string; // 订单唯一标识

  @Column({ type: 'varchar', length: 50 })
  @Index()
  deviceId: string; // 设备标识（匿名用户模式）

  @Column({ type: 'enum', enum: BookTemplate })
  bookId: BookTemplate; // 绘本模板ID

  @Column({ type: 'varchar', length: 100, nullable: true })
  bookName: string; // 绘本名称（冗余存储，方便查询）

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number; // 订单金额（元）

  @Column({ type: 'enum', enum: OrderStatus, default: OrderStatus.UNPAID })
  @Index()
  status: OrderStatus; // 订单状态

  @Column({ type: 'varchar', length: 255, nullable: true, unique: true })
  paymentId: string; // Apple 支付交易ID（全局唯一，防止 transactionId 复用）

  @Column({ type: 'text', nullable: true })
  receiptData: string; // Apple 支付收据（Base64）

  @Column({ type: 'varchar', length: 255, nullable: true })
  imageUrl: string; // 宝宝照片临时URL（生成后立即删除）

  @Column({ type: 'text', nullable: true })
  resultImageUrl: string; // 生成的九宫格图片URL

  @Column({ type: 'int', default: 0 })
  retryCount: number; // 失败重试次数

  @Column({ type: 'text', nullable: true })
  errorMessage: string; // 错误信息（失败时记录）

  @CreateDateColumn()
  createdAt: Date; // 创建时间

  @UpdateDateColumn()
  updatedAt: Date; // 更新时间

  @Column({ type: 'timestamp', nullable: true })
  paidAt: Date; // 支付时间

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date; // 完成时间
}
