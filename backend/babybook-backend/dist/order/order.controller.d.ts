import { OrderService } from './order.service';
import { CreateOrderDto, OrderResponseDto, QueryOrdersDto, UpdateOrderImageDto } from './dto/order.dto';
export declare class OrderController {
    private readonly orderService;
    constructor(orderService: OrderService);
    create(createOrderDto: CreateOrderDto): Promise<OrderResponseDto>;
    findById(id: string): Promise<OrderResponseDto>;
    findAll(query: QueryOrdersDto): Promise<{
        orders: OrderResponseDto[];
        total: number;
    }>;
    updateImage(id: string, updateImageDto: UpdateOrderImageDto): Promise<OrderResponseDto>;
}
