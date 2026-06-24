import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Order } from './entities/order.entity';
import { CreateOrderDto, OrderResponseDto, QueryOrdersDto } from './dto/order.dto';
import { OrderStatus, BookTemplate } from '../common/enums';

/**
 * 绘本模板配置
 */
const BOOK_TEMPLATES: Record<BookTemplate, { name: string; price: number }> = {
  [BookTemplate.SELF_INTRO]: { name: '《这是我》', price: 12.99 },
  [BookTemplate.DREAM_JOB]: { name: '《我长大想做什么》', price: 12.99 },
  [BookTemplate.COLOR_RECOGNITION]: { name: '《认识颜色》', price: 12.99 },
};

@Injectable()
export class OrderService {
  constructor(
    @InjectRepository(Order)
    private orderRepository: Repository<Order>,
  ) {}

  /**
   * 创建订单
   */
  async create(createOrderDto: CreateOrderDto): Promise<OrderResponseDto> {
    const { bookId, deviceId, imageUrl } = createOrderDto;

    const template = BOOK_TEMPLATES[bookId];
    if (!template) {
      throw new BadRequestException('无效的绘本模板ID');
    }

    const order = this.orderRepository.create({
      deviceId,
      bookId,
      bookName: template.name,
      amount: template.price,
      status: OrderStatus.UNPAID,
      imageUrl: imageUrl || undefined,
    } as any);

    const savedOrder = await this.orderRepository.save(order as any);

    return this.toResponseDto(savedOrder);
  }

  /**
   * 根据ID查询订单
   */
  async findById(id: string): Promise<OrderResponseDto> {
    const order = await this.orderRepository.findOne({ where: { id } });
    if (!order) {
      throw new NotFoundException('订单不存在');
    }
    return this.toResponseDto(order);
  }

  /**
   * 查询订单列表（支持按设备ID和状态筛选）
   */
  async findAll(query: QueryOrdersDto): Promise<{ orders: OrderResponseDto[]; total: number }> {
    const { deviceId, status, page = 1, limit = 10 } = query;

    const where: any = {};
    if (deviceId) {
      where.deviceId = deviceId;
    }
    if (status) {
      where.status = status;
    }

    const [orders, total] = await this.orderRepository.findAndCount({
      where,
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return {
      orders: orders.map(order => this.toResponseDto(order)),
      total,
    };
  }

  /**
   * 更新订单状态
   */
  async updateStatus(id: string, status: OrderStatus, updates?: Partial<Order>): Promise<Order> {
    const order = await this.orderRepository.findOne({ where: { id } });
    if (!order) {
      throw new NotFoundException('订单不存在');
    }

    order.status = status;
    if (updates) {
      Object.assign(order, updates);
    }

    return await this.orderRepository.save(order);
  }

  /**
   * 获取订单实体（内部使用）
   */
  async findOneEntity(id: string): Promise<Order> {
    const order = await this.orderRepository.findOne({ where: { id } });
    if (!order) {
      throw new NotFoundException('订单不存在');
    }
    return order;
  }

  /**
   * 转换为响应DTO
   */
  private toResponseDto(order: Order): OrderResponseDto {
    return {
      id: order.id,
      deviceId: order.deviceId,
      bookId: order.bookId,
      bookName: order.bookName,
      amount: Number(order.amount),
      status: order.status,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    };
  }
}
