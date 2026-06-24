import { TaskStatus } from '../../common/enums';
export declare class TaskResponseDto {
    id: string;
    orderId: string;
    status: TaskStatus;
    progress: number;
    resultUrl?: string;
    errorMessage?: string;
    createdAt: Date;
    updatedAt: Date;
}
export declare class CreateTaskDto {
    orderId: string;
}
export declare class UpdateTaskStatusDto {
    status: TaskStatus;
    progress?: number;
    resultUrl?: string;
    errorMessage?: string;
}
