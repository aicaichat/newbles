#!/bin/bash
set -e

echo "🚨 紧急修复：证书路径和配置问题"

# 1. 停止服务
echo "⏹️  停止所有服务..."
sudo docker-compose down

# 2. 修复 nginx 证书路径
echo "🔧 修复 nginx 证书路径..."
if [ -f "/etc/nginx/conf.d/ai.bless.top.conf" ]; then
    # 备份原配置
    sudo cp /etc/nginx/conf.d/ai.bless.top.conf /etc/nginx/conf.d/ai.bless.top.conf.backup
    
    # 修复证书路径（从 new.bless.top.key 改为 ai.bless.top.key）
    sudo sed -i 's/new\.bless\.top\.key/ai.bless.top.key/g' /etc/nginx/conf.d/ai.bless.top.conf
    
    echo "✅ nginx 证书路径已修复"
    echo "修复后的证书配置："
    grep ssl_certificate /etc/nginx/conf.d/ai.bless.top.conf
else
    echo "❌ nginx 配置文件不存在，需要创建"
    # 使用我们的模板配置
    sudo cp ./scripts/nginx-ssl.conf /etc/nginx/conf.d/ai.bless.top.conf
    echo "✅ 已创建 nginx 配置文件"
fi

# 3. 验证证书文件存在
echo "🔐 验证证书文件..."
if [ -f "/root/newbles/cert/fullchain.cer" ] && [ -f "/root/newbles/cert/ai.bless.top.key" ]; then
    echo "✅ 证书文件存在"
    ls -la /root/newbles/cert/fullchain.cer /root/newbles/cert/ai.bless.top.key
else
    echo "❌ 证书文件缺失"
    exit 1
fi

# 4. 测试 nginx 配置
echo "🧪 测试 nginx 配置..."
if sudo nginx -t; then
    echo "✅ nginx 配置正确"
else
    echo "❌ nginx 配置仍有错误"
    exit 1
fi

# 5. 重载 nginx
echo "🔄 重载 nginx..."
sudo nginx -s reload

# 6. 检查本地 trojan-go 配置
echo "🔍 检查 trojan-go 配置..."
if grep -q '"ssl"' trojan-go/config.json; then
    echo "❌ 检测到 trojan-go 配置中有 SSL 字段，这是错误的！"
    echo "当前配置："
    cat trojan-go/config.json
    echo ""
    echo "请确保配置文件中没有 ssl 字段，只有 websocket 配置"
    exit 1
else
    echo "✅ trojan-go 配置正确（无 SSL 字段）"
fi

# 7. 重新启动 trojan-go
echo "🚀 启动 trojan-go..."
sudo docker-compose up -d

# 8. 等待启动
sleep 5

# 9. 检查服务状态
echo "🔍 检查服务状态..."

# 检查 trojan-go 容器
echo "trojan-go 容器状态："
sudo docker ps | grep trojan-go

# 检查 trojan-go 日志
echo "trojan-go 最新日志："
sudo docker logs trojan-go 2>&1 | tail -5

# 检查 nginx 状态
echo "nginx 状态："
sudo systemctl status nginx --no-pager | head -3

# 10. 测试连接
echo "🧪 最终测试..."

# 测试 HTTPS
echo "测试 HTTPS："
curl -k -I https://ai.bless.top 2>/dev/null | head -1 || echo "HTTPS 测试完成"

# 测试本地端口
echo "测试本地 8443 端口："
timeout 3 nc -z 127.0.0.1 8443 && echo "✅ 8443 端口可访问" || echo "❌ 8443 端口不可访问"

echo ""
echo "🎉 修复完成！"
echo ""
echo "📊 如果仍有问题，请查看日志："
echo "   - trojan-go: sudo docker logs trojan-go"
echo "   - nginx error: sudo tail -f /var/log/nginx/error.log" 