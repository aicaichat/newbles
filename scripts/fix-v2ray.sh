#!/bin/bash

echo "V2Ray 修复脚本"

# 停止现有容器
echo "停止现有 V2Ray 容器..."
sudo docker stop v2ray v2ray-direct 2>/dev/null || true
sudo docker rm v2ray v2ray-direct 2>/dev/null || true

# 清理 Docker 系统
echo "清理 Docker 缓存..."
sudo docker system prune -f

# 拉取最新镜像
echo "拉取最新 V2Ray 镜像..."
sudo docker pull v2fly/v2fly-core:latest

# 检查配置文件
echo "检查配置文件..."
if [ ! -f "./v2ray/config.json" ]; then
    echo "错误: v2ray/config.json 不存在"
    exit 1
fi

# 验证 JSON 格式
echo "验证配置文件格式..."
if ! python3 -m json.tool v2ray/config.json > /dev/null 2>&1; then
    echo "错误: v2ray/config.json 格式无效"
    exit 1
fi

echo "配置文件验证通过"

# 重新启动容器
echo "启动 V2Ray 容器..."
sudo docker-compose -f docker-compose-v2ray.yml up -d

# 等待容器启动
sleep 5

# 检查容器状态
echo "检查容器状态..."
sudo docker ps | grep v2ray

echo "检查容器日志..."
sudo docker logs v2ray --tail=10

echo "检查端口监听..."
sudo netstat -tlnp | grep 8443

echo "修复完成！" 