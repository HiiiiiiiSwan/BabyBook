import { Repository } from 'typeorm';
import { Order } from './entities/order.entity';
import { CreateOrderDto, OrderResponseDto, QueryOrdersDto } from './dto/order.dto';
import { OrderStatus } from '../common/enums';
export declare class OrderService {
    private orderRepository;
    constructor(orderRepository: Repository<Order>);
    create(createOrderDto: CreateOrderDto): Promise<OrderResponseDto>;
    findById(id: string): Promise<OrderResponseDto>;
    findAll(query: QueryOrdersDto): Promise<{
        orders: OrderResponseDto[];
        total: number;
    }>;
    updateStatus(id: string, status: OrderStatus, updates?: Partial<Order>): Promise<Order>;
    findOneEntity(id: string): Promise<Order>;
    private toResponseDto;
}
