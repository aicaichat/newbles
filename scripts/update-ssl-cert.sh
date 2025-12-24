#!/bin/bash

# SSL 证书更新脚本
# 用于更新 ai.bless.top 的 SSL 证书

set -e

DOMAIN="ai.bless.top"
CERT_DIR="/root/newbles/cert"
NGINX_CONF="/etc/nginx/conf.d/${DOMAIN}.conf"

echo "🔄 SSL 证书更新脚本"
echo "===================="
echo ""

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    echo "❌ 请使用 root 用户运行此脚本"
    echo "   使用: sudo $0"
    exit 1
fi

# 1. 检查 acme.sh 是否安装
echo "1️⃣ 检查 acme.sh..."
if ! command -v acme.sh &> /dev/null; then
    echo "❌ acme.sh 未安装"
    echo "   安装命令: curl https://get.acme.sh | sh"
    echo "   或: wget -O - https://get.acme.sh | sh"
    exit 1
fi
echo "✅ acme.sh 已安装"

# 2. 检查证书目录
echo ""
echo "2️⃣ 检查证书目录..."
if [ ! -d "$CERT_DIR" ]; then
    echo "⚠️  证书目录不存在: $CERT_DIR"
    echo "   创建目录..."
    mkdir -p "$CERT_DIR"
fi
echo "✅ 证书目录: $CERT_DIR"

# 3. 检查当前证书状态
echo ""
echo "3️⃣ 检查当前证书状态..."
if [ -f "$CERT_DIR/fullchain.cer" ]; then
    CERT_EXPIRY=$(openssl x509 -in "$CERT_DIR/fullchain.cer" -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -n "$CERT_EXPIRY" ]; then
        echo "📅 当前证书过期时间: $CERT_EXPIRY"
        
        # 计算剩余天数
        EXPIRY_EPOCH=$(date -d "$CERT_EXPIRY" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$CERT_EXPIRY" +%s 2>/dev/null || echo "0")
        CURRENT_EPOCH=$(date +%s)
        DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
        
        if [ $DAYS_LEFT -lt 0 ]; then
            echo "❌ 证书已过期！"
        elif [ $DAYS_LEFT -lt 30 ]; then
            echo "⚠️  证书将在 $DAYS_LEFT 天后过期"
        else
            echo "✅ 证书还有 $DAYS_LEFT 天过期"
        fi
    fi
else
    echo "⚠️  未找到证书文件"
fi

# 4. 更新证书
echo ""
echo "4️⃣ 更新证书..."
echo "   域名: $DOMAIN"

# 检查是否有现有证书
if acme.sh --list | grep -q "$DOMAIN"; then
    echo "   发现现有证书，尝试续期..."
    acme.sh --renew -d "$DOMAIN" --force
else
    echo "   未发现现有证书，申请新证书..."
    echo "   ⚠️  需要停止 nginx 或使用 webroot 模式"
    read -p "   是否继续？(y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "   操作已取消"
        exit 0
    fi
    
    # 尝试使用 standalone 模式（需要停止 nginx）
    echo "   使用 standalone 模式申请证书..."
    systemctl stop nginx 2>/dev/null || service nginx stop 2>/dev/null || true
    acme.sh --issue -d "$DOMAIN" --standalone
    systemctl start nginx 2>/dev/null || service nginx start 2>/dev/null || true
fi

# 5. 检查证书是否更新成功
echo ""
echo "5️⃣ 验证证书更新..."
if [ -f "$CERT_DIR/fullchain.cer" ]; then
    NEW_CERT_EXPIRY=$(openssl x509 -in "$CERT_DIR/fullchain.cer" -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -n "$NEW_CERT_EXPIRY" ]; then
        echo "✅ 证书更新成功"
        echo "📅 新证书过期时间: $NEW_CERT_EXPIRY"
    else
        echo "❌ 无法读取证书信息"
        exit 1
    fi
else
    echo "❌ 证书文件不存在"
    exit 1
fi

# 6. 检查 nginx 配置
echo ""
echo "6️⃣ 检查 nginx 配置..."
if [ -f "$NGINX_CONF" ]; then
    # 检查证书路径是否正确
    CERT_PATH=$(grep "ssl_certificate" "$NGINX_CONF" | head -1 | awk '{print $2}' | tr -d ';')
    if [ -n "$CERT_PATH" ] && [ -f "$CERT_PATH" ]; then
        echo "✅ nginx 证书路径正确: $CERT_PATH"
    else
        echo "⚠️  nginx 证书路径可能不正确"
        echo "   请检查: $NGINX_CONF"
    fi
else
    echo "⚠️  nginx 配置文件不存在: $NGINX_CONF"
fi

# 7. 测试 nginx 配置
echo ""
echo "7️⃣ 测试 nginx 配置..."
if nginx -t 2>/dev/null; then
    echo "✅ nginx 配置正确"
else
    echo "❌ nginx 配置错误"
    nginx -t
    exit 1
fi

# 8. 重新加载 nginx
echo ""
echo "8️⃣ 重新加载 nginx..."
if systemctl reload nginx 2>/dev/null || service nginx reload 2>/dev/null || nginx -s reload 2>/dev/null; then
    echo "✅ nginx 已重新加载"
else
    echo "⚠️  nginx 重新加载失败，尝试重启..."
    systemctl restart nginx 2>/dev/null || service nginx restart 2>/dev/null
fi

# 9. 验证证书
echo ""
echo "9️⃣ 验证证书..."
sleep 3

# 测试 HTTPS 连接
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://$DOMAIN/bs 2>/dev/null || echo "000")

if [ "$HTTP_CODE" != "000" ]; then
    echo "✅ HTTPS 连接成功 (HTTP $HTTP_CODE)"
    
    # 检查证书是否有效
    CERT_CHECK=$(echo | openssl s_client -connect $DOMAIN:443 -servername $DOMAIN 2>/dev/null | openssl x509 -noout -checkend 0 2>/dev/null && echo "valid" || echo "invalid")
    
    if [ "$CERT_CHECK" = "valid" ]; then
        echo "✅ SSL 证书有效"
    else
        echo "⚠️  SSL 证书可能仍有问题"
    fi
else
    echo "⚠️  HTTPS 连接失败，请检查："
    echo "   - nginx 是否正常运行"
    echo "   - 防火墙是否开放 443 端口"
    echo "   - 证书路径是否正确"
fi

echo ""
echo "===================="
echo "🎉 证书更新完成！"
echo ""
echo "📝 下一步："
echo "   1. 测试客户端连接"
echo "   2. 确认证书有效期"
echo "   3. 设置自动续期（可选）"
echo ""

