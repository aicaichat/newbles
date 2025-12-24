# OpenWrt 路由器 V2Ray 配置指南

## 📋 准备工作

### 系统要求
- OpenWrt 19.07+ 或 ImmortalWrt
- 至少 64MB RAM，128MB 存储空间
- 支持的架构：arm64, amd64, mipsle 等

### 检查系统信息
```bash
# SSH 登录路由器后执行
uname -a
cat /proc/cpuinfo | grep "model name"
df -h
```

---

## 🚀 方案1：PassWall 插件（推荐）

### 1.1 安装 PassWall

**方法A：从软件源安装**
```bash
# 更新软件包
opkg update

# 安装 PassWall
opkg install luci-app-passwall
opkg install luci-i18n-passwall-zh-cn  # 中文语言包
```

**方法B：手动安装 IPK 包**
```bash
# 下载对应架构的 IPK 包
cd /tmp
wget https://github.com/xiaorouji/openwrt-passwall/releases/download/packages/luci-app-passwall_*.ipk

# 安装
opkg install luci-app-passwall_*.ipk
opkg install luci-i18n-passwall-zh-cn_*.ipk
```

### 1.2 PassWall 配置

1. **Web 界面配置**：
   ```
   地址: http://192.168.1.1 (路由器IP)
   路径: 服务 → PassWall
   ```

2. **添加 V2Ray 节点**：
   ```
   节点列表 → 添加 → VMess
   
   基本设置:
   ├── 别名: ai.bless.top-v2ray
   ├── 服务器地址: ai.bless.top
   ├── 端口: 443
   ├── 用户ID: 25c09e60-e69d-4b6b-b119-300180ef7fbb
   ├── 额外ID: 0
   └── 加密方式: auto
   
   传输设置:
   ├── 传输协议: websocket
   ├── WebSocket路径: /bs
   ├── WebSocket主机: ai.bless.top
   └── TLS: 启用
   ```

3. **基本设置**：
   ```
   主要 → 基本设置
   ├── 总开关: 启用
   ├── TCP节点: 选择刚添加的节点
   ├── 运行模式: 大陆白名单模式 (推荐)
   └── 保存&应用
   ```

---

## 🚀 方案2：OpenClash 插件

### 2.1 安装 OpenClash

```bash
# 下载 OpenClash
cd /tmp
wget https://github.com/vernesong/OpenClash/releases/download/v0.45.106-beta/luci-app-openclash_*.ipk

# 安装依赖
opkg update
opkg install coreutils-nohup bash iptables dnsmasq-full curl ca-certificates ipset ip-full iptables-mod-tproxy iptables-mod-extra libcap libcap-bin ruby ruby-yaml kmod-tun kmod-inet-diag unzip luci-compat

# 安装 OpenClash
opkg install luci-app-openclash_*.ipk
```

### 2.2 OpenClash 配置

1. **上传配置文件**：
   - 进入 服务 → OpenClash
   - 配置文件订阅 → 上传配置文件
   - 选择项目中的 `client-configs/clash-config.yaml`

2. **启动服务**：
   - 插件设置 → 功能设置 → 启用 OpenClash
   - 应用配置

---

## 🚀 方案3：原生 V2Ray-Core

### 3.1 安装 V2Ray 核心

```bash
# 安装 v2ray-core
opkg update
opkg install v2ray-core

# 创建配置目录
mkdir -p /etc/v2ray
```

### 3.2 配置文件

将项目中的 `client-configs/v2ray-client.json` 上传到 `/etc/v2ray/config.json`

```bash
# 方法1：直接编辑
vi /etc/v2ray/config.json

# 方法2：SCP 上传
scp client-configs/v2ray-client.json root@192.168.1.1:/etc/v2ray/config.json
```

### 3.3 启动服务

```bash
# 启动 v2ray
/etc/init.d/v2ray start

# 设置开机自启
/etc/init.d/v2ray enable

# 检查状态
/etc/init.d/v2ray status
```

### 3.4 透明代理配置

创建透明代理脚本 `/etc/init.d/v2ray-transparent`：

```bash
#!/bin/sh /etc/rc.common

START=99
STOP=15

start() {
    # 创建新的路由表
    ip route add local 0.0.0.0/0 dev lo table 100
    ip rule add fwmark 1 table 100
    
    # iptables 规则
    iptables -t mangle -N V2RAY
    iptables -t mangle -A V2RAY -d 127.0.0.0/8 -j RETURN
    iptables -t mangle -A V2RAY -d 192.168.0.0/16 -j RETURN
    iptables -t mangle -A V2RAY -d 10.0.0.0/8 -j RETURN
    iptables -t mangle -A V2RAY -d 172.16.0.0/12 -j RETURN
    iptables -t mangle -A V2RAY -p tcp -j TPROXY --on-port 12345 --tproxy-mark 1
    iptables -t mangle -A PREROUTING -j V2RAY
}

stop() {
    iptables -t mangle -F V2RAY
    iptables -t mangle -X V2RAY
    ip rule del table 100
    ip route flush table 100
}
```

---

## 🔧 路由器配置优化

### DNS 设置

1. **PassWall DNS**：
   ```
   网络 → DHCP/DNS
   DNS转发: 127.0.0.1#5353 (PassWall DNS端口)
   ```

2. **自定义 DNS**：
   ```
   上游DNS: 8.8.8.8, 1.1.1.1
   禁用IPV6: 是 (如果不需要)
   ```

### 防火墙设置

```bash
# 允许 V2Ray 端口
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-V2Ray'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='1080'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart
```

---

## 📱 客户端设备配置

### 自动代理（推荐）
设备连接路由器WiFi后自动走代理，无需额外配置。

### 手动代理设置
如果只想部分设备走代理：

**Android/iOS:**
```
WiFi设置 → 代理 → 手动
代理服务器: 192.168.1.1 (路由器IP)
端口: 1080 (SOCKS5) 或 8080 (HTTP)
```

**Windows/macOS:**
```
系统代理设置:
HTTP代理: 192.168.1.1:8080
SOCKS代理: 192.168.1.1:1080
```

---

## 🔍 故障排除

### 检查服务状态
```bash
# PassWall 状态
/etc/init.d/passwall status

# OpenClash 状态
/etc/init.d/openclash status

# V2Ray 核心状态
ps | grep v2ray
netstat -an | grep 1080
```

### 日志查看
```bash
# 系统日志
logread | grep -i v2ray

# PassWall 日志
cat /tmp/log/passwall.log

# OpenClash 日志
cat /tmp/openclash.log
```

### 连接测试
```bash
# 测试代理连接
curl --socks5 127.0.0.1:1080 https://www.google.com -I

# 测试DNS解析
nslookup google.com 127.0.0.1
```

### 重启服务
```bash
# 重启网络
/etc/init.d/network restart

# 重启防火墙
/etc/init.d/firewall restart

# 重启代理服务
/etc/init.d/passwall restart
```

---

## 📋 推荐配置

**家庭用户推荐**：PassWall + 大陆白名单模式
**企业用户推荐**：V2Ray 核心 + 自定义路由规则
**技术爱好者**：OpenClash + 完整 Clash 配置

根据你的需求选择合适的方案！ 