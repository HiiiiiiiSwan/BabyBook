import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * 初始化 orders 与 tasks 表
 * 与 Order / Task 实体定义保持一致
 */
export class InitOrderAndTask1720000000000 implements MigrationInterface {
  name = 'InitOrderAndTask1720000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 创建订单状态枚举
    await queryRunner.query(`
      CREATE TYPE "order_status_enum" AS ENUM ('UNPAID', 'PAID', 'GENERATING', 'SUCCESS', 'FAILED', 'REFUND')
    `);

    // 创建绘本模板枚举
    await queryRunner.query(`
      CREATE TYPE "book_template_enum" AS ENUM ('Book001', 'Book002', 'Book003')
    `);

    // 创建任务状态枚举
    await queryRunner.query(`
      CREATE TYPE "task_status_enum" AS ENUM ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED')
    `);

    // 创建 orders 表
    await queryRunner.query(`
      CREATE TABLE "orders" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "deviceId" character varying(50) NOT NULL,
        "bookId" "book_template_enum" NOT NULL,
        "bookName" character varying(100),
        "amount" numeric(10,2) NOT NULL,
        "status" "order_status_enum" NOT NULL DEFAULT 'UNPAID',
        "paymentId" character varying(255) UNIQUE,
        "receiptData" text,
        "imageUrl" character varying(255),
        "resultImageUrl" text,
        "retryCount" integer NOT NULL DEFAULT 0,
        "errorMessage" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        "paidAt" TIMESTAMP,
        "completedAt" TIMESTAMP,
        CONSTRAINT "PK_orders_id" PRIMARY KEY ("id")
      )
    `);

    // orders 常用查询索引
    await queryRunner.query(`CREATE INDEX "IDX_orders_deviceId" ON "orders" ("deviceId")`);
    await queryRunner.query(`CREATE INDEX "IDX_orders_status" ON "orders" ("status")`);

    // 创建 tasks 表
    await queryRunner.query(`
      CREATE TABLE "tasks" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "orderId" uuid NOT NULL,
        "status" "task_status_enum" NOT NULL DEFAULT 'PENDING',
        "progress" integer NOT NULL DEFAULT 0,
        "resultUrl" text,
        "errorMessage" text,
        "retryCount" integer NOT NULL DEFAULT 0,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        "startedAt" TIMESTAMP,
        "completedAt" TIMESTAMP,
        CONSTRAINT "PK_tasks_id" PRIMARY KEY ("id"),
        CONSTRAINT "FK_tasks_orderId" FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE
      )
    `);

    await queryRunner.query(`CREATE INDEX "IDX_tasks_orderId" ON "tasks" ("orderId")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE "tasks"`);
    await queryRunner.query(`DROP TABLE "orders"`);
    await queryRunner.query(`DROP TYPE "task_status_enum"`);
    await queryRunner.query(`DROP TYPE "book_template_enum"`);
    await queryRunner.query(`DROP TYPE "order_status_enum"`);
  }
}
