#!/bin/bash

# V2Ray 部署脚本
echo "V2Ray 代理服务部署脚本"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，请先安装 Docker"
    exit 1
fi

# 检查 docker-compose 是否安装
if ! command -v docker-compose &> /dev/null; then
    echo "docker-compose 未安装，请先安装 docker-compose"
    exit 1
fi

# 创建必要的目录
mkdir -p v2ray client-configs

# 生成随机 UUID
UUID=$(cat /proc/sys/kernel/random/uuid)
echo "生成的 UUID: $UUID"

# 修改配置文件中的 UUID
sed -i "s/12345678-1234-5678-9abc-123456789abc/$UUID/g" v2ray/config.json
sed -i "s/12345678-1234-5678-9abc-123456789abc/$UUID/g" v2ray/config-direct.json
sed -i "s/12345678-1234-5678-9abc-123456789abc/$UUID/g" client-configs/v2ray-client.json

echo "UUID 已更新到配置文件"

# 选择部署模式
echo "请选择部署模式："
echo "1. V2Ray 后端模式（需要 nginx 反向代理）"
echo "2. V2Ray 直接暴露模式（直接监听 443 端口）"
read -p "请输入选择 (1 或 2): " choice

case $choice in
    1)
        echo "启动 V2Ray 后端模式..."
        docker-compose -f docker-compose-v2ray.yml up -d
        echo "V2Ray 后端模式已启动，监听 127.0.0.1:8443"
        ;;
    2)
        echo "启动 V2Ray 直接暴露模式..."
        docker-compose -f docker-compose-v2ray-direct.yml up -d
        echo "V2Ray 直接暴露模式已启动，监听 443 端口"
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo "部署完成！"
echo "客户端配置文件: client-configs/v2ray-client.json"
echo "UUID: $UUID" 