#!/bin/bash

# 从服务器端 V2Ray 配置导出 Clash 配置文件
# 使用方法：在服务器上执行 bash scripts/export-clash-config.sh

set -e

echo "🔄 正在从服务器配置生成 Clash 配置文件..."
echo ""

# 配置变量
V2RAY_CONFIG="/etc/v2ray/config.json"
V2RAY_CONTAINER="v2ray"
OUTPUT_FILE="clash-config-exported.yaml"

# 检查 V2Ray 配置是否存在
if [ -f "$V2RAY_CONFIG" ]; then
    CONFIG_SOURCE="file"
    CONFIG_PATH="$V2RAY_CONFIG"
    echo "✅ 找到 V2Ray 配置文件: $V2RAY_CONFIG"
elif docker ps | grep -q "$V2RAY_CONTAINER"; then
    CONFIG_SOURCE="container"
    CONFIG_PATH="docker exec $V2RAY_CONTAINER cat /etc/v2ray/config.json"
    echo "✅ 找到 V2Ray 容器: $V2RAY_CONTAINER"
else
    echo "❌ 未找到 V2Ray 配置或容器"
    echo "   请确保 V2Ray 已部署或配置文件存在"
    exit 1
fi

# 读取配置
if [ "$CONFIG_SOURCE" = "file" ]; then
    V2RAY_JSON=$(cat "$CONFIG_PATH")
else
    V2RAY_JSON=$(docker exec "$V2RAY_CONTAINER" cat /etc/v2ray/config.json)
fi

# 提取配置信息
echo "📋 正在提取配置信息..."

# 提取 UUID
UUID=$(echo "$V2RAY_JSON" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$UUID" ]; then
    echo "⚠️  无法从配置中提取 UUID，使用默认值"
    UUID="25c09e60-e69d-4b6b-b119-300180ef7fbb"
fi

# 提取 alterId
ALTER_ID=$(echo "$V2RAY_JSON" | grep -o '"alterId"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*' || echo "0")

# 提取 WebSocket 路径
WS_PATH=$(echo "$V2RAY_JSON" | grep -o '"path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$WS_PATH" ]; then
    WS_PATH="/bs"
fi

# 提取 Host
HOST=$(echo "$V2RAY_JSON" | grep -o '"Host"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
if [ -z "$HOST" ]; then
    # 尝试从 nginx 配置获取
    if [ -f "/etc/nginx/conf.d/ai.bless.top.conf" ]; then
        HOST=$(grep -o "server_name[[:space:]]*[^;]*" /etc/nginx/conf.d/ai.bless.top.conf | awk '{print $2}' | head -1)
    fi
    if [ -z "$HOST" ]; then
        HOST="ai.bless.top"
    fi
fi

# 获取服务器域名（从 nginx 配置或使用默认值）
DOMAIN="$HOST"
PORT=443

echo "✅ 配置信息提取完成："
echo "   UUID: $UUID"
echo "   AlterId: $ALTER_ID"
echo "   WebSocket 路径: $WS_PATH"
echo "   Host: $HOST"
echo "   服务器: $DOMAIN:$PORT"
echo ""

# 生成 Clash 配置
echo "📝 正在生成 Clash 配置文件..."

cat > "$OUTPUT_FILE" << EOF
port: 7890
socks-port: 7891
redir-port: 7892
mixed-port: 7890
allow-lan: true
mode: Rule
log-level: info
external-controller: 127.0.0.1:9090

proxies:
  - name: "VMess-$DOMAIN"
    type: vmess
    server: $DOMAIN
    port: $PORT
    uuid: $UUID
    alterId: $ALTER_ID
    cipher: auto
    tls: true
    skip-cert-verify: false
    servername: $HOST
    network: ws
    ws-opts:
      path: $WS_PATH
      headers:
        Host: $HOST

proxy-groups:
  - name: "Proxy"
    type: select
    proxies:
      - "VMess-$DOMAIN"
      - DIRECT

rules:
  - MATCH,Proxy
EOF

echo "✅ Clash 配置文件已生成: $OUTPUT_FILE"
echo ""
echo "📋 配置内容预览："
echo "---"
head -20 "$OUTPUT_FILE"
echo "..."
echo "---"
echo ""
echo "📤 下一步："
echo "   1. 检查配置文件: cat $OUTPUT_FILE"
echo "   2. 下载到本地: scp user@server:$OUTPUT_FILE ./"
echo "   3. 导入到 Clash 客户端"
echo ""

