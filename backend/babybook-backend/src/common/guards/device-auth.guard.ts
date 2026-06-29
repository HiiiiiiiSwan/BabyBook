import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';

/**
 * 设备认证守卫
 * 基于 device_id 的轻量认证机制
 * 验证请求中是否包含有效的 device_id
 */
@Injectable()
export class DeviceAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();

    // 从请求头或请求体中获取 device_id
    const deviceId = this.extractDeviceId(request);

    if (!deviceId || deviceId.trim().length === 0) {
      throw new UnauthorizedException('缺少设备标识 (device_id)，请确保请求中包含有效的 device_id');
    }

    // 验证 device_id 格式（至少 8 个字符，只允许字母、数字、下划线和连字符）
    const deviceIdPattern = /^[a-zA-Z0-9_-]{8,}$/;
    if (!deviceIdPattern.test(deviceId)) {
      throw new UnauthorizedException('设备标识格式无效');
    }

    // 将 device_id 附加到请求对象，供后续使用
    request['deviceId'] = deviceId;

    return true;
  }

  private extractDeviceId(request: Request): string | undefined {
    // 优先从请求头中获取
    const headerDeviceId = request.headers['x-device-id'] as string;
    if (headerDeviceId) {
      return headerDeviceId;
    }

    // 从请求体中获取（适用于 POST/PUT 请求）
    const body = request.body;
    if (body && body.deviceId) {
      return body.deviceId;
    }

    // 从查询参数中获取（适用于 GET 请求）
    const query = request.query;
    if (query && query.deviceId) {
      return query.deviceId as string;
    }

    return undefined;
  }
}
