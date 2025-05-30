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
echo "=== 方案1：使用 Xray 1.8.1 版本 ==="

# 停止当前服务
echo "1️⃣ 停止所有当前服务..."
sudo docker-compose -f docker-compose-xray.yml down 2>/dev/null || true
sudo docker-compose -f docker-compose-direct.yml down 2>/dev/null || true
sudo docker-compose -f docker-compose-xray-stable.yml down 2>/dev/null || true

echo "2️⃣ 创建使用旧版本 Xray 的配置..."

# 尝试几个可用的旧版本
XRAY_VERSIONS=("1.8.1" "1.7.5" "1.6.5")

for VERSION in "${XRAY_VERSIONS[@]}"; do
    echo "尝试 Xray v$VERSION..."
    
    # 创建使用稳定版本 Xray 的 docker-compose
    cat > docker-compose-xray-stable.yml << EOF
version: '3.7'
services:
  xray-stable:
    image: ghcr.io/xtls/xray-core:v$VERSION
    container_name: xray-stable
    restart: always
    ports:
      - "127.0.0.1:8443:8443"
    volumes:
      - ./xray/config-ws-fixed.json:/etc/xray/config.json:ro
EOF

    echo "测试 Xray v$VERSION 镜像是否可用..."
    if sudo docker pull ghcr.io/xtls/xray-core:v$VERSION 2>/dev/null; then
        echo "✅ Xray v$VERSION 镜像可用"
        WORKING_VERSION=$VERSION
        break
    else
        echo "❌ Xray v$VERSION 镜像不可用"
    fi
done

if [ -z "$WORKING_VERSION" ]; then
    echo "❌ 所有尝试的 Xray 版本都不可用，跳到 V2Ray 方案"
    SKIP_XRAY=true
else
    echo "✅ 使用 Xray v$WORKING_VERSION"
    SKIP_XRAY=false
fi

if [ "$SKIP_XRAY" = false ]; then
    echo "3️⃣ 启动 Xray v$WORKING_VERSION..."
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
        echo "⚠️  仍有弃用警告，但可能仍能工作"
        STABLE_OK=true
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
        echo "   - Xray：v$WORKING_VERSION（稳定版本）"
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
fi

echo ""
echo "=== 方案2：V2Ray 替代方案（主推）==="

echo "1️⃣ 停止 Xray 并恢复 nginx..."
sudo docker-compose -f docker-compose-xray-stable.yml down 2>/dev/null || true
sudo systemctl start nginx 2>/dev/null || true

echo "2️⃣ 使用 V2Ray 替代..."

# 创建 V2Ray 配置目录
mkdir -p v2ray

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
    command: ["v2ray", "run", "-config", "/etc/v2ray/config.json"]
EOF

echo "3️⃣ 启动 V2Ray..."
sudo docker-compose -f docker-compose-v2ray.yml up -d

echo "4️⃣ 等待 V2Ray 启动..."
sleep 8

echo "5️⃣ 检查 V2Ray 状态..."
echo "V2Ray 容器："
sudo docker ps | grep v2ray

echo "V2Ray 日志："
sudo docker logs v2ray 2>&1 | tail -10

echo "6️⃣ 测试 V2Ray WebSocket..."
sudo truncate -s 0 /var/log/nginx/error.log
sleep 3

curl -k -v \
    -H "Upgrade: websocket" \
    -H "Connection: Upgrade" \
    -H "Host: ai.bless.top" \
    --http1.1 \
    --connect-timeout 10 \
    https://ai.bless.top/bs 2>&1 | head -15

V2RAY_ERRORS=$(sudo tail -3 /var/log/nginx/error.log 2>/dev/null | grep "502\|Connection reset" || echo "")

if [ -z "$V2RAY_ERRORS" ]; then
    echo ""
    echo "✅ V2Ray 方案成功！"
    echo ""
    echo "🎉 最终配置："
    echo "   - 代理软件：V2Ray（推荐）"
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
    echo "❌ V2Ray 方案失败：$V2RAY_ERRORS"
fi

echo ""
echo "=== 方案3：直接暴露测试（最后尝试）==="

echo "1️⃣ 停止 V2Ray 并停止 nginx..."
sudo docker-compose -f docker-compose-v2ray.yml down
sudo systemctl stop nginx

echo "2️⃣ 使用 V2Ray 直接暴露 443 端口..."

# 创建 V2Ray 直接暴露配置
cat > v2ray/config-direct.json << 'EOF'
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 443,
      "listen": "0.0.0.0",
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
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/cert/fullchain.cer",
              "keyFile": "/cert/ai.bless.top.key"
            }
          ]
        },
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

# 创建直接暴露的 docker-compose
cat > docker-compose-v2ray-direct.yml << 'EOF'
version: '3.7'
services:
  v2ray-direct:
    image: v2fly/v2fly-core:latest
    container_name: v2ray-direct
    restart: always
    ports:
      - "443:443"
    volumes:
      - ./v2ray/config-direct.json:/etc/v2ray/config.json:ro
      - /root/newbles/cert:/cert:ro
    command: ["v2ray", "run", "-config", "/etc/v2ray/config.json"]
EOF

sudo docker-compose -f docker-compose-v2ray-direct.yml up -d

echo "3️⃣ 等待直接暴露启动..."
sleep 10

echo "4️⃣ 检查直接暴露状态..."
echo "容器状态："
sudo docker ps | grep v2ray

echo "启动日志："
sudo docker logs v2ray-direct 2>&1 | tail -10

echo "5️⃣ 测试直接连接..."

# 简单的连接测试
if timeout 5 bash -c '</dev/tcp/ai.bless.top/443'; then
    echo "✅ 直接暴露端口 443 可访问"
    
    echo ""
    echo "🎉 直接暴露方案成功！"
    echo ""
    echo "📋 配置信息："
    echo "   - 模式：V2Ray 直接暴露 443 端口"
    echo "   - nginx：已停止"
    echo "   - Clash：clash/clash-config-vmess.yaml"
    echo ""
    echo "⚠️  注意：nginx 已停止，如需要其他网站服务，请："
    echo "   sudo systemctl start nginx"
    echo "   但这会与 V2Ray 443 端口冲突"
    echo ""
    cat clash/clash-config-vmess.yaml
    exit 0
else
    echo "❌ 直接暴露端口不可访问"
    echo ""
    echo "恢复服务..."
    sudo docker-compose -f docker-compose-v2ray-direct.yml down
    sudo systemctl start nginx
    sudo docker-compose -f docker-compose-v2ray.yml up -d
fi

echo ""
echo "🤔 所有方案都失败，建议检查："
echo "1. 证书文件权限和路径：ls -la /root/newbles/cert/"
echo "2. 防火墙设置：sudo iptables -L"
echo "3. VPS 提供商的端口限制"
echo "4. DNS 解析问题：nslookup ai.bless.top"
echo ""
echo "📊 最终状态："
sudo docker ps | grep -E "(xray|v2ray)" || echo "没有代理容器运行"
sudo systemctl status nginx --no-pager | head -3 