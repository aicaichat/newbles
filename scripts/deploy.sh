#!/bin/bash
set -e

# 1. 申请证书
bash ./scripts/apply-cert.sh

# 2. 启动 trojan-go 服务
sudo docker-compose up -d

# 3. 输出 Clash 配置路径
CLASH_CONFIG="$(cd "$(dirname "$0")/.." && pwd)/clash/clash-config.yaml"
echo "Clash 配置已生成：$CLASH_CONFIG" 