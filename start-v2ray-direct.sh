#!/bin/bash

echo "正在启动 v2ray 直接模式（监听 443 端口）..."

# 停止可能运行的容器
docker stop v2ray-direct 2>/dev/null || true
docker rm v2ray-direct 2>/dev/null || true

# 启动 v2ray 直接模式
docker run -d \
  --name v2ray-direct \
  --restart always \
  -p 443:443 \
  -v $(pwd)/v2ray/config-direct.json:/etc/v2ray/config.json:ro \
  -v /root/newbles/cert:/cert:ro \
  v2fly/v2fly-core:latest \
  v2ray run -config /etc/v2ray/config.json

echo "v2ray 直接模式启动完成！"
echo "配置信息："
echo "- 监听端口：443"
echo "- WebSocket 路径：/bs"
echo "- 域名：ai.bless.top"
echo "- UUID：25c09e60-e69d-4b6b-b119-300180ef7fbb"

# 检查容器状态
sleep 3
docker ps | grep v2ray-direct 