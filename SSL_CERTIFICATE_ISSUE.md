# SSL 证书过期问题

## 🚀 快速修复（一键执行）

**最简单的一键命令**（复制到服务器执行）：

```bash
acme.sh --renew -d ai.bless.top --force && nginx -s reload && echo "✅ 证书更新完成" && curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" https://ai.bless.top/bs
```

📖 **更多一键执行方案**：请查看 [SERVER_ONE_CLICK_UPDATE.md](./SERVER_ONE_CLICK_UPDATE.md)

---

## 🚨 问题诊断

### 错误信息
```
SSL certificate problem: certificate has expired
```

### 问题原因
服务器的 SSL 证书已过期，需要更新证书。

---

## 🔧 解决方案

### 方案1：更新服务器证书（推荐）

在服务器上执行以下步骤：

#### 1. 检查证书过期时间

```bash
# 查看证书信息
openssl x509 -in /root/newbles/cert/fullchain.cer -text -noout | grep -A 2 "Validity"

# 或查看 nginx 使用的证书
openssl x509 -in /etc/nginx/ssl/ai.bless.top.crt -text -noout | grep -A 2 "Validity"
```

#### 2. 使用 acme.sh 更新证书

```bash
# 如果使用 acme.sh
acme.sh --renew -d ai.bless.top --force

# 或重新申请证书
acme.sh --issue -d ai.bless.top --standalone
```

#### 3. 重新加载 nginx

```bash
# 测试 nginx 配置
nginx -t

# 重新加载 nginx（不中断服务）
nginx -s reload

# 或重启 nginx
systemctl reload nginx
```

#### 4. 验证证书更新

```bash
# 在服务器上测试
curl -v https://ai.bless.top/bs

# 查看新证书信息
openssl s_client -connect ai.bless.top:443 -servername ai.bless.top < /dev/null 2>/dev/null | openssl x509 -noout -dates
```

---

### 方案2：临时跳过证书验证（仅用于测试）

**⚠️ 警告：仅用于测试，不要在生产环境使用！**

#### 使用 curl 测试（跳过证书验证）

```bash
# 跳过证书验证
curl -k -v https://ai.bless.top/bs

# 或使用 --insecure 参数
curl --insecure -v https://ai.bless.top/bs
```

#### Clash 配置临时修改

如果只是测试，可以临时修改 Clash 配置：

```yaml
proxies:
  - name: "VMess-ai.bless.top"
    type: vmess
    server: ai.bless.top
    port: 443
    uuid: 25c09e60-e69d-4b6b-b119-300180ef7fbb
    alterId: 0
    cipher: auto
    tls: true
    skip-cert-verify: true    # ⚠️ 临时设置为 true（跳过证书验证）
    servername: ai.bless.top
    network: ws
    ws-opts:
      path: /bs
      headers:
        Host: ai.bless.top
```

**注意**：`skip-cert-verify: true` 会跳过证书验证，存在安全风险，仅用于测试。

---

## 📋 证书更新脚本

创建一个自动更新证书的脚本：

```bash
#!/bin/bash
# 更新 SSL 证书脚本

DOMAIN="ai.bless.top"
CERT_DIR="/root/newbles/cert"
NGINX_CONF="/etc/nginx/conf.d/${DOMAIN}.conf"

echo "🔄 开始更新 SSL 证书..."

# 1. 检查 acme.sh 是否安装
if ! command -v acme.sh &> /dev/null; then
    echo "❌ acme.sh 未安装"
    echo "安装命令: curl https://get.acme.sh | sh"
    exit 1
fi

# 2. 更新证书
echo "📝 更新证书..."
acme.sh --renew -d $DOMAIN --force

# 3. 检查证书是否更新成功
if [ -f "$CERT_DIR/fullchain.cer" ]; then
    CERT_EXPIRY=$(openssl x509 -in $CERT_DIR/fullchain.cer -noout -enddate | cut -d= -f2)
    echo "✅ 证书更新成功"
    echo "📅 证书过期时间: $CERT_EXPIRY"
else
    echo "❌ 证书文件不存在"
    exit 1
fi

# 4. 重新加载 nginx
echo "🔄 重新加载 nginx..."
if nginx -t; then
    nginx -s reload
    echo "✅ nginx 已重新加载"
else
    echo "❌ nginx 配置错误"
    exit 1
fi

# 5. 验证证书
echo "🔍 验证证书..."
sleep 2
if curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/bs | grep -q "200\|400\|404"; then
    echo "✅ 证书验证成功"
else
    echo "⚠️  证书验证失败，请检查配置"
fi

echo "🎉 证书更新完成！"
```

保存为 `update-cert.sh`，然后运行：
```bash
chmod +x update-cert.sh
sudo ./update-cert.sh
```

---

## 🔍 诊断命令

### 检查证书状态

```bash
# 查看证书详细信息
openssl s_client -connect ai.bless.top:443 -servername ai.bless.top < /dev/null 2>/dev/null | openssl x509 -noout -text

# 查看证书过期时间
openssl s_client -connect ai.bless.top:443 -servername ai.bless.top < /dev/null 2>/dev/null | openssl x509 -noout -dates

# 查看证书有效期剩余天数
echo | openssl s_client -connect ai.bless.top:443 -servername ai.bless.top 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2 | xargs -I {} date -d {} +%s | xargs -I {} bash -c 'echo $(( ({} - $(date +%s)) / 86400 )) days remaining'
```

### 检查 nginx 证书配置

```bash
# 查看 nginx 证书路径
grep -r "ssl_certificate" /etc/nginx/

# 检查证书文件是否存在
ls -la /root/newbles/cert/
ls -la /etc/nginx/ssl/
```

---

## ⚠️ 重要提示

1. **证书过期影响**：
   - 客户端连接会失败（证书验证错误）
   - 浏览器会显示安全警告
   - 代理可能无法正常工作

2. **更新证书后**：
   - 需要重新加载 nginx
   - 客户端可能需要清除缓存
   - 建议测试连接确保正常

3. **预防措施**：
   - 设置证书自动续期
   - 监控证书过期时间
   - 提前 30 天更新证书

---

## 🚀 快速修复步骤

```bash
# 在服务器上执行
cd /root/newbles

# 1. 更新证书
acme.sh --renew -d ai.bless.top --force

# 2. 重新加载 nginx
nginx -s reload

# 3. 验证
curl -v https://ai.bless.top/bs
```

---

## 📝 客户端配置建议

### 临时方案（测试用）

如果证书暂时无法更新，可以临时使用：

```yaml
skip-cert-verify: true  # ⚠️ 仅用于测试
```

### 正式方案

证书更新后，恢复为：

```yaml
skip-cert-verify: false  # ✅ 正常使用
```

---

**总结：服务器 SSL 证书已过期，需要在服务器上更新证书。更新后重新加载 nginx 即可恢复正常。** 🔒

