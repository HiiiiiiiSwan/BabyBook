###################
# 构建阶段
###################
FROM node:22-alpine AS builder

WORKDIR /app

# 复制 package 文件（构建上下文为项目根目录）
COPY backend/babybook-backend/package*.json ./
RUN npm ci && npm cache clean --force

# 复制后端源代码（构建上下文为项目根目录）
COPY backend/babybook-backend/tsconfig*.json ./
COPY backend/babybook-backend/nest-cli.json ./
COPY backend/babybook-backend/src ./src

# 复制绘本模板资源到容器固定目录，供 AI 生图时读取
COPY templates ./templates

# 构建 NestJS 项目
RUN npm run build

# 验证构建产物
RUN ls -la dist/src/ && cat dist/src/main.js | head -5

###################
# 生产阶段
###################
FROM node:22-alpine

WORKDIR /app

# 安装 dumb-init 用于正确处理信号
RUN apk add --no-cache dumb-init

# 复制构建产物、依赖与模板资源
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/templates ./templates

# 验证文件
RUN ls -la dist/src/ && ls -la dist/src/main.js

# 创建非 root 用户运行服务
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 预创建上传临时目录并授权给 nodejs 用户
# multer 在模块加载时会 mkdirSync('./uploads/temp')，非 root 用户需提前拥有该目录写权限
RUN mkdir -p /app/uploads/temp && chown -R nodejs:nodejs /app/uploads

USER nodejs

# 暴露端口
EXPOSE 3000

# 健康检查（使用无需认证的 /health 端点）
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => r.statusCode === 200 ? process.exit(0) : process.exit(1))"

# 启动命令
CMD ["dumb-init", "node", "dist/src/main.js"]
