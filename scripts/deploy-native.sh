#!/bin/bash
set -e

echo "=== Trojan-Go 原生部署脚本 ==="

# 变量定义
TROJAN_VERSION="v0.10.6"
TROJAN_URL="https://github.com/p4gefau1t/trojan-go/releases/download/${TROJAN_VERSION}/trojan-go-linux-amd64.zip"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CERT_DIR="$PROJECT_DIR/cert"
CONFIG_SRC="$PROJECT_DIR/trojan-go/config.json"

echo "项目目录: $PROJECT_DIR"
echo "证书目录: $CERT_DIR"

# 1. 停止 Docker 服务（避免端口冲突）
echo "=== 停止 Docker 服务 ==="
if command -v docker-compose >/dev/null 2>&1; then
    cd "$PROJECT_DIR"
    sudo docker-compose down 2>/dev/null || true
    echo "Docker 服务已停止"
fi

# 2. 下载并安装 trojan-go
echo "=== 下载并安装 trojan-go ==="
cd /tmp
wget -O trojan-go.zip "$TROJAN_URL"
unzip -o trojan-go.zip
sudo cp trojan-go /usr/local/bin/
sudo chmod +x /usr/local/bin/trojan-go
echo "trojan-go 安装完成: $(/usr/local/bin/trojan-go -version 2>&1 || echo '已安装')"

# 3. 创建配置目录
echo "=== 创建配置目录 ==="
sudo mkdir -p /etc/trojan-go

# 4. 生成配置文件
echo "=== 生成配置文件 ==="
sudo tee /etc/trojan-go/config.json > /dev/null <<EOF
{
  "run_type": "server",
  "local_addr": "0.0.0.0",
  "local_port": 8443,
  "remote_addr": "127.0.0.1",
  "remote_port": 80,
  "password": [
    "mySecureBlessPassword123"
  ],
  "ssl": {
    "cert": "$CERT_DIR/fullchain.cer",
    "key": "$CERT_DIR/new.bless.top.key",
    "sni": "new.bless.top"
  }
}
EOF
echo "配置文件已生成: /etc/trojan-go/config.json"

# 5. 检查证书文件
echo "=== 检查证书文件 ==="
if [ ! -f "$CERT_DIR/fullchain.cer" ] || [ ! -f "$CERT_DIR/new.bless.top.key" ]; then
    echo "错误: 证书文件不存在，请先申请证书"
    echo "证书文件应位于:"
    echo "  - $CERT_DIR/fullchain.cer"
    echo "  - $CERT_DIR/new.bless.top.key"
    exit 1
fi
echo "证书文件检查完成"

# 6. 创建 systemd 服务
echo "=== 创建 systemd 服务 ==="
sudo tee /etc/systemd/system/trojan-go.service > /dev/null <<EOF
[Unit]
Description=Trojan-Go
Documentation=https://github.com/p4gefau1t/trojan-go
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/trojan-go -config /etc/trojan-go/config.json
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# 7. 启动服务
echo "=== 启动 trojan-go 服务 ==="
sudo systemctl daemon-reload
sudo systemctl enable trojan-go
sudo systemctl stop trojan-go 2>/dev/null || true
sudo systemctl start trojan-go

# 8. 检查服务状态
echo "=== 检查服务状态 ==="
sleep 3
if sudo systemctl is-active --quiet trojan-go; then
    echo "✅ trojan-go 服务启动成功"
    sudo systemctl status trojan-go --no-pager -l
else
    echo "❌ trojan-go 服务启动失败，查看日志:"
    sudo journalctl -u trojan-go --no-pager -n 20
    exit 1
fi

# 9. 更新 acme.sh 重载命令
echo "=== 更新证书重载命令 ==="
if [ -f "$PROJECT_DIR/scripts/apply-cert.sh" ]; then
    sed -i 's/docker restart trojan-go/systemctl restart trojan-go/' "$PROJECT_DIR/scripts/apply-cert.sh"
    echo "已更新证书重载命令为 systemctl restart trojan-go"
fi

# 10. 输出 Clash 配置
echo "=== Clash 配置信息 ==="
CLASH_CONFIG="$PROJECT_DIR/clash/clash-config.yaml"
echo "Clash 配置文件位置: $CLASH_CONFIG"
echo ""
echo "如需查看实时日志:"
echo "  sudo journalctl -u trojan-go -f"
echo ""
echo "服务管理命令:"
echo "  启动: sudo systemctl start trojan-go"
echo "  停止: sudo systemctl stop trojan-go"
echo "  重启: sudo systemctl restart trojan-go"
echo "  状态: sudo systemctl status trojan-go"
echo ""
echo "=== 部署完成 ===" 