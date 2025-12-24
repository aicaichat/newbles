#!/bin/bash

# V2Ray 代理服务部署脚本 - 生产版本
echo "=== V2Ray 代理服务部署脚本 ==="

# 检查运行环境
if [[ $EUID -eq 0 ]]; then
   echo "建议使用普通用户运行此脚本"
fi

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装，请先安装 Docker"
    echo "安装命令：curl -fsSL https://get.docker.com | sh"
    exit 1
fi

# 检查 docker-compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose 未安装，请先安装 docker-compose"
    exit 1
fi

echo "✅ Docker 环境检查通过"

# 创建必要的目录
mkdir -p v2ray client-configs logs

# 检查是否已有 UUID 配置
EXISTING_UUID=$(grep -o '"id": "[^"]*"' v2ray/config.json 2>/dev/null | cut -d'"' -f4)

if [[ -n "$EXISTING_UUID" && "$EXISTING_UUID" != "25c09e60-e69d-4b6b-b119-300180ef7fbb" ]]; then
    echo "🔍 发现现有 UUID: $EXISTING_UUID"
    read -p "是否保留现有 UUID？(y/n): " keep_uuid
    if [[ $keep_uuid == "y" || $keep_uuid == "Y" ]]; then
        UUID="$EXISTING_UUID"
        echo "✅ 保留现有 UUID"
    else
        # 生成新的随机 UUID
        UUID=$(cat /proc/sys/kernel/random/uuid)
        echo "🆕 生成新的 UUID: $UUID"
    fi
else
    # 生成新的随机 UUID
    UUID=$(cat /proc/sys/kernel/random/uuid)
    echo "🆕 生成新的 UUID: $UUID"
fi

# 更新配置文件中的 UUID
echo "📝 更新配置文件..."
if [[ -f v2ray/config.json ]]; then
    sed -i "s/\"id\": \"[^\"]*\"/\"id\": \"$UUID\"/g" v2ray/config.json
fi

if [[ -f v2ray/config-direct.json ]]; then
    sed -i "s/\"id\": \"[^\"]*\"/\"id\": \"$UUID\"/g" v2ray/config-direct.json
fi

if [[ -f client-configs/v2ray-client.json ]]; then
    sed -i "s/\"id\": \"[^\"]*\"/\"id\": \"$UUID\"/g" client-configs/v2ray-client.json
fi

if [[ -f client-configs/clash-config.yaml ]]; then
    sed -i "s/uuid: .*/uuid: $UUID/g" client-configs/clash-config.yaml
fi

echo "✅ UUID 已更新到所有配置文件"

# 选择部署模式
echo ""
echo "📋 请选择部署模式："
echo "1. V2Ray 后端模式 (推荐 - 需要 nginx 反向代理)"
echo "2. V2Ray 直接暴露模式 (直接监听 443 端口)"
read -p "请输入选择 (1 或 2): " choice

case $choice in
    1)
        echo "🚀 启动 V2Ray 后端模式..."
        docker-compose -f docker-compose-v2ray.yml pull
        docker-compose -f docker-compose-v2ray.yml up -d
        
        # 等待服务启动
        echo "⏳ 等待服务启动..."
        sleep 5
        
        # 检查服务状态
        if docker ps | grep -q v2ray; then
            echo "✅ V2Ray 后端模式已启动"
            echo "📍 监听地址: 127.0.0.1:8443"
            echo "📝 需要配置 nginx 反向代理到此端口"
        else
            echo "❌ V2Ray 启动失败，请检查日志"
            docker logs v2ray --tail=10
            exit 1
        fi
        ;;
    2)
        echo "🚀 启动 V2Ray 直接暴露模式..."
        echo "⚠️  注意：此模式会占用 443 端口，请确保停止其他使用此端口的服务"
        read -p "继续？(y/n): " confirm
        if [[ $confirm != "y" && $confirm != "Y" ]]; then
            echo "操作已取消"
            exit 0
        fi
        
        docker-compose -f docker-compose-v2ray-direct.yml pull
        docker-compose -f docker-compose-v2ray-direct.yml up -d
        
        sleep 5
        
        if docker ps | grep -q v2ray; then
            echo "✅ V2Ray 直接暴露模式已启动"
            echo "📍 监听地址: 0.0.0.0:443"
        else
            echo "❌ V2Ray 启动失败，请检查日志"
            docker logs v2ray-direct --tail=10
            exit 1
        fi
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

# 生成客户端配置摘要
echo ""
echo "🎉 部署完成！"
echo ""
echo "📋 配置信息摘要："
echo "================================"
echo "服务器地址: ai.bless.top"
echo "端口: 443"
echo "UUID: $UUID"
echo "协议: VMess"
echo "传输: WebSocket"
echo "路径: /bs"
echo "TLS: 启用"
echo "================================"
echo ""
echo "📁 客户端配置文件："
echo "- V2Ray 格式: client-configs/v2ray-client.json"
echo "- Clash 格式: client-configs/clash-config.yaml"
echo "- 分享链接: client-configs/vmess-link.txt"
echo ""
echo "💡 下一步："
echo "1. 下载对应的客户端配置文件"
echo "2. 导入到你的 V2Ray 客户端"
echo "3. 测试连接"
echo ""

# 保存配置信息
cat > deployment-info.txt << EOF
V2Ray 部署信息
================================
部署时间: $(date)
UUID: $UUID
服务器: ai.bless.top:443
协议: VMess over WebSocket + TLS
路径: /bs
本地代理端口: 1080 (SOCKS5)
================================
EOF

echo "📝 部署信息已保存到 deployment-info.txt"

# 显示服务状态
echo ""
echo "🔍 服务状态检查："
docker ps | grep v2ray
echo ""
echo "📊 如需查看日志，运行："
echo "docker logs v2ray --tail=20" 