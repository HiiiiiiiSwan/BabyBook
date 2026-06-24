import { TaskStatus } from '../../common/enums';
import { Order } from '../../order/entities/order.entity';
export declare class Task {
    id: string;
    orderId: string;
    order: Order;
    status: TaskStatus;
    progress: number;
    resultUrl: string;
    errorMessage: string | undefined;
    retryCount: number;
    createdAt: Date;
    updatedAt: Date;
    startedAt: Date;
    completedAt: Date;
}
