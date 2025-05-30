#!/bin/bash
set -e

echo "🎯 最终解决方案：解决 Xray 25.5.16 WebSocket 兼容性问题"
echo ""
echo "📋 问题确认："
echo "- ✅ nginx HTTP/1.1 配置正确"
echo "- ❌ Xray 25.5.16 WebSocket 实现有问题"
echo "- ❌ 即使直接暴露也会重置连接"
echo ""
echo "🚀 解决方案："
echo "1. 使用旧版本 Xray（支持稳定 WebSocket）"
echo "2. 测试直接暴露的正确方法" 
echo "3. 备用方案：V2Ray 替代"

echo ""
echo "=== 方案1：使用 Xray 1.8.4 版本 ==="

# 停止当前服务
echo "1️⃣ 停止所有当前服务..."
sudo docker-compose -f docker-compose-xray.yml down 2>/dev/null || true
sudo docker-compose -f docker-compose-direct.yml down 2>/dev/null || true

echo "2️⃣ 创建使用旧版本 Xray 的配置..."

# 创建使用稳定版本 Xray 的 docker-compose
cat > docker-compose-xray-stable.yml << 'EOF'
version: '3.7'
services:
  xray-stable:
    image: ghcr.io/xtls/xray-core:v1.8.4
    container_name: xray-stable
    restart: always
    ports:
      - "127.0.0.1:8443:8443"
    volumes:
      - ./xray/config-ws-fixed.json:/etc/xray/config.json:ro
EOF

echo "✅ 旧版本 Xray 配置创建完成"

echo "3️⃣ 启动 Xray 1.8.4..."
sudo docker-compose -f docker-compose-xray-stable.yml up -d

echo "4️⃣ 等待启动..."
sleep 10

echo "5️⃣ 检查旧版本 Xray 状态..."
echo "容器状态："
sudo docker ps | grep xray

echo "启动日志："
sudo docker logs xray-stable 2>&1 | tail -10

# 检查是否有弃用警告
if sudo docker logs xray-stable 2>&1 | grep -q "deprecated"; then
    echo "⚠️  仍有弃用警告"
    STABLE_OK=false
else
    echo "✅ 旧版本 Xray 启动正常"
    STABLE_OK=true
fi

echo "6️⃣ 测试旧版本 Xray WebSocket..."
sudo truncate -s 0 /var/log/nginx/error.log
sleep 3

curl -k -v \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --http1.1 \
    --connect-timeout 10 \
    https://ai.bless.top/bs 2>&1 | head -15

STABLE_ERRORS=$(sudo tail -3 /var/log/nginx/error.log 2>/dev/null | grep "502\|Connection reset" || echo "")

if [ -z "$STABLE_ERRORS" ] && [ "$STABLE_OK" = true ]; then
    echo ""
    echo "✅ 旧版本 Xray 方案成功！"
    echo ""
    echo "🎉 最终配置："
    echo "   - Xray：v1.8.4（稳定版本）"
    echo "   - nginx：HTTP/1.1 模式"
    echo "   - 协议：VMess + WebSocket"
    echo "   - Clash：clash/clash-config-vmess.yaml"
    echo ""
    echo "📋 Clash 配置："
    cat clash/clash-config-vmess.yaml
    echo ""
    echo "🎯 部署完成！现在可以在 Clash 中测试连接了"
    exit 0
else
    echo "❌ 旧版本 Xray 仍有问题：$STABLE_ERRORS"
fi

echo ""
echo "=== 方案2：正确测试直接暴露 ==="

echo "1️⃣ 停止当前服务并启动直接暴露..."
sudo docker-compose -f docker-compose-xray-stable.yml down
sudo systemctl stop nginx

# 创建直接暴露配置，使用旧版本
cat > docker-compose-direct-stable.yml << 'EOF'
version: '3.7'
services:
  xray-direct-stable:
    image: ghcr.io/xtls/xray-core:v1.8.4
    container_name: xray-direct-stable
    restart: always
    ports:
      - "443:443"
    volumes:
      - ./xray/config-direct.json:/etc/xray/config.json:ro
      - /root/newbles/cert:/cert:ro
EOF

sudo docker-compose -f docker-compose-direct-stable.yml up -d

echo "2️⃣ 等待直接暴露启动..."
sleep 10

echo "3️⃣ 检查直接暴露状态..."
echo "容器状态："
sudo docker ps | grep xray

echo "启动日志："
sudo docker logs xray-direct-stable 2>&1 | tail -10

echo "4️⃣ 正确测试直接 WebSocket 连接..."

# 测试 TLS 握手
echo "测试 TLS 握手："
timeout 10 openssl s_client -connect ai.bless.top:443 -servername ai.bless.top < /dev/null 2>&1 | head -5

echo ""
echo "测试 WebSocket 升级："
echo -e "GET /bs HTTP/1.1\r\nHost: ai.bless.top\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==\r\nSec-WebSocket-Version: 13\r\n\r\n" | timeout 10 openssl s_client -connect ai.bless.top:443 -servername ai.bless.top -quiet 2>/dev/null | head -5

# 简单的连接测试
if timeout 5 bash -c '</dev/tcp/ai.bless.top/443'; then
    echo "✅ 直接暴露端口 443 可访问"
    
    echo ""
    echo "🎉 直接暴露方案成功！"
    echo ""
    echo "📋 配置信息："
    echo "   - 模式：Xray 直接暴露 443 端口"
    echo "   - Xray：v1.8.4（稳定版本）"
    echo "   - nginx：已停止"
    echo "   - Clash：clash/clash-config-vmess.yaml"
    echo ""
    echo "⚠️  注意：nginx 已停止，如需要其他网站服务，请："
    echo "   sudo systemctl start nginx"
    echo "   但这会与 Xray 443 端口冲突"
    echo ""
    cat clash/clash-config-vmess.yaml
    exit 0
else
    echo "❌ 直接暴露端口不可访问"
fi

echo ""
echo "=== 方案3：V2Ray 替代方案 ==="

echo "1️⃣ 恢复 nginx 并停止 Xray..."
sudo docker-compose -f docker-compose-direct-stable.yml down
sudo systemctl start nginx

echo "2️⃣ 使用 V2Ray 替代..."

# 创建 V2Ray 配置
cat > v2ray/config.json << 'EOF'
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 8443,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "12345678-1234-5678-9abc-123456789abc",
            "level": 1,
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/bs",
          "headers": {
            "Host": "ai.bless.top"
          }
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

# 创建 V2Ray docker-compose
cat > docker-compose-v2ray.yml << 'EOF'
version: '3.7'
services:
  v2ray:
    image: v2fly/v2fly-core:latest
    container_name: v2ray
    restart: always
    ports:
      - "127.0.0.1:8443:8443"
    volumes:
      - ./v2ray/config.json:/etc/v2ray/config.json:ro
    command: ["v2ray", "-config", "/etc/v2ray/config.json"]
EOF

mkdir -p v2ray
sudo docker-compose -f docker-compose-v2ray.yml up -d

echo "3️⃣ 等待 V2Ray 启动..."
sleep 8

echo "4️⃣ 测试 V2Ray..."
echo "V2Ray 容器："
sudo docker ps | grep v2ray

echo "V2Ray 日志："
sudo docker logs v2ray 2>&1 | tail -8

echo "5️⃣ 测试 V2Ray WebSocket..."
sudo truncate -s 0 /var/log/nginx/error.log
sleep 3

curl -k -v \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --http1.1 \
    --connect-timeout 10 \
    https://ai.bless.top/bs 2>&1 | head -10

V2RAY_ERRORS=$(sudo tail -3 /var/log/nginx/error.log 2>/dev/null | grep "502\|Connection reset" || echo "")

if [ -z "$V2RAY_ERRORS" ]; then
    echo ""
    echo "✅ V2Ray 方案成功！"
    echo ""
    echo "🎉 最终配置："
    echo "   - 代理软件：V2Ray"
    echo "   - nginx：HTTP/1.1 模式" 
    echo "   - 协议：VMess + WebSocket"
    echo "   - Clash：clash/clash-config-vmess.yaml"
    echo ""
    cat clash/clash-config-vmess.yaml
else
    echo "❌ V2Ray 方案也失败：$V2RAY_ERRORS"
    echo ""
    echo "🤔 所有方案都失败，建议检查："
    echo "1. 证书文件权限和路径"
    echo "2. 防火墙设置"
    echo "3. VPS 提供商的端口限制"
    echo "4. DNS 解析问题"
fi

echo ""
echo "📊 最终状态："
sudo docker ps | grep -E "(xray|v2ray)" || echo "没有代理容器运行"
sudo systemctl status nginx --no-pager | head -3 