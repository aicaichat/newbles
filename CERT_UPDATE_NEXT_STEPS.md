# 证书更新后的后续步骤

## ✅ 证书已更新成功

根据 acme.sh 的输出，证书已成功更新并安装到：
- 证书文件：`/root/newbles/cert/fullchain.rsa.cer`
- 密钥文件：`/root/newbles/cert/ai.bless.top.rsa.key`

---

## ⚠️ 重要：需要重新加载 Nginx

acme.sh 自动执行的是 `systemctl restart trojan-go`，但实际使用的是 **V2Ray + Nginx**，所以需要手动重新加载 Nginx。

---

## 🚀 立即执行（一键命令）

在服务器上执行以下命令：

```bash
# 1. 检查证书文件是否存在
ls -lh /root/newbles/cert/fullchain.rsa.cer /root/newbles/cert/ai.bless.top.rsa.key

# 2. 检查 nginx 配置使用的证书路径
grep -E "ssl_certificate" /etc/nginx/conf.d/ai.bless.top.conf

# 3. 如果文件名不匹配，创建符号链接或复制文件
# 方式A：创建符号链接（推荐）
ln -sf /root/newbles/cert/fullchain.rsa.cer /root/newbles/cert/fullchain.cer
ln -sf /root/newbles/cert/ai.bless.top.rsa.key /root/newbles/cert/ai.bless.top.key

# 方式B：或者直接复制文件
# cp /root/newbles/cert/fullchain.rsa.cer /root/newbles/cert/fullchain.cer
# cp /root/newbles/cert/ai.bless.top.rsa.key /root/newbles/cert/ai.bless.top.key

# 4. 测试 nginx 配置
nginx -t

# 5. 重新加载 nginx
nginx -s reload

# 6. 验证证书
curl -v https://ai.bless.top/bs
```

---

## 📋 完整一键执行命令

```bash
# 检查并修复证书文件链接，然后重新加载 nginx
ls -lh /root/newbles/cert/fullchain.rsa.cer /root/newbles/cert/ai.bless.top.rsa.key && \
ln -sf /root/newbles/cert/fullchain.rsa.cer /root/newbles/cert/fullchain.cer && \
ln -sf /root/newbles/cert/ai.bless.top.rsa.key /root/newbles/cert/ai.bless.top.key && \
nginx -t && nginx -s reload && \
echo "✅ Nginx 已重新加载" && \
sleep 2 && \
curl -I https://ai.bless.top/bs && \
echo "✅ 证书更新完成！"
```

---

## 🔍 检查证书路径

### 1. 查看 nginx 配置的证书路径

```bash
grep -E "ssl_certificate" /etc/nginx/conf.d/ai.bless.top.conf
```

预期输出类似：
```
ssl_certificate /root/newbles/cert/fullchain.cer;
ssl_certificate_key /root/newbles/cert/ai.bless.top.key;
```

### 2. 查看实际证书文件

```bash
ls -lh /root/newbles/cert/
```

### 3. 如果文件名不匹配

如果 nginx 配置使用的是 `fullchain.cer`，但实际文件是 `fullchain.rsa.cer`，需要创建符号链接：

```bash
# 创建符号链接（推荐，节省空间）
ln -sf /root/newbles/cert/fullchain.rsa.cer /root/newbles/cert/fullchain.cer
ln -sf /root/newbles/cert/ai.bless.top.rsa.key /root/newbles/cert/ai.bless.top.key
```

---

## ✅ 验证步骤

### 1. 验证证书文件

```bash
# 查看证书过期时间
openssl x509 -in /root/newbles/cert/fullchain.rsa.cer -noout -enddate
```

### 2. 验证 nginx 配置

```bash
nginx -t
```

### 3. 重新加载 nginx

```bash
nginx -s reload
# 或
systemctl reload nginx
```

### 4. 测试 HTTPS 连接

```bash
# 测试连接
curl -v https://ai.bless.top/bs

# 查看证书信息
echo | openssl s_client -connect ai.bless.top:443 -servername ai.bless.top 2>/dev/null | openssl x509 -noout -dates
```

---

## 🔧 更新 acme.sh 的 reload 命令

为了避免下次更新证书时自动重启 trojan-go，可以更新 acme.sh 的安装配置：

```bash
# 查看当前安装配置
acme.sh --install-cert -d ai.bless.top --list

# 更新 reload 命令为 nginx
acme.sh --install-cert -d ai.bless.top \
  --key-file /root/newbles/cert/ai.bless.top.rsa.key \
  --fullchain-file /root/newbles/cert/fullchain.rsa.cer \
  --reloadcmd "nginx -s reload"
```

---

## 📝 快速检查清单

- [ ] 证书文件已更新（`/root/newbles/cert/fullchain.rsa.cer`）
- [ ] 证书文件链接正确（如果 nginx 使用不同文件名）
- [ ] nginx 配置测试通过（`nginx -t`）
- [ ] nginx 已重新加载（`nginx -s reload`）
- [ ] HTTPS 连接测试成功（`curl -v https://ai.bless.top/bs`）
- [ ] 证书有效期已更新（检查过期时间）

---

## 🎯 推荐执行顺序

1. **检查证书文件**：确认文件已更新
2. **检查 nginx 配置**：确认证书路径
3. **创建符号链接**：如果文件名不匹配
4. **重新加载 nginx**：应用新证书
5. **验证连接**：测试 HTTPS 是否正常

---

**总结：证书已更新，现在需要重新加载 nginx 才能生效。如果文件名不匹配，需要创建符号链接。** 🔒

