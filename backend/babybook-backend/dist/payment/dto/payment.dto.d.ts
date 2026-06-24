export declare class VerifyPaymentDto {
    orderId: string;
    receiptData: string;
    transactionId: string;
    imageUrl?: string;
}
export declare class PaymentResponseDto {
    success: boolean;
    orderId: string;
    status: string;
    errorMessage?: string;
}
