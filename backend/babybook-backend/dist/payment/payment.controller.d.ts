import { PaymentService } from './payment.service';
import { VerifyPaymentDto, PaymentResponseDto } from './dto/payment.dto';
export declare class PaymentController {
    private readonly paymentService;
    constructor(paymentService: PaymentService);
    verifyPayment(dto: VerifyPaymentDto): Promise<PaymentResponseDto>;
}
