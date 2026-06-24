import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';
import { Order } from '../order/entities/order.entity';
import { VerifyPaymentDto, PaymentResponseDto } from './dto/payment.dto';
import { TaskService } from '../task/task.service';
export declare class PaymentService {
    private configService;
    private orderRepository;
    private taskService;
    private readonly logger;
    private readonly appleVerifyUrl;
    private readonly appleSandboxUrl;
    constructor(configService: ConfigService, orderRepository: Repository<Order>, taskService: TaskService);
    verifyPayment(dto: VerifyPaymentDto): Promise<PaymentResponseDto>;
    private verifyAppleReceipt;
    private requestAppleVerify;
}
