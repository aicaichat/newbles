#!/bin/bash
set -e

echo "🔧 强制 nginx 使用 HTTP/1.1，解决协议冲突..."

echo "1️⃣ 停止当前 Xray..."
sudo docker-compose -f docker-compose-xray.yml down 2>/dev/null || true

echo "2️⃣ 创建强制 HTTP/1.1 的 nginx 配置（修复重复指令）..."

# 创建专门的 nginx 配置，强制 HTTP/1.1
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

# HTTP/1.1 专用 server 块用于 WebSocket
server {
    listen 443 ssl;  # 移除 http2，强制 HTTP/1.1
    server_name ai.bless.top;

    ssl_certificate /root/newbles/cert/fullchain.cer;
    ssl_certificate_key /root/newbles/cert/ai.bless.top.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # 专门为 WebSocket 优化的反代配置
    location /bs {
        proxy_pass http://127.0.0.1:8443;
        proxy_http_version 1.1;
        
        # 完全禁用所有缓冲和缓存
        proxy_buffering off;
        proxy_cache off;
        proxy_request_buffering off;
        
        # WebSocket 升级头部
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # 优化的超时设置
        proxy_connect_timeout 60s;
        proxy_send_timeout 3600s;
        proxy_read_timeout 3600s;
        
        # 禁用重定向和错误页面
        proxy_redirect off;
        proxy_intercept_errors off;
    }

    # 其他路径的处理
    location / {
        root /var/www/ai.bless.top/;
        index index.html index.htm;
        try_files $uri $uri/ =404;
    }
}
EOF

echo "✅ nginx 配置已更新（修复重复指令）"

echo "3️⃣ 测试 nginx 配置..."
if sudo nginx -t; then
    echo "✅ nginx 配置语法正确"
    sudo nginx -s reload
    echo "✅ nginx 已重载"
else
    echo "❌ nginx 配置仍有错误，显示详细错误信息："
    sudo nginx -t
    exit 1
fi

echo "4️⃣ 使用修复的 WebSocket 配置启动 Xray..."
cp xray/config-ws-fixed.json xray/config.json
sudo docker-compose -f docker-compose-xray.yml up -d

echo "5️⃣ 等待启动..."
sleep 8

echo "6️⃣ 检查服务状态..."
echo "Xray 容器："
sudo docker ps | grep xray

echo "Xray 日志："
sudo docker logs xray-trojan 2>&1 | tail -8

echo "7️⃣ 清理日志并测试强制 HTTP/1.1..."
sudo truncate -s 0 /var/log/nginx/error.log
sleep 3

echo "测试 HTTP/1.1 WebSocket 连接："
curl -k -v \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --http1.1 \
    --connect-timeout 10 \
    https://ai.bless.top/bs 2>&1 | head -15

echo ""
echo "8️⃣ 检查错误日志..."
HTTP1_ERRORS=$(sudo tail -5 /var/log/nginx/error.log 2>/dev/null | grep "502\|Connection reset" || echo "")

if [ -z "$HTTP1_ERRORS" ]; then
    echo "✅ 强制 HTTP/1.1 方案成功！"
    echo ""
    echo "🎉 配置信息："
    echo "   - nginx：强制 HTTP/1.1 模式"
    echo "   - Xray：修复的 WebSocket 配置"  
    echo "   - Clash：clash/clash-config-vmess.yaml"
    echo ""
    echo "📋 Clash 配置："
    cat clash/clash-config-vmess.yaml
else
    echo "❌ 强制 HTTP/1.1 仍失败：$HTTP1_ERRORS"
    echo ""
    echo "🔧 尝试直接暴露方案..."
    
    # 停止当前服务
    sudo docker-compose -f docker-compose-xray.yml down
    sudo systemctl stop nginx
    
    # 启动直接暴露的 Xray
    echo "启动直接暴露的 Xray（修复的命令）..."
    sudo docker-compose -f docker-compose-direct.yml up -d
    
    sleep 8
    
    echo "检查直接暴露状态："
    sudo docker ps | grep xray
    sudo docker logs xray-direct 2>&1 | tail -8
    
    # 测试直接连接
    if curl -k -I https://ai.bless.top 2>/dev/null | head -1 | grep -q "200\|101"; then
        echo "✅ 直接暴露方案成功！"
        echo "⚠️  注意：nginx 已停止，Xray 直接监听 443 端口"
    else
        echo "❌ 直接暴露方案也失败"
        echo "恢复服务..."
        sudo docker-compose -f docker-compose-direct.yml down
        sudo systemctl start nginx
        sudo docker-compose -f docker-compose-xray.yml up -d
    fi
fi

echo ""
echo "📊 最终状态："
sudo docker ps | grep -E "(xray|nginx)" || echo "检查容器状态"
sudo systemctl status nginx --no-pager | head -3 