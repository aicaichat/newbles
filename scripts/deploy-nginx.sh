#!/bin/bash
set -e

echo "🚀 开始部署 trojan-go + nginx 反代..."

# 1. 创建 webroot 目录并写入测试文件
WEBROOT="/var/www/ai.bless.top/"
echo "📁 创建 webroot 目录..."
sudo mkdir -p "$WEBROOT/.well-known/acme-challenge/"
echo test | sudo tee "$WEBROOT/.well-known/acme-challenge/test.txt"

# 2. 申请证书（如果还没有的话）
echo "🔐 申请/更新 SSL 证书..."
if [ ! -f "/root/newbles/cert/fullchain.cer" ]; then
    bash ./scripts/apply-cert.sh
else
    echo "证书已存在，跳过申请"
fi

# 3. 应用 nginx SSL 配置
NGINX_CONF="/etc/nginx/conf.d/ai.bless.top.conf"
echo "⚙️  配置 nginx..."
sudo cp ./scripts/nginx-ssl.conf "$NGINX_CONF"
sudo nginx -t && sudo nginx -s reload

# 4. 确保 8443 端口只允许本地访问
echo "🔒 配置防火墙规则..."
sudo iptables -C INPUT -p tcp --dport 8443 ! -s 127.0.0.1 -j DROP 2>/dev/null || \
sudo iptables -A INPUT -p tcp --dport 8443 ! -s 127.0.0.1 -j DROP
echo "✅ 8443 端口已限制为仅本地访问"

# 5. 启动 trojan-go
echo "🔧 启动 trojan-go..."
sudo docker-compose up -d

# 6. 等待服务启动
sleep 3

# 7. 测试配置
echo "🧪 测试配置..."
echo "测试 nginx 到 trojan-go 连接:"
curl -I "http://127.0.0.1:8443" || echo "8443 连接测试完成（预期会失败，因为不是 WebSocket）"

echo "测试 HTTPS 服务:"
curl -I "https://ai.bless.top" || echo "HTTPS 服务测试完成"

# 8. 输出信息
CLASH_CONFIG="$(cd "$(dirname "$0")/.." && pwd)/clash/clash-config.yaml"
echo ""
echo "🎉 部署完成！"
echo "📋 配置信息："
echo "   - trojan-go 监听: 127.0.0.1:8443 (明文 WebSocket)"
echo "   - nginx 监听: 443 (SSL) + 80 (重定向)"
echo "   - WebSocket 路径: /bs"
echo "   - Clash 配置: $CLASH_CONFIG"
echo ""
echo "🔧 使用方法："
echo "   1. 将 $CLASH_CONFIG 导入到 Clash 客户端"
echo "   2. 选择 'Trojan-ai.bless.top' 节点"
echo "   3. 开始科学上网"
echo ""
echo "📊 查看日志："
echo "   - trojan-go: sudo docker logs trojan-go-service"
echo "   - nginx: sudo tail -f /var/log/nginx/access.log" 