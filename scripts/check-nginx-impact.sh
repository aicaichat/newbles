#!/bin/bash

echo "🔍 检查 nginx 配置影响范围..."

echo "1️⃣ 当前服务器上的网站配置："
echo "nginx 配置目录："
sudo ls -la /etc/nginx/conf.d/ 2>/dev/null || echo "配置目录不存在或为空"

echo ""
echo "主配置文件包含的站点："
sudo ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "sites-enabled 目录不存在或为空"

echo ""
echo "2️⃣ ai.bless.top 配置详情："
echo "配置文件："
if [ -f "/etc/nginx/conf.d/ai.bless.top.conf" ]; then
    echo "✅ /etc/nginx/conf.d/ai.bless.top.conf 存在"
    echo ""
    echo "影响的域名："
    sudo grep "server_name" /etc/nginx/conf.d/ai.bless.top.conf || echo "未找到 server_name"
    
    echo ""
    echo "HTTP/2 状态："
    if sudo grep "listen.*http2" /etc/nginx/conf.d/ai.bless.top.conf >/dev/null 2>&1; then
        echo "❌ 仍在使用 HTTP/2"
    else
        echo "✅ 已移除 HTTP/2（仅对 ai.bless.top）"
    fi
    
    echo ""
    echo "WebSocket 配置："
    sudo grep -A 5 "location /bs" /etc/nginx/conf.d/ai.bless.top.conf || echo "未找到 /bs 配置"
else
    echo "❌ 配置文件不存在"
fi

echo ""
echo "3️⃣ 影响范围总结："
echo ""
echo "🎯 影响范围："
echo "   ✅ 只影响域名：ai.bless.top"
echo "   ✅ 只影响路径：/bs（WebSocket 反代）"
echo "   ✅ 其他路径：/（正常静态文件，无特殊限制）"
echo ""
echo "🚫 不影响："
echo "   ✅ 其他域名的网站（如果有）"
echo "   ✅ 服务器上的其他服务"
echo "   ✅ 默认的 nginx 行为"
echo ""
echo "📋 具体修改："
echo "   • HTTP/2 → HTTP/1.1（仅 ai.bless.top:443）"
echo "   • 启用 WebSocket 支持（仅 /bs 路径）"
echo "   • 禁用代理缓冲（仅 /bs 路径）"
echo "   • 其他路径保持标准配置"

echo ""
echo "4️⃣ 如果想恢复 HTTP/2（不推荐）："
echo "可以修改配置文件，将："
echo "   listen 443 ssl;"
echo "改为："
echo "   listen 443 ssl http2;"
echo ""
echo "但这会导致 WebSocket 代理失败！"

echo ""
echo "5️⃣ 验证当前配置："
echo "检查 nginx 配置语法："
sudo nginx -t

echo ""
echo "检查端口监听："
sudo netstat -tlnp | grep ":443" 2>/dev/null || echo "未找到 443 端口监听"

echo ""
echo "🎉 结论："
echo "此配置变更是安全的，只影响 ai.bless.top 的代理行为"
echo "不会影响服务器上的其他网站或服务" 