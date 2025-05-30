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

# 3. 检查证书状态
echo "🔐 检查证书状态..."
if [ -f "/root/newbles/cert/fullchain.cer" ] && [ -f "/root/newbles/cert/ai.bless.top.key" ]; then
    echo "✅ 证书文件存在"
    # 检查证书域名
    CERT_DOMAIN=$(openssl x509 -in /root/newbles/cert/fullchain.cer -subject -noout | grep -o 'CN = [^,]*' | cut -d' ' -f3)
    echo "✅ 证书域名: $CERT_DOMAIN"
else
    echo "❌ 证书文件缺失，需要申请证书"
    echo "请运行: bash scripts/apply-cert.sh"
    exit 1
fi

# 4. 检查 nginx 配置
if [ -f "/etc/nginx/conf.d/ai.bless.top.conf" ]; then
    echo "🔍 检查 nginx 配置..."
    
    # 测试配置语法
    if sudo nginx -t 2>/dev/null; then
        echo "✅ nginx 配置语法正确"
    else
        echo "❌ nginx 配置语法错误"
        sudo nginx -t
        exit 1
    fi
    
    # 检查反代配置
    if grep -q "location /bs" /etc/nginx/conf.d/ai.bless.top.conf; then
        echo "✅ nginx 已配置 /bs 反代"
    else
        echo "⚠️  nginx 缺少 /bs 反代配置，需要更新"
        echo "请运行: bash scripts/deploy-nginx.sh"
        exit 1
    fi
    
    # 检查证书路径
    echo "🔍 检查 nginx 证书配置..."
    grep -E "(ssl_certificate|ssl_certificate_key)" /etc/nginx/conf.d/ai.bless.top.conf
    
else
    echo "⚠️  nginx 配置文件不存在，需要创建"
    echo "请运行: bash scripts/deploy-nginx.sh"
    exit 1
fi

# 5. 重载 nginx 配置
echo "🔄 重载 nginx 配置..."
sudo nginx -s reload

# 6. 重新启动 trojan-go（明文模式）
echo "🚀 启动 trojan-go（明文 WebSocket 模式）..."
sudo docker-compose up -d

# 7. 等待服务启动
sleep 3

# 8. 检查服务状态
echo "🔍 检查服务状态..."
echo "Docker 容器状态:"
sudo docker ps | grep trojan-go || echo "trojan-go 容器未运行"

echo "nginx 进程状态:"
sudo systemctl status nginx --no-pager -l || echo "nginx 状态检查完成"

# 9. 测试连接
echo "🧪 测试连接..."

# 测试 HTTPS（跳过证书验证）
echo "测试 HTTPS 连接（跳过证书验证）:"
curl -k -I "https://ai.bless.top" 2>/dev/null | head -1 || echo "HTTPS 连接测试完成"

# 测试本地 WebSocket 端口
echo "测试本地 8443 端口:"
timeout 3 nc -z 127.0.0.1 8443 && echo "✅ 8443 端口可访问" || echo "❌ 8443 端口不可访问"

echo ""
echo "🎉 修复完成！"
echo "📋 当前配置："
echo "   - trojan-go: 127.0.0.1:8443 (明文 WebSocket)"
echo "   - WebSocket 路径: /bs"
echo "   - 8443 端口: 仅本地访问"
echo "   - 证书域名: $CERT_DOMAIN"
echo ""
echo "🔧 下一步："
echo "   1. 测试 Clash 连接"
echo "   2. 如有问题，查看日志"
echo ""
echo "📊 查看日志:"
echo "   - trojan-go: sudo docker logs trojan-go"
echo "   - nginx access: sudo tail -f /var/log/nginx/access.log"
echo "   - nginx error: sudo tail -f /var/log/nginx/error.log" 