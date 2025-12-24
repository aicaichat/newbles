# 服务器端一键更新 SSL 证书

## 🚀 快速执行（推荐）

### 方案1：最简单的一键命令（已有 acme.sh）

直接在服务器上执行以下命令：

```bash
acme.sh --renew -d ai.bless.top --force && nginx -s reload && echo "✅ 证书更新完成" && curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" https://ai.bless.top/bs
```

---

### 方案2：完整检查的一键命令

包含检查、更新、验证的完整流程：

```bash
DOMAIN="ai.bless.top" && CERT_DIR="/root/newbles/cert" && echo "🔄 开始更新证书..." && if command -v acme.sh &> /dev/null; then acme.sh --renew -d $DOMAIN --force && if [ -f "$CERT_DIR/fullchain.cer" ]; then echo "✅ 证书文件已更新" && openssl x509 -in "$CERT_DIR/fullchain.cer" -noout -enddate | cut -d= -f2 | xargs -I {} echo "📅 新证书过期时间: {}" && nginx -t && nginx -s reload && echo "✅ nginx 已重新加载" && sleep 2 && HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 https://$DOMAIN/bs 2>/dev/null || echo "000") && if [ "$HTTP_CODE" != "000" ]; then echo "✅ HTTPS 连接成功 (HTTP $HTTP_CODE)" && echo "🎉 证书更新完成！"; else echo "⚠️ HTTPS 连接失败，请检查配置"; fi; else echo "❌ 证书文件不存在"; fi; else echo "❌ acme.sh 未安装，请先安装: curl https://get.acme.sh | sh"; fi
```

---

### 方案3：多行命令（更易读）

```bash
# 更新证书
acme.sh --renew -d ai.bless.top --force

# 重新加载 nginx
nginx -t && nginx -s reload

# 验证证书
curl -v https://ai.bless.top/bs
```

---

### 方案4：下载并执行脚本

如果服务器上没有脚本，可以一键下载并执行：

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/vpn/main/scripts/update-ssl-cert.sh -o /tmp/update-ssl-cert.sh && chmod +x /tmp/update-ssl-cert.sh && bash /tmp/update-ssl-cert.sh
```

**注意**：需要将 `your-repo` 替换为实际的仓库地址，或者使用以下方式：

```bash
# 方式1：从本地复制脚本到服务器后执行
# 在本地执行：
cat scripts/update-ssl-cert.sh | ssh root@your-server "cat > /tmp/update-ssl-cert.sh && chmod +x /tmp/update-ssl-cert.sh && bash /tmp/update-ssl-cert.sh"

# 方式2：直接在服务器上创建脚本
cat > /tmp/update-ssl-cert.sh << 'EOF'
#!/bin/bash
set -e
DOMAIN="ai.bless.top"
CERT_DIR="/root/newbles/cert"
echo "🔄 更新证书..."
acme.sh --renew -d $DOMAIN --force
nginx -t && nginx -s reload
echo "✅ 完成"
EOF
chmod +x /tmp/update-ssl-cert.sh
bash /tmp/update-ssl-cert.sh
```

---

## 📋 分步执行（适合排查问题）

如果一键命令遇到问题，可以分步执行：

### 步骤1：检查 acme.sh

```bash
which acme.sh || echo "❌ acme.sh 未安装"
```

如果未安装，执行：

```bash
curl https://get.acme.sh | sh
source ~/.bashrc
```

### 步骤2：检查当前证书状态

```bash
openssl x509 -in /root/newbles/cert/fullchain.cer -noout -enddate 2>/dev/null || echo "证书文件不存在"
```

### 步骤3：更新证书

```bash
acme.sh --renew -d ai.bless.top --force
```

### 步骤4：验证证书文件

```bash
ls -lh /root/newbles/cert/fullchain.cer
openssl x509 -in /root/newbles/cert/fullchain.cer -noout -enddate
```

### 步骤5：测试 nginx 配置

```bash
nginx -t
```

### 步骤6：重新加载 nginx

```bash
nginx -s reload
# 或
systemctl reload nginx
```

### 步骤7：验证 HTTPS 连接

```bash
curl -v https://ai.bless.top/bs
```

---

## 🔧 常见问题处理

### 问题1：acme.sh 未安装

```bash
# 安装 acme.sh
curl https://get.acme.sh | sh
source ~/.bashrc

# 或使用 wget
wget -O - https://get.acme.sh | sh
source ~/.bashrc
```

### 问题2：证书续期失败

```bash
# 查看 acme.sh 日志
~/.acme.sh/acme.sh --list

# 强制重新申请证书（需要停止 nginx）
systemctl stop nginx
acme.sh --issue -d ai.bless.top --standalone
systemctl start nginx
```

### 问题3：nginx 配置错误

```bash
# 查看详细错误
nginx -t

# 检查证书路径配置
grep -r "ssl_certificate" /etc/nginx/conf.d/ai.bless.top.conf
```

### 问题4：证书文件路径不对

```bash
# 查找证书实际位置
find /root -name "fullchain.cer" 2>/dev/null
find /etc/nginx -name "*.crt" 2>/dev/null

# 检查 nginx 配置的证书路径
grep "ssl_certificate" /etc/nginx/conf.d/ai.bless.top.conf
```

---

## 🎯 推荐执行流程

### 最简单（推荐）

```bash
acme.sh --renew -d ai.bless.top --force && nginx -s reload
```

### 带验证

```bash
acme.sh --renew -d ai.bless.top --force && nginx -t && nginx -s reload && sleep 2 && curl -I https://ai.bless.top/bs
```

### 完整流程（包含检查）

```bash
echo "1️⃣ 检查证书..." && \
openssl x509 -in /root/newbles/cert/fullchain.cer -noout -enddate 2>/dev/null && \
echo "2️⃣ 更新证书..." && \
acme.sh --renew -d ai.bless.top --force && \
echo "3️⃣ 验证证书..." && \
openssl x509 -in /root/newbles/cert/fullchain.cer -noout -enddate && \
echo "4️⃣ 重新加载 nginx..." && \
nginx -t && nginx -s reload && \
echo "5️⃣ 测试连接..." && \
curl -I https://ai.bless.top/bs && \
echo "✅ 完成！"
```

---

## 📝 执行后验证

更新完成后，执行以下命令验证：

```bash
# 1. 查看证书过期时间
openssl x509 -in /root/newbles/cert/fullchain.cer -noout -enddate

# 2. 测试 HTTPS 连接
curl -v https://ai.bless.top/bs

# 3. 查看证书有效期（在线）
echo | openssl s_client -connect ai.bless.top:443 -servername ai.bless.top 2>/dev/null | openssl x509 -noout -dates
```

---

## ⚠️ 注意事项

1. **需要 root 权限**：证书更新需要 root 权限
2. **nginx 必须运行**：更新证书时 nginx 需要正常运行（除非使用 standalone 模式）
3. **域名解析**：确保 `ai.bless.top` 正确解析到服务器 IP
4. **防火墙**：确保 80 和 443 端口开放（acme.sh 验证需要）
5. **证书路径**：确认 nginx 配置的证书路径与实际证书文件路径一致

---

## 🚀 快速复制执行

**最简单的一键命令**（复制以下整行到服务器执行）：

```bash
acme.sh --renew -d ai.bless.top --force && nginx -s reload && echo "✅ 证书更新完成" && curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" https://ai.bless.top/bs
```

---

**总结：推荐使用方案1的最简单命令，如果遇到问题再使用分步执行方式排查。** 🔒

