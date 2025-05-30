#!/bin/bash
set -e
DOMAIN="ai.bless.top"
CERT_DIR="$(cd "$(dirname "$0")/.." && pwd)/cert"
EMAIL="your-email@example.com" # 可修改为你的邮箱

# 安装 acme.sh
if ! command -v acme.sh >/dev/null 2>&1; then
  curl https://get.acme.sh | sh
  source ~/.bashrc || true
fi

~/.acme.sh/acme.sh --issue --webroot /var/www/ai.bless.top/ -d "$DOMAIN" --force --keylength ec-256 --server letsencrypt --accountemail "$EMAIL"
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
  --ecc \
  --key-file       "$CERT_DIR/$DOMAIN.key" \
  --fullchain-file "$CERT_DIR/fullchain.cer" \
  --reloadcmd     "systemctl restart trojan-go" 