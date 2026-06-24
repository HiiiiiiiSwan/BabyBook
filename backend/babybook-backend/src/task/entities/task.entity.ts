import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { TaskStatus } from '../../common/enums';
import { Order } from '../../order/entities/order.entity';

/**
 * AI 生成任务实体
 * 记录绘本生成任务的执行状态
 */
@Entity('tasks')
export class Task {
  @PrimaryGeneratedColumn('uuid')
  id: string; // 任务唯一标识

  @Column({ type: 'uuid' })
  orderId: string; // 关联的订单ID

  @ManyToOne(() => Order, order => order.id, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'orderId' })
  order: Order;

  @Column({ type: 'enum', enum: TaskStatus, default: TaskStatus.PENDING })
  status: TaskStatus; // 任务状态

  @Column({ type: 'int', default: 0 })
  progress: number; // 生成进度（0-100）

  @Column({ type: 'varchar', length: 255, nullable: true })
  resultUrl: string; // 生成结果图片URL

  @Column({ type: 'text', nullable: true })
  errorMessage: string | undefined; // 错误信息

  @Column({ type: 'int', default: 0 })
  retryCount: number; // 重试次数

  @CreateDateColumn()
  createdAt: Date; // 创建时间

  @UpdateDateColumn()
  updatedAt: Date; // 更新时间

  @Column({ type: 'timestamp', nullable: true })
  startedAt: Date; // 开始执行时间

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date; // 完成时间
}
