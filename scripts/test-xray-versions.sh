#!/bin/bash
set -e

echo "🚀 解决 Xray 25.5.16 兼容性问题..."
echo ""
echo "📋 问题分析："
echo "- Xray WebSocket 传输已弃用"
echo "- 推荐使用 XHTTP H2 & H3"
echo "- headers 配置格式已过时"
echo ""
echo "🧪 测试方案："
echo "1. XHTTP 传输（推荐）"
echo "2. 修复的 WebSocket 配置"
echo "3. 直接暴露 Xray（绕过 nginx）"

# 方案1: XHTTP 传输
echo ""
echo "=== 方案1: 测试 XHTTP 传输 ==="

echo "1️⃣ 停止当前服务..."
sudo docker-compose -f docker-compose-xray.yml down 2>/dev/null || true

echo "2️⃣ 使用 XHTTP 配置..."
cp xray/config.json xray/config.json.backup 2>/dev/null || true
cp xray/config-xhttp.json xray/config.json

echo "3️⃣ 启动 XHTTP..."
sudo docker-compose -f docker-compose-xray.yml up -d

echo "4️⃣ 等待启动..."
sleep 8

echo "5️⃣ 检查 XHTTP 日志..."
echo "容器状态："
sudo docker ps | grep xray

echo "启动日志："
sudo docker logs xray-trojan 2>&1 | tail -10

# 检查是否有弃用警告
if sudo docker logs xray-trojan 2>&1 | grep -q "deprecated"; then
    echo "⚠️  仍有弃用警告，继续下一个方案"
    XHTTP_OK=false
else
    echo "✅ XHTTP 启动正常，无弃用警告"
    XHTTP_OK=true
fi

echo "6️⃣ 测试 XHTTP 连接..."
sudo truncate -s 0 /var/log/nginx/error.log
sleep 3

curl -k -v --connect-timeout 8 https://ai.bless.top/bs 2>&1 | head -10

XHTTP_ERRORS=$(sudo tail -3 /var/log/nginx/error.log 2>/dev/null | grep "502\|Connection reset" || echo "")

if [ -z "$XHTTP_ERRORS" ] && [ "$XHTTP_OK" = true ]; then
    echo "✅ XHTTP 方案成功！"
    echo ""
    echo "🎉 使用 XHTTP 传输："
    echo "   - 配置：xray/config-xhttp.json"
    echo "   - Clash：clash/clash-config-vmess.yaml"
    echo "   - 协议：VMess + XHTTP"
    exit 0
else
    echo "❌ XHTTP 方案失败：$XHTTP_ERRORS"
fi

# 方案2: 修复的 WebSocket
echo ""
echo "=== 方案2: 测试修复的 WebSocket ==="

echo "1️⃣ 停止 XHTTP..."
sudo docker-compose -f docker-compose-xray.yml down

echo "2️⃣ 使用修复的 WebSocket 配置..."
cp xray/config-ws-fixed.json xray/config.json

echo "3️⃣ 启动修复的 WebSocket..."
sudo docker-compose -f docker-compose-xray.yml up -d

echo "4️⃣ 等待启动..."
sleep 8

echo "5️⃣ 检查修复的 WebSocket..."
sudo docker logs xray-trojan 2>&1 | tail -8

echo "6️⃣ 测试修复的 WebSocket..."
sudo truncate -s 0 /var/log/nginx/error.log
sleep 3

curl -k -v --connect-timeout 8 https://ai.bless.top/bs 2>&1 | head -10

WS_ERRORS=$(sudo tail -3 /var/log/nginx/error.log 2>/dev/null | grep "502\|Connection reset" || echo "")

if [ -z "$WS_ERRORS" ]; then
    echo "✅ 修复的 WebSocket 成功！"
    echo ""
    echo "🎉 使用修复的 WebSocket："
    echo "   - 配置：xray/config-ws-fixed.json"
    echo "   - Clash：clash/clash-config-vmess.yaml"
    exit 0
else
    echo "❌ 修复的 WebSocket 失败：$WS_ERRORS"
fi

# 方案3: 直接暴露 Xray
echo ""
echo "=== 方案3: 直接暴露 Xray（绕过 nginx）==="

echo "1️⃣ 停止当前服务..."
sudo docker-compose -f docker-compose-xray.yml down
sudo systemctl stop nginx

echo "2️⃣ 检查证书文件..."
if [ ! -f "/root/newbles/cert/fullchain.cer" ] || [ ! -f "/root/newbles/cert/ai.bless.top.key" ]; then
    echo "❌ 证书文件缺失，无法直接暴露"
    echo "恢复 nginx..."
    sudo systemctl start nginx
    cp xray/config.json.backup xray/config.json
    exit 1
fi

echo "✅ 证书文件存在"

echo "3️⃣ 启动直接暴露的 Xray..."
sudo docker-compose -f docker-compose-direct.yml up -d

echo "4️⃣ 等待启动..."
sleep 8

echo "5️⃣ 检查直接暴露状态..."
echo "容器状态："
sudo docker ps | grep xray

echo "启动日志："
sudo docker logs xray-direct 2>&1 | tail -10

echo "6️⃣ 测试直接连接..."
sleep 3

# 测试直接 WebSocket 连接
curl -k -v \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --connect-timeout 8 \
    https://ai.bless.top/bs 2>&1 | head -15

if curl -k -I https://ai.bless.top 2>/dev/null | head -1 | grep -q "200\|101"; then
    echo "✅ 直接暴露方案成功！"
    echo ""
    echo "🎉 使用直接暴露模式："
    echo "   - 配置：xray/config-direct.json"
    echo "   - 部署：docker-compose-direct.yml"
    echo "   - Clash：clash/clash-config-vmess.yaml"
    echo ""
    echo "⚠️  注意：nginx 已停止，Xray 直接监听 443 端口"
    exit 0
else
    echo "❌ 直接暴露方案也失败"
    echo ""
    echo "恢复原配置..."
    sudo docker-compose -f docker-compose-direct.yml down
    sudo systemctl start nginx
    cp xray/config.json.backup xray/config.json
    sudo docker-compose -f docker-compose-xray.yml up -d
fi

echo ""
echo "🤔 所有方案都失败，建议："
echo "1. 降级到 Xray 早期版本（支持 WebSocket）"
echo "2. 使用 V2Ray 替代 Xray"
echo "3. 使用 trojan-go 原生实现"
echo "4. 更新 nginx 到最新版本"

echo ""
echo "📊 当前状态："
sudo docker ps | grep -E "(xray|nginx)" || echo "没有相关容器运行"
sudo systemctl status nginx --no-pager | head -3 