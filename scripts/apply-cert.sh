#!/bin/bash
set -e
DOMAIN="new.bless.top"
CERT_DIR="$(cd "$(dirname "$0")/.." && pwd)/cert"
EMAIL="your@example.com" # 可修改为你的邮箱

# 安装 acme.sh
if ! command -v acme.sh >/dev/null 2>&1; then
  curl https://get.acme.sh | sh
  source ~/.bashrc || true
fi

~/.acme.sh/acme.sh --issue --webroot /var/www/new.bless.top/ -d "$DOMAIN" --force --keylength ec-256 --server letsencrypt --accountemail "$EMAIL"
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
  --ecc \
  --key-file       "$CERT_DIR/$DOMAIN.key" \
  --fullchain-file "$CERT_DIR/fullchain.cer" \
  --reloadcmd     "docker restart trojan-go" 