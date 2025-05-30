# 证书目录说明

## ⚠️ 重要安全提醒

**此目录用于存放 SSL 证书文件，但所有证书文件已被 `.gitignore` 忽略，不会提交到 git 仓库。**

## 目录用途

这个目录主要用于开发和测试时的证书存放，但在实际部署中：

- **实际证书路径**: `/root/newbles/cert/`
- **本目录**: 仅用于开发时的配置参考

## 证书文件

实际部署时需要的证书文件：

```
/root/newbles/cert/
├── fullchain.cer          # SSL 证书链文件
└── ai.bless.top.key       # 私钥文件
```

## 部署说明

1. **证书申请**: 使用 `scripts/apply-cert.sh` 申请证书
2. **配置路径**: nginx 和相关配置都指向 `/root/newbles/cert/`
3. **权限设置**: 
   ```bash
   chmod 600 /root/newbles/cert/ai.bless.top.key
   chmod 644 /root/newbles/cert/fullchain.cer
   ```

## 安全提醒

- ❌ 永远不要将真实的证书文件提交到 git 仓库
- ❌ 不要在配置文件中硬编码证书内容
- ✅ 使用环境变量或安全的密钥管理服务
- ✅ 定期更新证书文件

## 相关脚本

- `scripts/apply-cert.sh` - 申请 SSL 证书
- `scripts/deploy-nginx.sh` - 完整部署 nginx + trojan-go
- `scripts/fix-current.sh` - 修复当前配置问题 