import { Controller, Post, Get, Body, Param, Query, Patch, UseGuards, Req, UnauthorizedException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { OrderService } from './order.service';
import { CreateOrderDto, OrderResponseDto, QueryOrdersDto, UpdateOrderImageDto } from './dto/order.dto';
import { DeviceAuthGuard } from '../common/guards/device-auth.guard';
import { Request } from 'express';

@ApiTags('订单')
@Controller('api/order')
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  @Post('create')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '创建订单' })
  @ApiResponse({ status: 201, description: '订单创建成功', type: OrderResponseDto })
  @ApiResponse({ status: 400, description: '参数错误' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async create(@Body() createOrderDto: CreateOrderDto): Promise<OrderResponseDto> {
    return this.orderService.create(createOrderDto);
  }

  @Get(':id')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '查询订单详情' })
  @ApiResponse({ status: 200, description: '查询成功', type: OrderResponseDto })
  @ApiResponse({ status: 404, description: '订单不存在' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async findById(@Param('id') id: string, @Req() req: Request): Promise<OrderResponseDto> {
    const order = await this.orderService.findById(id);
    // 验证设备权限：只能查询自己的订单
    const deviceId = req['deviceId'];
    if (order.deviceId !== deviceId) {
      throw new UnauthorizedException('无权访问此订单');
    }
    return order;
  }

  @Get()
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '查询订单列表' })
  @ApiResponse({ status: 200, description: '查询成功' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async findAll(@Query() query: QueryOrdersDto, @Req() req: Request): Promise<{ orders: OrderResponseDto[]; total: number }> {
    // 强制使用当前设备的 device_id，防止查询其他设备的订单
    const deviceId = req['deviceId'];
    query.deviceId = deviceId;
    return this.orderService.findAll(query);
  }

  @Patch(':id/image')
  @UseGuards(DeviceAuthGuard)
  @ApiOperation({ summary: '更新订单图片URL' })
  @ApiResponse({ status: 200, description: '更新成功', type: OrderResponseDto })
  @ApiResponse({ status: 404, description: '订单不存在' })
  @ApiResponse({ status: 401, description: '缺少或无效的设备标识' })
  async updateImage(
    @Param('id') id: string,
    @Body() updateImageDto: UpdateOrderImageDto,
    @Req() req: Request,
  ): Promise<OrderResponseDto> {
    const order = await this.orderService.findOneEntity(id);
    // 验证设备权限
    const deviceId = req['deviceId'];
    if (order.deviceId !== deviceId) {
      throw new UnauthorizedException('无权访问此订单');
    }
    order.imageUrl = updateImageDto.imageUrl;
    const updated = await this.orderService['orderRepository'].save(order);
    return this.orderService['toResponseDto'](updated);
  }
}
