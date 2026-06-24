import { Repository } from 'typeorm';
import { Order } from '../order/entities/order.entity';
export declare class BookService {
    private orderRepository;
    private readonly logger;
    constructor(orderRepository: Repository<Order>);
    getBookDownloadInfo(orderId: string): Promise<{
        imageUrl: string;
        bookName: string;
        status: string;
    }>;
    getBookImage(orderId: string): Promise<Buffer>;
}
