#!/bin/bash
set -e

echo "🔧 修复当前配置问题..."

# 1. 停止当前的 trojan-go（如果在运行）
echo "⏹️  停止当前服务..."
sudo docker-compose down 2>/dev/null || echo "Docker 服务未在运行"

# 2. 限制 8443 端口访问
echo "🔒 限制 8443 端口..."
sudo iptables -C INPUT -p tcp --dport 8443 ! -s 127.0.0.1 -j DROP 2>/dev/null || \
sudo iptables -A INPUT -p tcp --dport 8443 ! -s 127.0.0.1 -j DROP
echo "✅ 8443 端口已限制为仅本地访问"

# 3. 检查 nginx 配置
if [ -f "/etc/nginx/conf.d/ai.bless.top.conf" ]; then
    echo "🔍 检查现有 nginx 配置..."
    if grep -q "location /bs" /etc/nginx/conf.d/ai.bless.top.conf; then
        echo "✅ nginx 已配置 /bs 反代"
    else
        echo "⚠️  nginx 缺少 /bs 反代配置，需要更新"
        echo "请运行: bash scripts/deploy-nginx.sh"
    fi
else
    echo "⚠️  nginx 配置文件不存在，需要创建"
    echo "请运行: bash scripts/deploy-nginx.sh"
fi

# 4. 重新启动 trojan-go（明文模式）
echo "🚀 启动 trojan-go（明文 WebSocket 模式）..."
sudo docker-compose up -d

echo ""
echo "🎉 修复完成！"
echo "📋 当前配置："
echo "   - trojan-go: 127.0.0.1:8443 (明文 WebSocket)"
echo "   - WebSocket 路径: /bs"
echo "   - 8443 端口: 仅本地访问"
echo ""
echo "🔧 下一步："
echo "   1. 确保 nginx 配置正确: bash scripts/deploy-nginx.sh"
echo "   2. 测试 Clash 连接"
echo ""
echo "📊 查看日志:"
echo "   sudo docker logs vpn-trojan-go-1" 