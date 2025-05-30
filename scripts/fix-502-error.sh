#!/bin/bash
set -e

echo "🔧 修复 502 Bad Gateway 错误..."

echo "1️⃣ 停止当前 Xray..."
sudo docker-compose -f docker-compose-xray.yml down

echo ""
echo "2️⃣ 检查并修复 nginx WebSocket 反代配置..."

# 创建优化的 nginx 配置
sudo tee /etc/nginx/conf.d/ai.bless.top.conf > /dev/null <<'EOF'
server {
    listen 80;
    server_name ai.bless.top;

    root /var/www/ai.bless.top/;

    location /.well-known/acme-challenge/ {
        alias /var/www/ai.bless.top/.well-known/acme-challenge/;
        try_files $uri =404;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name ai.bless.top;

    ssl_certificate /root/newbles/cert/fullchain.cer;
    ssl_certificate_key /root/newbles/cert/ai.bless.top.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 优化的 WebSocket 反代配置
    location /bs {
        # 强制使用 HTTP/1.1，禁用缓冲
        proxy_pass http://127.0.0.1:8443;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_cache off;
        
        # WebSocket 必需的头部
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 延长超时时间，避免连接中断
        proxy_connect_timeout 10s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
        
        # 禁用重定向
        proxy_redirect off;
    }

    location / {
        root /var/www/ai.bless.top/;
        index index.html index.htm;
        try_files $uri $uri/ =404;
    }
}
EOF

echo "✅ nginx 配置已更新"

echo ""
echo "3️⃣ 测试 nginx 配置..."
if sudo nginx -t; then
    echo "✅ nginx 配置语法正确"
    sudo nginx -s reload
    echo "✅ nginx 已重载"
else
    echo "❌ nginx 配置错误"
    exit 1
fi

echo ""
echo "4️⃣ 重新启动 Xray（使用优化配置）..."
sudo docker-compose -f docker-compose-xray.yml up -d

echo ""
echo "5️⃣ 等待 Xray 启动..."
sleep 8

echo ""
echo "6️⃣ 检查服务状态..."
echo "Xray 容器状态："
sudo docker ps | grep xray

echo ""
echo "Xray 启动日志："
sudo docker logs xray-trojan 2>&1 | tail -10

echo ""
echo "7️⃣ 清理日志并测试..."
# 清理错误日志
sudo truncate -s 0 /var/log/nginx/error.log

echo "等待 5 秒后测试连接..."
sleep 5

# 测试 WebSocket 连接（强制 HTTP/1.1）
echo "测试优化后的 WebSocket 反代："
curl -k -v -w "\n状态码: %{http_code}\n连接时间: %{time_connect}s\n" \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --http1.1 \
    --connect-timeout 10 \
    https://ai.bless.top/bs 2>&1 | head -20

echo ""
echo "8️⃣ 检查新的错误日志..."
echo "nginx 新错误日志："
sudo tail -10 /var/log/nginx/error.log 2>/dev/null || echo "没有新的错误日志"

echo ""
echo "9️⃣ 最终测试端口连通性..."
if timeout 5 bash -c '</dev/tcp/127.0.0.1/8443'; then
    echo "✅ 8443 端口连通正常"
else
    echo "❌ 8443 端口连接失败"
fi

echo ""
echo "🎯 问题诊断："

# 检查关键进程
echo "关键服务状态："
sudo docker ps | grep xray || echo "❌ Xray 容器未运行"
sudo systemctl is-active nginx || echo "❌ nginx 未运行"

# 检查端口监听
echo "端口监听状态："
sudo netstat -tlnp | grep -E "(443|8443)" || echo "❌ 端口未监听"

echo ""
if sudo tail -1 /var/log/nginx/error.log 2>/dev/null | grep -q "502"; then
    echo "❌ 仍然有 502 错误，可能需要："
    echo "1. 检查 Xray 是否真正支持 trojan+websocket"
    echo "2. 尝试使用 VMess 协议替代"
    echo "3. 检查 Clash 客户端配置"
else
    echo "✅ 没有新的 502 错误！"
    echo ""
    echo "📋 下一步："
    echo "1. 在 Clash 中导入配置：clash/clash-config.yaml"
    echo "2. 选择节点：Trojan-ai.bless.top"
    echo "3. 测试科学上网"
fi 