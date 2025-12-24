# 服务器实际运行状态

> ⚠️ **已更新**：详细验证结果请查看 `CONFIRMED_SERVER_CONFIG.md`

## 🎯 当前实际运行的服务

根据服务器上的 Docker 容器信息，**实际运行的是以下配置**：

### 运行中的容器信息

```
容器ID: cd1c4f69240d
容器名: v2ray
镜像: teddysun/v2ray:latest
命令: /usr/bin/v2ray run -config /etc/v2ray/config.json
运行时间: 6 months ago, Up 5 weeks
端口映射: 0.0.0.0:8443->8443/tcp, :::8443->8443/tcp
```

### 关键信息

✅ **确认的服务配置：**
- **服务类型**: V2Ray VMess
- **容器名称**: `v2ray`
- **镜像版本**: `teddysun/v2ray:latest`
- **监听端口**: `8443`
- **端口映射**: `0.0.0.0:8443` (所有接口)
- **运行状态**: 已运行 5 周，服务稳定

---

## 📊 配置分析

### 端口映射说明

**实际运行**: `0.0.0.0:8443->8443/tcp`
- 这意味着容器监听所有网络接口的 8443 端口
- 外部可以通过服务器的 8443 端口访问

**配置文件**: `127.0.0.1:8443:8443` (docker-compose-v2ray.yml)
- 配置文件中写的是仅本地访问
- 但实际运行的是所有接口访问

**可能的原因：**
1. 容器是手动启动的，而不是通过 docker-compose
2. docker-compose 配置被修改过
3. 有防火墙/安全组限制，虽然映射到 0.0.0.0，但实际只允许特定IP访问

### 实际架构

根据运行状态，实际架构可能是：

**方案A：后端模式（通过 nginx）**
```
客户端 → nginx:443 (SSL终止) → /bs路径 → V2Ray:8443 (WebSocket) → 代理
```

**方案B：直接访问模式**
```
客户端 → V2Ray:8443 (直接访问，如果防火墙允许)
```

---

## 🔍 如何确认实际配置

### 1. 查看容器详细信息

```bash
# 查看容器完整信息
docker inspect v2ray

# 查看容器使用的配置文件
docker exec v2ray cat /etc/v2ray/config.json

# 查看容器日志
docker logs v2ray --tail=50
```

### 2. 检查端口监听情况

```bash
# 查看端口监听
netstat -tlnp | grep 8443
# 或
ss -tlnp | grep 8443

# 查看防火墙规则
iptables -L -n | grep 8443
# 或
ufw status | grep 8443
```

### 3. 检查 nginx 配置

```bash
# 查看 nginx 是否配置了反向代理
grep -r "8443\|/bs" /etc/nginx/

# 查看 nginx 是否运行
systemctl status nginx
# 或
ps aux | grep nginx
```

### 4. 测试连接

```bash
# 测试本地连接
curl -v http://127.0.0.1:8443/bs

# 测试外部连接（从其他机器）
curl -v http://服务器IP:8443/bs

# 测试 HTTPS 连接（如果通过 nginx）
curl -v https://ai.bless.top/bs
```

---

## ⚠️ 安全建议

### 如果端口映射是 0.0.0.0:8443

**安全风险：**
- V2Ray 端口直接暴露在公网上
- 如果没有防火墙保护，可能被扫描和攻击

**建议措施：**

1. **使用防火墙限制访问**
   ```bash
   # 只允许本地和 nginx 访问
   iptables -A INPUT -p tcp --dport 8443 ! -s 127.0.0.1 -j DROP
   ```

2. **修改端口映射为仅本地**
   ```bash
   # 停止容器
   docker stop v2ray
   docker rm v2ray
   
   # 使用正确的配置重新启动
   docker-compose -f docker-compose-v2ray.yml up -d
   ```

3. **确保通过 nginx 访问**
   - 确保 nginx 配置了反向代理
   - 客户端只通过 HTTPS (443) 访问
   - V2Ray 端口不对外暴露

---

## 🔧 推荐的正确配置

### 方案1：后端模式（推荐）⭐

**Docker Compose 配置应该是：**
```yaml
ports:
  - "127.0.0.1:8443:8443"  # 仅本地访问
```

**架构：**
```
客户端 → nginx:443 (SSL) → /bs → V2Ray:127.0.0.1:8443 → 代理
```

**优势：**
- ✅ 安全：V2Ray 不直接暴露
- ✅ 统一管理：SSL 由 nginx 处理
- ✅ 灵活：可以配置多个域名

### 方案2：直接暴露模式

**Docker Compose 配置：**
```yaml
ports:
  - "443:443"  # 直接暴露 443 端口
```

**架构：**
```
客户端 → V2Ray:443 (SSL + WebSocket) → 代理
```

**注意：**
- 需要 V2Ray 自己处理 TLS
- 需要挂载证书文件
- 需要停止 nginx 避免端口冲突

---

## 📝 当前状态总结

### ✅ 确认的信息

1. **服务正在运行**: V2Ray 容器已运行 5 周
2. **镜像正确**: 使用 `teddysun/v2ray:latest`
3. **端口正确**: 监听 8443 端口
4. **服务稳定**: 运行时间较长，说明服务正常

### ⚠️ 需要注意

1. **端口映射**: 实际是 `0.0.0.0:8443`，而不是配置文件的 `127.0.0.1:8443`
2. **安全检查**: 需要确认是否有防火墙保护
3. **nginx 配置**: 需要确认是否通过 nginx 反向代理

### 🔍 建议检查

1. 查看容器实际使用的配置文件
2. 检查 nginx 是否配置了反向代理
3. 检查防火墙规则
4. 测试实际连接方式

---

## 🚀 客户端配置

无论服务端实际运行方式如何，**客户端配置保持不变**：

```yaml
proxies:
  - name: "VMess-ai.bless.top"
    type: vmess
    server: ai.bless.top
    port: 443          # 客户端始终连接 443 端口（nginx）
    uuid: 25c09e60-e69d-4b6b-b119-300180ef7fbb
    alterId: 0
    cipher: auto
    tls: true
    network: ws
    ws-opts:
      path: /bs
      headers:
        Host: ai.bless.top
```

**说明：**
- 客户端连接的是 `ai.bless.top:443`（通过 nginx）
- 不直接连接 `8443` 端口
- 如果 nginx 配置正确，客户端配置无需修改

---

## 📞 快速诊断命令

```bash
# 一键诊断脚本
echo "=== 容器状态 ==="
docker ps | grep v2ray

echo ""
echo "=== 端口监听 ==="
netstat -tlnp | grep 8443

echo ""
echo "=== 容器配置 ==="
docker exec v2ray cat /etc/v2ray/config.json | grep -E "port|listen|path"

echo ""
echo "=== Nginx 状态 ==="
systemctl status nginx 2>/dev/null || echo "Nginx 未运行或未安装"

echo ""
echo "=== Nginx 反向代理配置 ==="
grep -r "8443\|/bs" /etc/nginx/ 2>/dev/null || echo "未找到相关配置"
```

---

**总结：服务器上实际运行的是 V2Ray 容器，端口映射为 0.0.0.0:8443。建议检查是否有 nginx 反向代理和防火墙保护。** ✅

