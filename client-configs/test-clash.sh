#!/bin/bash

# Clash 配置快速测试脚本
# 用于测试 VMess 代理配置是否可用

echo "🧪 Clash 配置测试脚本"
echo "===================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置参数
SERVER="ai.bless.top"
PORT=443
UUID="25c09e60-e69d-4b6b-b119-300180ef7fbb"
PATH_WS="/bs"
CLASH_HTTP_PORT=7890
CLASH_SOCKS_PORT=7891

# 测试计数器
PASSED=0
FAILED=0

# 测试函数
test_check() {
    local name=$1
    local command=$2
    local expected=$3
    
    echo -n "测试: $name ... "
    
    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ 失败${NC}"
        ((FAILED++))
        return 1
    fi
}

# 1. 测试服务器域名解析
echo "1️⃣ 测试服务器域名解析..."
if test_check "DNS 解析" "nslookup $SERVER" ""; then
    IP=$(nslookup $SERVER 2>/dev/null | grep -A1 "Name:" | grep "Address:" | tail -1 | awk '{print $2}')
    if [ -n "$IP" ]; then
        echo "   📍 服务器IP: $IP"
    fi
else
    echo "   ⚠️  无法解析域名，请检查网络连接"
fi
echo ""

# 2. 测试服务器端口连通性
echo "2️⃣ 测试服务器端口连通性..."
if command -v nc &> /dev/null; then
    if test_check "端口 $PORT 连通性" "nc -zv -w 5 $SERVER $PORT"; then
        echo "   ✅ 端口 $PORT 可访问"
    else
        echo "   ❌ 无法连接到端口 $PORT"
        echo "      可能原因："
        echo "      - 服务器未运行"
        echo "      - 防火墙阻止"
        echo "      - 网络问题"
    fi
else
    echo "   ⚠️  nc 命令未安装，跳过端口测试"
    echo "   安装: brew install netcat (macOS) 或 apt install netcat (Linux)"
fi
echo ""

# 3. 测试 HTTPS 连接
echo "3️⃣ 测试 HTTPS 连接..."
if test_check "HTTPS 连接" "curl -s -I --max-time 10 https://$SERVER" ""; then
    echo "   ✅ HTTPS 连接正常"
else
    echo "   ⚠️  HTTPS 连接失败（可能是正常的，如果服务器只接受 WebSocket）"
fi
echo ""

# 4. 测试 UUID 格式
echo "4️⃣ 验证 UUID 格式..."
UUID_PATTERN="^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
if echo "$UUID" | grep -qE "$UUID_PATTERN"; then
    echo -e "   ${GREEN}✅ UUID 格式正确${NC}"
    ((PASSED++))
else
    echo -e "   ${RED}❌ UUID 格式错误${NC}"
    ((FAILED++))
fi
echo ""

# 5. 测试 Clash 是否运行
echo "5️⃣ 检查 Clash 服务..."
CLASH_RUNNING=false

# 检查 HTTP 代理端口
if command -v nc &> /dev/null; then
    if nc -zv -w 2 127.0.0.1 $CLASH_HTTP_PORT 2>&1 | grep -q "succeeded"; then
        echo -e "   ${GREEN}✅ Clash HTTP 代理端口 $CLASH_HTTP_PORT 正在监听${NC}"
        CLASH_RUNNING=true
        ((PASSED++))
    else
        echo -e "   ${YELLOW}⚠️  Clash HTTP 代理端口 $CLASH_HTTP_PORT 未监听${NC}"
        ((FAILED++))
    fi
    
    # 检查 SOCKS5 代理端口
    if nc -zv -w 2 127.0.0.1 $CLASH_SOCKS_PORT 2>&1 | grep -q "succeeded"; then
        echo -e "   ${GREEN}✅ Clash SOCKS5 代理端口 $CLASH_SOCKS_PORT 正在监听${NC}"
        ((PASSED++))
    else
        echo -e "   ${YELLOW}⚠️  Clash SOCKS5 代理端口 $CLASH_SOCKS_PORT 未监听${NC}"
        ((FAILED++))
    fi
else
    echo "   ⚠️  无法检查端口（nc 未安装）"
fi
echo ""

# 6. 测试代理功能（如果 Clash 正在运行）
if [ "$CLASH_RUNNING" = true ]; then
    echo "6️⃣ 测试代理功能..."
    
    # 测试通过代理获取IP
    echo -n "   测试代理连接... "
    PROXY_IP=$(curl -s -x http://127.0.0.1:$CLASH_HTTP_PORT https://ip.sb --max-time 10 2>/dev/null)
    
    if [ -n "$PROXY_IP" ]; then
        echo -e "${GREEN}✅ 成功${NC}"
        echo "   📍 当前代理IP: $PROXY_IP"
        ((PASSED++))
        
        # 获取本地IP对比
        LOCAL_IP=$(curl -s https://ip.sb --max-time 5 2>/dev/null)
        if [ -n "$LOCAL_IP" ] && [ "$PROXY_IP" != "$LOCAL_IP" ]; then
            echo -e "   ${GREEN}✅ IP 已改变（代理生效）${NC}"
            echo "   📍 本地IP: $LOCAL_IP"
            echo "   📍 代理IP: $PROXY_IP"
            ((PASSED++))
        fi
        
        # 测试访问 Google
        echo -n "   测试访问 Google... "
        if curl -s -x http://127.0.0.1:$CLASH_HTTP_PORT https://www.google.com -I --max-time 10 2>&1 | grep -q "HTTP"; then
            echo -e "${GREEN}✅ 成功${NC}"
            ((PASSED++))
        else
            echo -e "${YELLOW}⚠️  失败（可能是网络问题）${NC}"
            ((FAILED++))
        fi
    else
        echo -e "${RED}❌ 失败${NC}"
        echo "   可能原因："
        echo "      - Clash 配置未正确加载"
        echo "      - 代理节点不可用"
        echo "      - 网络连接问题"
        ((FAILED++))
    fi
    echo ""
    
    # 测试 Clash API（如果可用）
    echo "7️⃣ 测试 Clash API..."
    if curl -s http://127.0.0.1:9090/version > /dev/null 2>&1; then
        echo -e "   ${GREEN}✅ Clash API 可用${NC}"
        VERSION=$(curl -s http://127.0.0.1:9090/version 2>/dev/null | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$VERSION" ]; then
            echo "   📦 Clash 版本: $VERSION"
        fi
        ((PASSED++))
    else
        echo -e "   ${YELLOW}⚠️  Clash API 不可用（external-controller 可能未启用）${NC}"
    fi
    echo ""
else
    echo "6️⃣ 跳过代理功能测试（Clash 未运行）"
    echo ""
    echo "   💡 启动 Clash 的方法："
    echo "      - 使用 Clash Verge Rev 客户端"
    echo "      - 命令行: clash -d ~/.config/clash"
    echo ""
fi

# 7. 配置验证
echo "8️⃣ 验证配置参数..."
echo "   服务器: $SERVER"
echo "   端口: $PORT"
echo "   UUID: $UUID"
echo "   WebSocket 路径: $PATH_WS"
echo "   TLS: 启用"
echo ""

# 总结
echo "===================="
echo "📊 测试结果总结"
echo "===================="
echo -e "   ${GREEN}通过: $PASSED${NC}"
echo -e "   ${RED}失败: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！配置应该可以正常使用。${NC}"
    exit 0
elif [ $PASSED -gt $FAILED ]; then
    echo -e "${YELLOW}⚠️  部分测试失败，但基本功能可能正常。${NC}"
    echo "   请检查失败的测试项。"
    exit 1
else
    echo -e "${RED}❌ 多个测试失败，配置可能有问题。${NC}"
    echo "   请检查："
    echo "   1. 服务器是否正常运行"
    echo "   2. 配置参数是否正确"
    echo "   3. Clash 是否正确启动"
    exit 2
fi

