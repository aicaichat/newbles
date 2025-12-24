# SSL 证书快速修复

## 🚀 一键执行命令

直接在服务器上执行（复制整行）：

```bash
acme.sh --renew -d ai.bless.top --force && nginx -s reload && echo "✅ 证书更新完成" && curl -s -o /dev/null -w "HTTP状态码: %{http_code}\n" https://ai.bless.top/bs
```

---

## 📋 如果上面的命令失败

### 步骤1：检查 acme.sh 是否安装

```bash
which acme.sh || (curl https://get.acme.sh | sh && source ~/.bashrc)
```

### 步骤2：更新证书

```bash
acme.sh --renew -d ai.bless.top --force
```

### 步骤3：重新加载 nginx

```bash
nginx -t && nginx -s reload
```

### 步骤4：验证

```bash
curl -v https://ai.bless.top/bs
```

---

---

## ⚠️ 证书更新后的后续步骤

如果证书已更新（acme.sh 显示成功），但 nginx 仍在使用旧证书，执行：

```bash
# 检查并修复证书文件链接，然后重新加载 nginx
ls -lh /root/newbles/cert/fullchain.rsa.cer /root/newbles/cert/ai.bless.top.rsa.key && \
ln -sf /root/newbles/cert/fullchain.rsa.cer /root/newbles/cert/fullchain.cer && \
ln -sf /root/newbles/cert/ai.bless.top.rsa.key /root/newbles/cert/ai.bless.top.key && \
nginx -t && nginx -s reload && \
echo "✅ Nginx 已重新加载" && \
sleep 2 && \
curl -I https://ai.bless.top/bs
```

**说明**：acme.sh 安装的证书文件名可能是 `fullchain.rsa.cer`，但 nginx 配置可能使用 `fullchain.cer`，需要创建符号链接。

---

## 📖 详细文档

- 证书更新后的完整步骤：[CERT_UPDATE_NEXT_STEPS.md](./CERT_UPDATE_NEXT_STEPS.md)
- 完整一键执行方案：[SERVER_ONE_CLICK_UPDATE.md](./SERVER_ONE_CLICK_UPDATE.md)
- 问题诊断和解决方案：[SSL_CERTIFICATE_ISSUE.md](./SSL_CERTIFICATE_ISSUE.md)

