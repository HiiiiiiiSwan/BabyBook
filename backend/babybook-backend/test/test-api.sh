#!/bin/bash

# BabyBook 后端 API 测试脚本
# 用法: ./test-api.sh [base_url]
# 默认: http://localhost:3000

BASE_URL="${1:-http://localhost:3000}"
API_PREFIX="/api"

echo "========================================"
echo "BabyBook API 测试脚本"
echo "测试地址: $BASE_URL"
echo "========================================"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试计数
PASS=0
FAIL=0

# 辅助函数：发送请求并检查状态
test_api() {
    local method=$1
    local endpoint=$2
    local data=$3
    local description=$4
    local expected_status=${5:-200}

    echo -e "\n${YELLOW}测试: $description${NC}"
    echo "  $method $endpoint"

    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\n%{http_code}" "$BASE_URL$API_PREFIX$endpoint" \
            -H "Content-Type: application/json")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$BASE_URL$API_PREFIX$endpoint" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" = "$expected_status" ] || ([ "$expected_status" = "201" ] && [ "$http_code" = "201" ]); then
        echo -e "  ${GREEN}✓ 通过 (HTTP $http_code)${NC}"
        echo "  响应: $body"
        ((PASS++))
    else
        echo -e "  ${RED}✗ 失败 (HTTP $http_code, 期望 $expected_status)${NC}"
        echo "  响应: $body"
        ((FAIL++))
    fi

    # 返回响应体供后续使用
    echo "$body"
}

# 1. 测试服务健康检查
echo -e "\n${YELLOW}=== 1. 服务健康检查 ===${NC}"
test_api "GET" "/order" "" "获取订单列表（空）" "200"

# 2. 创建订单
echo -e "\n${YELLOW}=== 2. 创建订单 ===${NC}"
order_response=$(test_api "POST" "/order/create" '{
    "bookId": "Book001",
    "deviceId": "test_device_'$(date +%s)'",
    "imageUrl": null
}' "创建订单" "201")

# 提取订单ID
order_id=$(echo "$order_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "  订单ID: $order_id"

if [ -z "$order_id" ]; then
    echo -e "${RED}无法提取订单ID，后续测试跳过${NC}"
    exit 1
fi

# 3. 查询订单详情
echo -e "\n${YELLOW}=== 3. 查询订单详情 ===${NC}"
test_api "GET" "/order/$order_id" "" "查询订单详情" "200"

# 4. 更新订单图片
echo -e "\n${YELLOW}=== 4. 更新订单图片 ===${NC}"
test_api "PATCH" "/order/$order_id/image" '{
    "imageUrl": "https://example.com/test-baby.jpg"
}' "更新订单图片URL" "200"

# 5. 验证支付（Mock）
echo -e "\n${YELLOW}=== 5. 验证支付（Mock） ===${NC}"
payment_response=$(test_api "POST" "/payment/verify" '{
    "orderId": "'"$order_id"'",
    "receiptData": "mock-receipt-data",
    "transactionId": "1000000123456789",
    "imageUrl": "https://example.com/test-baby.jpg"
}' "验证支付" "201")

# 6. 查询任务状态（根据订单ID）
echo -e "\n${YELLOW}=== 6. 查询任务状态 ===${NC}"
sleep 2
task_response=$(test_api "GET" "/task/order/$order_id" "" "根据订单查询任务" "200")

# 提取任务ID
task_id=$(echo "$task_response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "  任务ID: $task_id"

# 7. 查询任务详情
if [ -n "$task_id" ]; then
    echo -e "\n${YELLOW}=== 7. 查询任务详情 ===${NC}"
    test_api "GET" "/task/$task_id" "" "查询任务详情" "200"
fi

# 8. 获取绘本下载信息
sleep 2
echo -e "\n${YELLOW}=== 8. 获取绘本下载信息 ===${NC}"
test_api "GET" "/book/$order_id/download" "" "获取下载信息" "200"

# 9. 测试上传接口（需要实际文件，可选）
echo -e "\n${YELLOW}=== 9. 测试上传接口（可选） ===${NC}"
if [ -f "./test-baby.jpg" ]; then
    upload_response=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL$API_PREFIX/upload/image" \
        -F "image=@./test-baby.jpg")
    http_code=$(echo "$upload_response" | tail -n1)
    if [ "$http_code" = "201" ]; then
        echo -e "  ${GREEN}✓ 上传成功 (HTTP $http_code)${NC}"
        ((PASS++))
    else
        echo -e "  ${RED}✗ 上传失败 (HTTP $http_code)${NC}"
        ((FAIL++))
    fi
else
    echo "  跳过（未找到 test-baby.jpg 测试文件）"
fi

# 10. 测试 Swagger 文档
echo -e "\n${YELLOW}=== 10. Swagger 文档 ===${NC}"
swagger_response=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/docs")
if [ "$swagger_response" = "200" ]; then
    echo -e "  ${GREEN}✓ Swagger 文档可访问${NC}"
    ((PASS++))
else
    echo -e "  ${RED}✗ Swagger 文档不可访问 (HTTP $swagger_response)${NC}"
    ((FAIL++))
fi

# 11. 测试订单列表（带筛选）
echo -e "\n${YELLOW}=== 11. 查询订单列表（带筛选） ===${NC}"
test_api "GET" "/order?status=PAID&page=1&limit=10" "" "查询已支付订单" "200"

# 12. 测试取消任务（如果有任务）
if [ -n "$task_id" ]; then
    echo -e "\n${YELLOW}=== 12. 取消任务（测试后清理） ===${NC}"
    test_api "POST" "/task/$task_id/cancel" '{}' "取消任务" "201"
fi

# 测试总结
echo -e "\n========================================"
echo -e "${YELLOW}测试总结${NC}"
echo -e "========================================"
echo -e "${GREEN}通过: $PASS${NC}"
echo -e "${RED}失败: $FAIL${NC}"
echo "========================================"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}存在失败的测试，请检查${NC}"
    exit 1
fi
