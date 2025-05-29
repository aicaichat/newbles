#!/bin/bash
set -e

# 0. 创建 webroot 目录并写入测试文件
WEBROOT="/var/www/ai.bless.top/"
sudo mkdir -p "$WEBROOT/.well-known/acme-challenge/"
echo test | sudo tee "$WEBROOT/.well-known/acme-challenge/test.txt"
echo "已创建 webroot: $WEBROOT，并写入测试文件。请确保 nginx 配置正确，访问 http://ai.bless.top/.well-known/acme-challenge/test.txt 能看到 test。"

# 0.5 自动生成 nginx 配置并重载 nginx
NGINX_CONF="/etc/nginx/conf.d/ai.bless.top.conf"
sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name ai.bless.top;

    root /var/www/ai.bless.top/;

    location /.well-known/acme-challenge/ {
        alias /var/www/ai.bless.top/.well-known/acme-challenge/;
        try_files \$uri =404;
    }
}
EOF
sudo nginx -s reload
echo "nginx 配置已写入 $NGINX_CONF 并重载。"

# 1. 申请证书
bash ./scripts/apply-cert.sh

# 2. 启动 trojan-go 服务
sudo docker-compose up -d

# 3. 输出 Clash 配置路径
CLASH_CONFIG="$(cd "$(dirname "$0")/.." && pwd)/clash/clash-config.yaml"
echo "Clash 配置已生成：$CLASH_CONFIG" 