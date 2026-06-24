import { TaskService } from './task.service';
import { TaskResponseDto } from './dto/task.dto';
export declare class TaskController {
    private readonly taskService;
    constructor(taskService: TaskService);
    findById(id: string): Promise<TaskResponseDto>;
    findByOrderId(orderId: string): Promise<TaskResponseDto | null>;
    cancelTask(id: string): Promise<any>;
}
