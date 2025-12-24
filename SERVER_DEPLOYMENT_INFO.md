# 服务端部署信息说明

## 🎯 实际运行状态（已确认）

**根据服务器上的实际容器信息：**

```
容器名: v2ray
镜像: teddysun/v2ray:latest
端口映射: 0.0.0.0:8443->8443/tcp
运行状态: Up 5 weeks (稳定运行)
```

**详细分析请查看 `ACTUAL_SERVER_STATUS.md`**

---

## 🎯 推荐部署方案

根据项目配置和部署脚本，**推荐的部署配置如下**：

### 方案1：V2Ray 后端模式（推荐）⭐

**使用的文件：**
- **Docker Compose**: `docker-compose-v2ray.yml`
- **服务器配置**: `v2ray/config.json`
- **容器名称**: `v2ray`
- **镜像**: `teddysun/v2ray:latest`

**配置详情：**
```yaml
服务: V2Ray
监听地址: 127.0.0.1:8443 (仅本地)
协议: VMess
传输: WebSocket
路径: /bs
TLS: 由 nginx 处理（SSL 终止）
```

**架构：**
```
客户端 → nginx:443 (SSL终止) → /bs路径 → V2Ray:8443 (WebSocket) → 代理
```

**启动命令：**
```bash
docker-compose -f docker-compose-v2ray.yml up -d
```

**配置文件内容：**
- 监听端口：`8443`（仅本地 127.0.0.1）
- 协议：`VMess`
- UUID：`25c09e60-e69d-4b6b-b119-300180ef7fbb`
- WebSocket 路径：`/bs`
- **注意**：此配置**不包含 TLS**，TLS 由 nginx 处理

---

### 方案2：V2Ray 直接暴露模式（备用）

**使用的文件：**
- **Docker Compose**: `docker-compose-v2ray-direct.yml`
- **服务器配置**: `v2ray/config-direct.json`
- **容器名称**: `v2ray-direct`
- **镜像**: `v2fly/v2fly-core:latest`

**配置详情：**
```yaml
服务: V2Ray
监听地址: 0.0.0.0:443 (直接暴露)
协议: VMess
传输: WebSocket
路径: /bs
TLS: V2Ray 自己处理（需要证书挂载）
```

**架构：**
```
客户端 → V2Ray:443 (直接处理 SSL + WebSocket) → 代理
```

**启动命令：**
```bash
docker-compose -f docker-compose-v2ray-direct.yml up -d
```

**配置文件内容：**
- 监听端口：`443`（直接暴露）
- 协议：`VMess`
- UUID：`25c09e60-e69d-4b6b-b119-300180ef7fbb`
- WebSocket 路径：`/bs`
- **包含 TLS 配置**：需要挂载证书到 `/cert` 目录

---

### 方案3：Xray Trojan 模式（备用）

**使用的文件：**
- **Docker Compose**: `docker-compose-xray.yml`
- **服务器配置**: `xray/config.json`
- **容器名称**: `xray-trojan`
- **镜像**: `ghcr.io/xtls/xray-core:latest`

**配置详情：**
```yaml
服务: Xray
监听地址: 127.0.0.1:8443 (仅本地)
协议: Trojan
传输: WebSocket
路径: /bs
密码: mySecureBlessPassword123
TLS: 由 nginx 处理
```

**启动命令：**
```bash
docker-compose -f docker-compose-xray.yml up -d
```

---

## 📊 配置文件对比

| 配置项 | 后端模式 (推荐) | 直接暴露模式 | Xray Trojan |
|--------|----------------|-------------|-------------|
| **配置文件** | `v2ray/config.json` | `v2ray/config-direct.json` | `xray/config.json` |
| **监听地址** | 127.0.0.1:8443 | 0.0.0.0:443 | 127.0.0.1:8443 |
| **协议** | VMess | VMess | Trojan |
| **TLS处理** | nginx | V2Ray | nginx |
| **需要nginx** | ✅ 是 | ❌ 否 | ✅ 是 |
| **证书位置** | nginx配置 | /cert目录 | nginx配置 |
| **推荐度** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |

---

## 🔍 如何确认当前运行的是哪个？

### 方法1：查看运行中的容器
```bash
# 查看所有相关容器
docker ps | grep -E "v2ray|xray"

# 查看具体容器信息
docker inspect v2ray
docker inspect v2ray-direct
docker inspect xray-trojan
```

### 方法2：查看容器使用的配置文件
```bash
# 查看 V2Ray 后端模式
docker exec v2ray cat /etc/v2ray/config.json

# 查看 V2Ray 直接暴露模式
docker exec v2ray-direct cat /etc/v2ray/config.json

# 查看 Xray Trojan
docker exec xray-trojan cat /etc/xray/config.json
```

### 方法3：查看端口占用
```bash
# 查看 8443 端口（后端模式）
netstat -tlnp | grep 8443

# 查看 443 端口（直接暴露模式）
netstat -tlnp | grep 443
```

### 方法4：查看 docker-compose 文件
```bash
# 查看哪个 docker-compose 文件在运行
docker-compose ps

# 或查看所有 compose 项目
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"
```

---

## 📝 客户端配置对应关系

### 如果服务端运行的是 V2Ray 后端模式（推荐）
✅ **使用以下客户端配置：**
- `client-configs/v2ray-client.json` - V2Ray 原生格式
- `client-configs/clash-config.yaml` - Clash 格式
- `client-configs/vmess-link.txt` - 分享链接

**客户端连接信息：**
- 服务器：`ai.bless.top`
- 端口：`443`（nginx 端口）
- UUID：`25c09e60-e69d-4b6b-b119-300180ef7fbb`
- 协议：VMess over WebSocket + TLS
- 路径：`/bs`

### 如果服务端运行的是 V2Ray 直接暴露模式
✅ **使用相同的客户端配置**（因为对外接口相同）

### 如果服务端运行的是 Xray Trojan
✅ **使用以下客户端配置：**
- `client-configs/xray-trojan-client.json` - Xray/Trojan 格式

**客户端连接信息：**
- 服务器：`ai.bless.top`
- 端口：`443`
- 密码：`mySecureBlessPassword123`
- 协议：Trojan over WebSocket + TLS
- 路径：`/bs`

---

## 🚀 部署脚本说明

### 主要部署脚本
- **`scripts/deploy-v2ray.sh`** - V2Ray 部署脚本（推荐使用）
  - 支持选择后端模式或直接暴露模式
  - 自动更新 UUID 到所有配置文件
  - 自动生成客户端配置

### 其他脚本
- `scripts/fix-v2ray.sh` - 修复 V2Ray 问题
- `scripts/deploy-nginx.sh` - 部署 nginx 反向代理
- `scripts/final-solution-fixed.sh` - 最终解决方案脚本

---

## ⚠️ 重要提示

1. **推荐使用后端模式**（`docker-compose-v2ray.yml`）
   - SSL 由 nginx 统一管理，证书更新方便
   - 可以复用 nginx 配置，支持多域名
   - 性能优化，支持 HTTP/2

2. **直接暴露模式注意事项**
   - 需要停止 nginx，避免端口冲突
   - 需要手动挂载证书文件
   - 证书更新需要重启容器

3. **客户端配置通用性**
   - 无论服务端使用哪种模式，客户端配置基本相同
   - 因为对外接口（域名、端口、路径）都是一样的
   - 主要区别在服务端内部实现

---

## 📞 快速检查命令

```bash
# 一键检查当前运行的服务
echo "=== 检查运行中的容器 ==="
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -E "v2ray|xray|NAME"

echo ""
echo "=== 检查端口占用 ==="
netstat -tlnp 2>/dev/null | grep -E "8443|443" || ss -tlnp | grep -E "8443|443"

echo ""
echo "=== 检查配置文件 ==="
if docker ps | grep -q "v2ray$"; then
    echo "✅ V2Ray 后端模式运行中"
    docker exec v2ray cat /etc/v2ray/config.json | grep -E "port|listen|path"
elif docker ps | grep -q "v2ray-direct"; then
    echo "✅ V2Ray 直接暴露模式运行中"
    docker exec v2ray-direct cat /etc/v2ray/config.json | grep -E "port|listen|path"
elif docker ps | grep -q "xray-trojan"; then
    echo "✅ Xray Trojan 模式运行中"
    docker exec xray-trojan cat /etc/xray/config.json | grep -E "port|listen|path"
else
    echo "❌ 未发现运行中的代理服务"
fi
```

---

**总结：根据项目 README 和部署脚本，服务端真正运行的是 `docker-compose-v2ray.yml`（V2Ray 后端模式），使用 `v2ray/config.json` 配置文件。** ✅

