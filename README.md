# V2Ray 代理服务完整部署指南

本项目提供 V2Ray VMess over WebSocket + TLS 的完整部署方案，经过生产环境验证。

## 🚀 快速开始

### 服务器端部署

```bash
# 1. 克隆项目
git clone <your-repo>
cd vpn

# 2. 运行部署脚本
bash scripts/deploy-v2ray.sh

# 3. 或手动部署
docker-compose -f docker-compose-v2ray.yml up -d
```

### 客户端配置

选择适合你的客户端：

#### 方案1：V2Ray 原生客户端（推荐）
- **配置文件**: `client-configs/v2ray-client.json`
- **Windows**: v2rayN
- **macOS**: v2rayU 或命令行
- **Android**: v2rayNG
- **iOS**: Shadowrocket / Quantumult X

#### 方案2：Clash 替代客户端
- **配置文件**: `client-configs/clash-config.yaml`
- **客户端**: Clash Verge Rev, Mihomo, Clash Meta

#### 方案3：移动端快速导入
- **分享链接**: 见 `client-configs/vmess-link.txt`
- 复制 vmess:// 链接到客户端导入

## 📁 项目结构

```
vpn/
├── v2ray/                           # V2Ray 服务器配置
│   ├── config.json                 # 后端模式（nginx反代）
│   └── config-direct.json          # 直接暴露模式
├── client-configs/                 # 客户端配置
│   ├── v2ray-client.json          # V2Ray 原生格式
│   ├── clash-config.yaml          # Clash 格式
│   ├── xray-trojan-client.json    # Xray Trojan 配置
│   └── vmess-link.txt              # 分享链接
├── scripts/                        # 部署脚本
│   ├── deploy-v2ray.sh            # V2Ray 自动部署
│   └── fix-v2ray.sh               # 问题修复脚本
├── docker-compose-v2ray.yml       # V2Ray 后端部署
├── docker-compose-v2ray-direct.yml # V2Ray 直接暴露
├── docker-compose-xray.yml        # Xray Trojan 部署
└── cert/                           # SSL 证书目录
```

## ⚙️ 配置详情

### 服务器信息
- **域名**: ai.bless.top
- **端口**: 443 (HTTPS)
- **协议**: VMess over WebSocket + TLS
- **路径**: /bs
- **UUID**: 25c09e60-e69d-4b6b-b119-300180ef7fbb

### 架构说明
```
客户端 → nginx:443 (SSL终止) → /bs路径 → V2Ray:8443 (WebSocket) → 代理
```

## 🛠️ 部署方式

### 方式1：后端模式（推荐）
需要 nginx 作为前端反向代理，提供 SSL 终止和 WebSocket 升级。

```bash
docker-compose -f docker-compose-v2ray.yml up -d
```

**优势**：
- SSL 由 nginx 处理，证书管理简单
- 可复用 nginx 配置，支持多域名
- 性能优化，支持 HTTP/2

### 方式2：直接暴露模式
V2Ray 直接监听 443 端口，处理 SSL 和 WebSocket。

```bash
docker-compose -f docker-compose-v2ray-direct.yml up -d
```

**注意**：需要停止 nginx，确保端口不冲突。

### 方式3：Xray Trojan 模式
使用 Xray 的 Trojan 协议（备用方案）。

```bash
docker-compose -f docker-compose-xray.yml up -d
```

## 📱 客户端设置指南

### Windows - v2rayN
1. 下载 v2rayN：https://github.com/2dust/v2rayN/releases
2. 导入配置：服务器 → 从剪贴板导入批量URL
3. 测试连接：右键节点 → 测试服务器真连接延迟

### macOS - 命令行
```bash
# 安装 v2ray
brew install v2ray

# 启动服务
v2ray -config client-configs/v2ray-client.json

# 配置系统代理：127.0.0.1:1080 (SOCKS5)
```

### Android - v2rayNG
1. 安装 v2rayNG
2. 右上角 + → 扫描二维码 或 手动输入
3. 填入服务器信息或导入 vmess:// 链接

### iOS - Shadowrocket
1. 购买并安装 Shadowrocket
2. 右上角 + → 类型选择 VMess
3. 填入配置信息或扫描二维码

## 🔧 故障排除

### 常见问题

1. **连接失败**
   ```bash
   # 检查服务状态
   docker logs v2ray
   netstat -tlnp | grep 8443
   curl -I https://ai.bless.top/
   ```

2. **证书问题**
   ```bash
   # 检查证书有效期
   openssl x509 -in /root/newbles/cert/fullchain.cer -text -noout
   ```

3. **重启服务**
   ```bash
   # 使用修复脚本
   bash scripts/fix-v2ray.sh
   ```

### 手动修复步骤

```bash
# 1. 停止容器
docker-compose -f docker-compose-v2ray.yml down

# 2. 检查配置
python3 -m json.tool v2ray/config.json

# 3. 重新启动
docker-compose -f docker-compose-v2ray.yml up -d

# 4. 查看日志
docker logs v2ray --tail=20
```

## 🔐 安全建议

1. **定期更换 UUID**
   ```bash
   NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
   sed -i "s/25c09e60-e69d-4b6b-b119-300180ef7fbb/$NEW_UUID/g" v2ray/config.json
   docker-compose -f docker-compose-v2ray.yml restart
   ```

2. **防火墙配置**
   ```bash
   # 只开放必要端口
   ufw allow 22/tcp
   ufw allow 80/tcp
   ufw allow 443/tcp
   ufw enable
   ```

3. **定期备份配置**
   ```bash
   tar -czf vpn-backup-$(date +%Y%m%d).tar.gz v2ray/ client-configs/
   ```

## 📊 性能监控

```bash
# 查看连接统计
docker exec v2ray netstat -an | grep 8443

# 监控资源使用
docker stats v2ray

# 查看访问日志
tail -f /var/log/nginx/access.log | grep "/bs"
```

## 🔗 相关链接

- [V2Ray 官方文档](https://www.v2ray.com/)
- [v2rayN Windows客户端](https://github.com/2dust/v2rayN)
- [v2rayNG Android客户端](https://github.com/2dust/v2rayNG)
- [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev)

---

**部署完成后，你将获得一个稳定的 VMess over WebSocket + TLS 代理服务！** 🎉 