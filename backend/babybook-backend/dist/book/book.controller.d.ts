import type { Response } from 'express';
import { BookService } from './book.service';
export declare class BookController {
    private readonly bookService;
    constructor(bookService: BookService);
    getDownloadInfo(orderId: string): Promise<{
        imageUrl: string;
        bookName: string;
        status: string;
    }>;
    downloadImage(orderId: string, res: Response): Promise<void>;
}
