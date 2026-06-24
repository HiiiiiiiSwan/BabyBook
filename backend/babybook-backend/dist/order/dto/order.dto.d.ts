import { BookTemplate } from '../../common/enums';
export declare class CreateOrderDto {
    bookId: BookTemplate;
    deviceId: string;
    imageUrl?: string;
}
export declare class OrderResponseDto {
    id: string;
    deviceId: string;
    bookId: string;
    bookName: string;
    amount: number;
    status: string;
    createdAt: Date;
    updatedAt: Date;
}
export declare class UpdateOrderImageDto {
    imageUrl: string;
}
export declare class QueryOrdersDto {
    deviceId?: string;
    status?: string;
    page?: number;
    limit?: number;
}
