"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TaskStatus = exports.BookTemplate = exports.OrderStatus = void 0;
var OrderStatus;
(function (OrderStatus) {
    OrderStatus["UNPAID"] = "UNPAID";
    OrderStatus["PAID"] = "PAID";
    OrderStatus["GENERATING"] = "GENERATING";
    OrderStatus["SUCCESS"] = "SUCCESS";
    OrderStatus["FAILED"] = "FAILED";
    OrderStatus["REFUND"] = "REFUND";
})(OrderStatus || (exports.OrderStatus = OrderStatus = {}));
var BookTemplate;
(function (BookTemplate) {
    BookTemplate["SELF_INTRO"] = "Book001";
    BookTemplate["DREAM_JOB"] = "Book002";
    BookTemplate["COLOR_RECOGNITION"] = "Book003";
})(BookTemplate || (exports.BookTemplate = BookTemplate = {}));
var TaskStatus;
(function (TaskStatus) {
    TaskStatus["PENDING"] = "PENDING";
    TaskStatus["RUNNING"] = "RUNNING";
    TaskStatus["COMPLETED"] = "COMPLETED";
    TaskStatus["FAILED"] = "FAILED";
    TaskStatus["CANCELLED"] = "CANCELLED";
})(TaskStatus || (exports.TaskStatus = TaskStatus = {}));
//# sourceMappingURL=enums.js.map