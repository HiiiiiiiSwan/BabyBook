import { Repository } from 'typeorm';
import { Task } from './entities/task.entity';
import { Order } from '../order/entities/order.entity';
import { TaskResponseDto, UpdateTaskStatusDto } from './dto/task.dto';
import { AiService } from '../ai/ai.service';
export declare class TaskService {
    private taskRepository;
    private orderRepository;
    private aiService;
    private readonly logger;
    private readonly maxRetries;
    constructor(taskRepository: Repository<Task>, orderRepository: Repository<Order>, aiService: AiService);
    createTask(orderId: string): Promise<Task>;
    findById(id: string): Promise<TaskResponseDto>;
    findByOrderId(orderId: string): Promise<TaskResponseDto | null>;
    updateStatus(id: string, dto: UpdateTaskStatusDto): Promise<Task>;
    cancelTask(id: string): Promise<Task>;
    private executeTask;
    retryFailedTasks(): Promise<void>;
    handleTimeoutTasks(): Promise<void>;
    private toResponseDto;
}
