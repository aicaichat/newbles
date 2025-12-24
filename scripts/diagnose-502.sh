#!/bin/bash
set -e

echo "🔍 诊断 502 Bad Gateway 问题..."

echo "1️⃣ 检查 Xray 日志..."
echo "Xray 容器日志："
sudo docker logs xray-trojan 2>&1 | tail -20

echo ""
echo "2️⃣ 检查 nginx 错误日志..."
echo "nginx 错误日志："
sudo tail -20 /var/log/nginx/error.log

echo ""
echo "3️⃣ 检查 nginx /bs 反代配置..."
echo "location /bs 配置："
cat /etc/nginx/conf.d/ai.bless.top.conf | grep -A 15 "location /bs" || echo "未找到 /bs 配置"

echo ""
echo "4️⃣ 测试本地连接..."
echo "测试 nginx → Xray 连接："
curl -v --connect-timeout 3 http://127.0.0.1:8443 2>&1 | head -5 || echo "本地连接测试完成"

echo ""
echo "5️⃣ 检查 Xray 配置文件..."
echo "Xray 实际配置："
sudo docker exec xray-trojan cat /etc/xray/config.json 2>/dev/null || echo "无法读取 Xray 配置"

echo ""
echo "6️⃣ 测试端口连通性..."
echo "测试端口连通性："
timeout 3 xbash -c 'cat < /dev/null > /dev/tcp/127.0.0.1/8443' && echo "✅ 8443 端口可连接" || echo "❌ 8443 端口连接失败"

echo ""
echo "7️⃣ 检查进程状态..."
echo "相关进程："
sudo ps aux | grep -E "(xray|nginx)" | grep -v grep

echo ""
echo "🔧 可能的解决方案："
echo "1. 如果 Xray 日志有错误，需要修复 Xray 配置"
echo "2. 如果 nginx 错误日志显示连接问题，需要修复反代配置"
echo "3. 如果端口不通，可能需要重启服务" 