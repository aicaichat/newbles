#!/bin/bash
set -e

echo "🧪 测试不同协议解决 502 错误..."

echo "📋 可用方案："
echo "1. VMess 协议（推荐，兼容性更好）"
echo "2. 优化的 Trojan 配置"

# 方案1：测试 VMess
echo ""
echo "=== 方案1：测试 VMess 协议 ==="

echo "1️⃣ 停止当前 Xray..."
sudo docker-compose -f docker-compose-xray.yml down

echo "2️⃣ 备份当前配置..."
cp xray/config.json xray/config.json.backup

echo "3️⃣ 使用 VMess 配置..."
cp xray/config-vmess.json xray/config.json

echo "4️⃣ 启动 Xray（VMess）..."
sudo docker-compose -f docker-compose-xray.yml up -d

echo "5️⃣ 等待启动..."
sleep 8

echo "6️⃣ 检查 VMess 启动状态..."
echo "Xray 容器："
sudo docker ps | grep xray

echo "Xray 日志："
sudo docker logs xray-trojan 2>&1 | tail -8

echo "7️⃣ 清理错误日志..."
sudo truncate -s 0 /var/log/nginx/error.log

echo "8️⃣ 测试 VMess WebSocket 连接..."
sleep 3

curl -k -v \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --http1.1 \
    --connect-timeout 8 \
    https://ai.bless.top/bs 2>&1 | head -15

echo ""
echo "9️⃣ 检查 VMess 错误日志..."
VMESS_ERRORS=$(sudo tail -5 /var/log/nginx/error.log 2>/dev/null | grep "502\|Connection reset" || echo "")

if [ -z "$VMESS_ERRORS" ]; then
    echo "✅ VMess 测试成功！没有 502 错误"
    echo ""
    echo "🎉 推荐使用 VMess 配置！"
    echo "📋 Clash 配置已准备："
    echo "   - 文件：clash/clash-config-vmess.yaml"
    echo "   - 协议：VMess"
    echo "   - UUID：12345678-1234-5678-9abc-123456789abc"
    echo ""
    cat clash/clash-config-vmess.yaml
    exit 0
else
    echo "❌ VMess 仍有问题："
    echo "$VMESS_ERRORS"
fi

# 方案2：测试优化的 Trojan
echo ""
echo "=== 方案2：测试优化的 Trojan 配置 ==="

echo "1️⃣ 停止 VMess..."
sudo docker-compose -f docker-compose-xray.yml down

echo "2️⃣ 使用优化的 Trojan 配置..."
cp xray/config-trojan-fixed.json xray/config.json

echo "3️⃣ 启动优化的 Trojan..."
sudo docker-compose -f docker-compose-xray.yml up -d

echo "4️⃣ 等待启动..."
sleep 8

echo "5️⃣ 检查优化的 Trojan 状态..."
echo "Xray 日志："
sudo docker logs xray-trojan 2>&1 | tail -8

echo "6️⃣ 清理错误日志..."
sudo truncate -s 0 /var/log/nginx/error.log

echo "7️⃣ 测试优化的 Trojan..."
sleep 3

curl -k -v \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --http1.1 \
    --connect-timeout 8 \
    https://ai.bless.top/bs 2>&1 | head -15

echo ""
echo "8️⃣ 检查优化的 Trojan 错误日志..."
TROJAN_ERRORS=$(sudo tail -5 /var/log/nginx/error.log 2>/dev/null | grep "502\|Connection reset" || echo "")

if [ -z "$TROJAN_ERRORS" ]; then
    echo "✅ 优化的 Trojan 测试成功！"
    echo ""
    echo "📋 使用当前 Clash 配置："
    echo "   - 文件：clash/clash-config.yaml"
    echo "   - 协议：Trojan"
    echo ""
    cat clash/clash-config.yaml
else
    echo "❌ 优化的 Trojan 仍有问题："
    echo "$TROJAN_ERRORS"
    
    # 恢复原配置
    cp xray/config.json.backup xray/config.json
    
    echo ""
    echo "🤔 两种方案都失败，可能需要："
    echo "1. 检查 Xray 版本兼容性"
    echo "2. 尝试其他代理协议（如 VLESS）"
    echo "3. 使用其他代理软件（如 V2Ray）"
    echo "4. 检查 nginx 版本和 WebSocket 支持"
fi

echo ""
echo "📊 最终服务状态："
sudo docker ps | grep xray
echo ""
echo "🔍 端口监听："
sudo netstat -tlnp | grep 8443 