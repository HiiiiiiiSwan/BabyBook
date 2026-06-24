import { Controller, Post, Get, Body, Param, Query, Patch } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { OrderService } from './order.service';
import { CreateOrderDto, OrderResponseDto, QueryOrdersDto, UpdateOrderImageDto } from './dto/order.dto';

@ApiTags('订单')
@Controller('api/order')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Post('create')
  @ApiOperation({ summary: '创建订单' })
  @ApiResponse({ status: 201, description: '订单创建成功', type: OrderResponseDto })
  @ApiResponse({ status: 400, description: '参数错误' })
  async create(@Body() createOrderDto: CreateOrderDto): Promise<OrderResponseDto> {
    return this.orderService.create(createOrderDto);
  }

  @Get(':id')
  @ApiOperation({ summary: '查询订单详情' })
  @ApiResponse({ status: 200, description: '查询成功', type: OrderResponseDto })
  @ApiResponse({ status: 404, description: '订单不存在' })
  async findById(@Param('id') id: string): Promise<OrderResponseDto> {
    return this.orderService.findById(id);
  }

  @Get()
  @ApiOperation({ summary: '查询订单列表' })
  @ApiResponse({ status: 200, description: '查询成功' })
  async findAll(@Query() query: QueryOrdersDto): Promise<{ orders: OrderResponseDto[]; total: number }> {
    return this.orderService.findAll(query);
  }

  @Patch(':id/image')
  @ApiOperation({ summary: '更新订单图片URL' })
  @ApiResponse({ status: 200, description: '更新成功', type: OrderResponseDto })
  @ApiResponse({ status: 404, description: '订单不存在' })
  async updateImage(
    @Param('id') id: string,
    @Body() updateImageDto: UpdateOrderImageDto,
  ): Promise<OrderResponseDto> {
    const order = await this.orderService.findOneEntity(id);
    order.imageUrl = updateImageDto.imageUrl;
    const updated = await this.orderService['orderRepository'].save(order);
    return this.orderService['toResponseDto'](updated);
  }
}
