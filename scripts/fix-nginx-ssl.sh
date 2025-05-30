#!/bin/bash
set -e

echo "🔧 修复所有 nginx SSL 证书路径..."

echo "1️⃣ 查找所有包含错误证书路径的文件..."
echo "错误引用 'new.bless.top.key' 的文件："
sudo grep -r "new.bless.top.key" /etc/nginx/ || echo "未找到错误引用"

echo ""
echo "2️⃣ 查找所有 SSL 证书配置..."
echo "所有 SSL 证书配置："
sudo grep -r "ssl_certificate" /etc/nginx/ | grep -v "ssl_certificate_verify\|ssl_certificate_transparency"

echo ""
echo "3️⃣ 修复错误的证书路径..."

# 查找并修复所有包含错误路径的文件
NGINX_FILES=$(sudo find /etc/nginx/ -name "*.conf" -type f)
FIXED_COUNT=0

for FILE in $NGINX_FILES; do
    if sudo grep -q "new\.bless\.top\.key" "$FILE"; then
        echo "修复文件: $FILE"
        sudo cp "$FILE" "$FILE.backup"
        sudo sed -i 's/new\.bless\.top\.key/ai.bless.top.key/g' "$FILE"
        FIXED_COUNT=$((FIXED_COUNT + 1))
    fi
done

echo "已修复 $FIXED_COUNT 个文件"

echo ""
echo "4️⃣ 验证修复结果..."
echo "修复后的证书配置："
sudo grep -r "ssl_certificate.*\.key" /etc/nginx/ | grep -v backup

echo ""
echo "5️⃣ 测试 nginx 配置..."
if sudo nginx -t; then
    echo "✅ nginx 配置语法正确"
    
    echo ""
    echo "6️⃣ 重载 nginx..."
    sudo nginx -s reload
    echo "✅ nginx 配置已重载"
    
    echo ""
    echo "7️⃣ 测试 HTTPS 连接..."
    curl -k -I https://ai.bless.top 2>&1 | head -3 || echo "HTTPS 测试完成"
    
else
    echo "❌ nginx 配置仍有错误"
    echo "请手动检查以下文件："
    sudo find /etc/nginx/ -name "*.conf" -type f | head -5
    exit 1
fi

echo ""
echo "🎉 nginx SSL 配置修复完成！"
echo ""
echo "📋 下一步："
echo "bash scripts/test-complete.sh" 