#!/bin/bash
set -e

echo "🔗 完整链路测试：nginx → Xray → 代理"

echo "1️⃣ 测试 Xray 本地连接..."
echo "本地 Xray 状态："
curl -v --connect-timeout 3 http://127.0.0.1:8443 2>&1 | head -3 || echo "Xray 本地连接测试完成"

echo ""
echo "2️⃣ 检查 nginx SSL 配置..."

# 检查证书文件
echo "证书文件状态："
ls -la /root/newbles/cert/fullchain.cer /root/newbles/cert/ai.bless.top.key

# 检查证书域名
echo "证书域名："
openssl x509 -in /root/newbles/cert/fullchain.cer -subject -noout

# 检查 nginx 配置
echo "nginx 证书配置："
grep ssl_certificate /etc/nginx/conf.d/ai.bless.top.conf

echo ""
echo "3️⃣ 测试 nginx 配置..."
if sudo nginx -t; then
    echo "✅ nginx 配置语法正确"
    sudo nginx -s reload
    echo "✅ nginx 配置已重载"
else
    echo "❌ nginx 配置有错误"
    exit 1
fi

echo ""
echo "4️⃣ 测试 HTTPS 连接（跳过证书验证）..."
curl -k -I https://ai.bless.top 2>/dev/null | head -3 || echo "HTTPS 基础连接测试完成"

echo ""
echo "5️⃣ 测试 WebSocket 反代（跳过证书验证）..."
curl -k -v \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --connect-timeout 5 \
    https://ai.bless.top/bs 2>&1 | head -10 || echo "WebSocket 反代测试完成"

echo ""
echo "6️⃣ 检查完整服务状态..."
echo "Docker 容器："
sudo docker ps | grep xray

echo "nginx 进程："
sudo systemctl status nginx --no-pager | head -3

echo "端口监听："
sudo netstat -tlnp | grep -E "(443|8443)"

echo ""
echo "🎯 下一步测试："
echo "1. 在 Clash 中导入配置：clash/clash-config.yaml"
echo "2. 选择节点：Trojan-ai.bless.top"
echo "3. 测试科学上网"

echo ""
echo "📊 Clash 配置确认："
cat clash/clash-config.yaml

echo ""
echo "🔧 如果 SSL 证书问题仍然存在，可以："
echo "1. 重新申请证书：bash scripts/apply-cert.sh"
echo "2. 或者暂时跳过证书验证测试功能" 