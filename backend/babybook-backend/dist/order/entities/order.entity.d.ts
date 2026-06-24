import { OrderStatus, BookTemplate } from '../../common/enums';
export declare class Order {
    id: string;
    deviceId: string;
    bookId: BookTemplate;
    bookName: string;
    amount: number;
    status: OrderStatus;
    paymentId: string;
    receiptData: string;
    imageUrl: string;
    resultImageUrl: string;
    retryCount: number;
    errorMessage: string;
    createdAt: Date;
    updatedAt: Date;
    paidAt: Date;
    completedAt: Date;
}
