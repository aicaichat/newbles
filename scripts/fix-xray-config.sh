#!/bin/bash
set -e

echo "🔧 修复 Xray 配置并重新部署..."

echo "1️⃣ 停止当前 Xray..."
sudo docker-compose -f docker-compose-xray.yml down

echo ""
echo "2️⃣ 检查修复后的配置..."
echo "新的 Xray 配置："
cat xray/config.json

echo ""
echo "3️⃣ 重新启动 Xray..."
sudo docker-compose -f docker-compose-xray.yml up -d

echo ""
echo "4️⃣ 等待启动..."
sleep 5

echo ""
echo "5️⃣ 检查启动状态..."
echo "容器状态："
sudo docker ps | grep xray

echo ""
echo "Xray 日志："
sudo docker logs xray-trojan 2>&1 | tail -10

echo ""
echo "6️⃣ 测试连接..."

# 清理旧的错误日志
sudo truncate -s 0 /var/log/nginx/error.log

echo "等待 10 秒，然后测试 WebSocket 连接..."
sleep 10

# 测试 WebSocket 连接
echo "测试 WebSocket 反代："
curl -k -v \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --connect-timeout 10 \
    https://ai.bless.top/bs 2>&1 | head -15

echo ""
echo "7️⃣ 检查新的错误日志..."
echo "nginx 新错误日志："
sudo tail -10 /var/log/nginx/error.log || echo "没有新的错误日志"

echo ""
echo "🎯 下一步："
echo "如果还有 502 错误，可能需要："
echo "1. 检查 Clash 客户端配置是否正确"
echo "2. 或者尝试不同的 Xray 配置"
echo ""
echo "📋 如果连接正常，现在可以："
echo "1. 在 Clash 中导入：clash/clash-config.yaml" 
echo "2. 选择节点测试科学上网" 