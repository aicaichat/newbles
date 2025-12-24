# 本地电脑使用代理指南

本指南详细说明如何在本地电脑（Windows、macOS、Linux）上使用该代理服务。

## 📋 代理服务器信息

### VMess 协议
- **服务器地址**: `ai.bless.top`
- **端口**: `443`
- **UUID**: `25c09e60-e69d-4b6b-b119-300180ef7fbb`
- **传输协议**: WebSocket
- **路径**: `/bs`
- **TLS**: 启用
- **加密方式**: auto

### Trojan 协议（备用）
- **服务器地址**: `ai.bless.top`
- **端口**: `443`
- **密码**: `mySecureBlessPassword123`
- **传输协议**: WebSocket
- **路径**: `/bs`
- **TLS**: 启用

---

## 🪟 Windows 系统

### 方案1：使用 v2rayN（推荐）

#### 1. 下载安装
1. 访问 GitHub 下载：https://github.com/2dust/v2rayN/releases
2. 下载最新版本的 `v2rayN-Core.zip`
3. 解压到任意目录（如 `C:\v2rayN`）

#### 2. 导入配置

**方法A：使用分享链接（最简单）**
1. 打开 v2rayN
2. 点击菜单栏 `服务器` → `从剪贴板导入批量URL`
3. 粘贴以下链接：
   ```
   vmess://eyJ2IjoiMiIsInBzIjoiYWkuYmxlc3MudG9wIiwiYWRkIjoiYWkuYmxlc3MudG9wIiwicG9ydCI6IjQ0MyIsInR5cGUiOiJub25lIiwiaWQiOiIyNWMwOWU2MC1lNjlkLTRiNmItYjExOS0zMDAxODBlZjdmYmIiLCJhaWQiOiIwIiwibmV0Ijoid3MiLCJwYXRoIjoiL2JzIiwiaG9zdCI6ImFpLmJsZXNzLnRvcCIsInRscyI6InRscyJ9
   ```
4. 点击确定，节点会自动添加

**方法B：手动导入配置文件**
1. 复制项目中的 `client-configs/v2ray-client.json` 文件
2. 在 v2rayN 中点击 `服务器` → `导入服务器配置` → `从本地文件导入`
3. 选择 `v2ray-client.json` 文件

**方法C：手动添加服务器**
1. 右键系统托盘图标 → `添加VMess服务器`
2. 填写以下信息：
   - 地址(Address): `ai.bless.top`
   - 端口(Port): `443`
   - 用户ID(UUID): `25c09e60-e69d-4b6b-b119-300180ef7fbb`
   - 额外ID(AlterId): `0`
   - 加密方式: `auto`
   - 传输协议: `ws`
   - 伪装域名: `ai.bless.top`
   - 路径: `/bs`
   - 底层传输安全: `tls`

#### 3. 启动代理
1. 右键系统托盘图标 → `Http代理` → `开启Http代理` → `自动配置系统代理`
2. 或者选择 `系统代理` → `自动配置系统代理`
3. 选择刚添加的服务器节点

#### 4. 测试连接
1. 右键系统托盘图标 → `检查更新订阅` → `测试服务器真连接延迟`
2. 打开浏览器访问 https://www.google.com 测试

---

### 方案2：使用 Clash Verge Rev

#### 1. 下载安装
1. 访问：https://github.com/clash-verge-rev/clash-verge-rev/releases
2. 下载 Windows 版本并安装

#### 2. 导入配置
1. 打开 Clash Verge Rev
2. 点击 `配置` → `导入配置`
3. 选择项目中的 `client-configs/clash-config.yaml` 文件
4. 或者手动创建配置，复制 `clash-config.yaml` 的内容

#### 3. 启动代理
1. 点击 `代理` 标签
2. 选择 `VMess-ai.bless.top` 节点
3. 点击 `系统代理` 开关启用

#### 4. 本地代理端口
- **HTTP代理**: `127.0.0.1:7890`
- **SOCKS5代理**: `127.0.0.1:7891`

---

## 🍎 macOS 系统

### 方案1：使用 v2rayU

#### 1. 下载安装
```bash
# 使用 Homebrew 安装
brew install --cask v2rayu

# 或从 GitHub 下载
# https://github.com/yanue/V2rayU/releases
```

#### 2. 导入配置
1. 打开 v2rayU
2. 点击菜单栏图标 → `配置` → `导入配置`
3. 选择项目中的 `client-configs/v2ray-client.json` 文件
4. 或使用分享链接导入

#### 3. 启动代理
1. 点击菜单栏图标 → `启动服务`
2. 选择 `系统代理` 或 `手动代理`
3. 选择服务器节点

---

### 方案2：使用 Clash Verge Rev（macOS）

#### 1. 下载安装
```bash
# 使用 Homebrew 安装
brew install --cask clash-verge-rev

# 或从 GitHub 下载
# https://github.com/clash-verge-rev/clash-verge-rev/releases
```

#### 2. 导入配置
1. 打开 Clash Verge Rev
2. 点击 `配置` → `导入配置`
3. 选择 `client-configs/clash-config.yaml` 文件

#### 3. 启动代理
1. 选择节点
2. 启用系统代理

---

### 方案3：使用命令行 v2ray（高级用户）

#### 1. 安装 v2ray
```bash
brew install v2ray
```

#### 2. 启动代理
```bash
# 使用项目配置文件启动
v2ray -config /Users/mac/Downloads/vpn/client-configs/v2ray-client.json

# 或复制到标准位置
cp /Users/mac/Downloads/vpn/client-configs/v2ray-client.json ~/.v2ray/config.json
v2ray -config ~/.v2ray/config.json
```

#### 3. 配置系统代理
1. 打开 `系统设置` → `网络` → `高级` → `代理`
2. 配置：
   - **SOCKS代理**: `127.0.0.1:1080`
   - **HTTP代理**: `127.0.0.1:1081`
3. 勾选 `使用这些代理设置`

---

## 🐧 Linux 系统

### 方案1：使用 v2rayA（推荐）

#### 1. 安装 v2rayA
```bash
# Ubuntu/Debian
wget -qO - https://apt.v2raya.org/key/public-key.asc | sudo tee /etc/apt/trusted.gpg.d/v2raya.asc
echo "deb https://apt.v2raya.org/ v2raya main" | sudo tee /etc/apt/sources.list.d/v2raya.list
sudo apt update
sudo apt install v2raya

# 启动服务
sudo systemctl start v2raya
sudo systemctl enable v2raya
```

#### 2. 配置
1. 打开浏览器访问：http://localhost:2017
2. 点击 `导入` → `从剪贴板导入`
3. 粘贴 vmess 链接或导入配置文件

#### 3. 启用系统代理
在 v2rayA 界面中启用 `系统代理`

---

### 方案2：使用 Clash Verge Rev（Linux）

#### 1. 下载安装
```bash
# 从 GitHub 下载 AppImage
wget https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v1.4.8/clash-verge_1.4.8_amd64.AppImage
chmod +x clash-verge_1.4.8_amd64.AppImage
./clash-verge_1.4.8_amd64.AppImage
```

#### 2. 导入配置
导入 `client-configs/clash-config.yaml` 文件

---

### 方案3：使用命令行 v2ray

#### 1. 安装 v2ray
```bash
# Ubuntu/Debian
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# 或使用包管理器
sudo apt install v2ray
```

#### 2. 配置
```bash
# 复制配置文件
sudo cp /Users/mac/Downloads/vpn/client-configs/v2ray-client.json /usr/local/etc/v2ray/config.json

# 或编辑配置文件
sudo nano /usr/local/etc/v2ray/config.json
```

#### 3. 启动服务
```bash
# 启动 v2ray
sudo systemctl start v2ray
sudo systemctl enable v2ray

# 检查状态
sudo systemctl status v2ray
```

#### 4. 配置系统代理
```bash
# 设置环境变量（临时）
export http_proxy=http://127.0.0.1:1081
export https_proxy=http://127.0.0.1:1081
export socks_proxy=socks5://127.0.0.1:1080

# 或添加到 ~/.bashrc（永久）
echo 'export http_proxy=http://127.0.0.1:1081' >> ~/.bashrc
echo 'export https_proxy=http://127.0.0.1:1081' >> ~/.bashrc
echo 'export socks_proxy=socks5://127.0.0.1:1080' >> ~/.bashrc
source ~/.bashrc
```

---

## 📱 移动端配置

### Android - v2rayNG

1. 从 Google Play 或 GitHub 下载 v2rayNG
2. 打开应用 → 右上角 `+` → `扫描二维码` 或 `手动输入`
3. 选择 `从剪贴板导入`，粘贴 vmess 链接：
   ```
   vmess://eyJ2IjoiMiIsInBzIjoiYWkuYmxlc3MudG9wIiwiYWRkIjoiYWkuYmxlc3MudG9wIiwicG9ydCI6IjQ0MyIsInR5cGUiOiJub25lIiwiaWQiOiIyNWMwOWU2MC1lNjlkLTRiNmItYjExOS0zMDAxODBlZjdmYmIiLCJhaWQiOiIwIiwibmV0Ijoid3MiLCJwYXRoIjoiL2JzIiwiaG9zdCI6ImFpLmJsZXNzLnRvcCIsInRscyI6InRscyJ9
   ```
4. 点击右下角 `V` 图标启动代理

### iOS - Shadowrocket / Quantumult X

1. 在 App Store 购买并安装 Shadowrocket
2. 打开应用 → 右上角 `+` → 选择 `VMess`
3. 填写服务器信息：
   - 服务器: `ai.bless.top`
   - 端口: `443`
   - UUID: `25c09e60-e69d-4b6b-b119-300180ef7fbb`
   - 加密: `auto`
   - 传输: `ws`
   - 路径: `/bs`
   - TLS: `开启`
4. 保存并启用

---

## 🔧 浏览器代理配置（不使用系统代理时）

### Chrome / Edge
1. 安装扩展：SwitchyOmega
2. 配置代理：
   - **协议**: SOCKS5
   - **服务器**: `127.0.0.1`
   - **端口**: `1080` (v2ray) 或 `7891` (Clash)
3. 选择代理模式

### Firefox
1. 打开 `设置` → `网络设置` → `设置`
2. 选择 `手动代理配置`
3. 配置：
   - **SOCKS主机**: `127.0.0.1`
   - **端口**: `1080`
   - **SOCKS v5**
4. 勾选 `代理DNS查询时使用SOCKS v5`

---

## ✅ 连接测试

### 测试代理是否工作

#### 方法1：浏览器测试
打开浏览器访问：
- https://www.google.com
- https://www.youtube.com
- https://ip.sb （查看当前IP）

#### 方法2：命令行测试
```bash
# Windows (PowerShell)
curl -x socks5://127.0.0.1:1080 https://www.google.com

# macOS/Linux
curl --socks5 127.0.0.1:1080 https://www.google.com

# 查看当前IP
curl --socks5 127.0.0.1:1080 https://ip.sb
```

#### 方法3：检查端口
```bash
# Windows
netstat -an | findstr 1080

# macOS/Linux
netstat -an | grep 1080
# 或
ss -tlnp | grep 1080
```

---

## 🐛 常见问题排查

### 1. 无法连接服务器
- **检查服务器状态**: 确认服务器正常运行
- **检查防火墙**: 确保本地防火墙允许客户端连接
- **检查网络**: 确认能访问 `ai.bless.top:443`

### 2. 连接超时
- **检查配置**: 确认服务器地址、端口、UUID 正确
- **检查TLS**: 确认 TLS 已启用，SNI 设置为 `ai.bless.top`
- **检查路径**: 确认 WebSocket 路径为 `/bs`

### 3. 速度慢
- **更换节点**: 尝试其他节点（如果有）
- **检查网络**: 测试本地网络速度
- **调整加密**: 尝试不同的加密方式

### 4. 部分网站无法访问
- **检查规则**: 确认代理规则配置正确
- **DNS设置**: 尝试更换 DNS 服务器（如 8.8.8.8）
- **分流规则**: 检查是否需要添加特定规则

---

## 📝 配置文件位置

项目中的客户端配置文件位于：
- **V2Ray配置**: `client-configs/v2ray-client.json`
- **Clash配置**: `client-configs/clash-config.yaml`
- **Trojan配置**: `client-configs/xray-trojan-client.json`
- **分享链接**: `client-configs/vmess-link.txt`

---

## 🔐 安全建议

1. **定期更新客户端**: 保持客户端软件为最新版本
2. **不要分享配置**: 保护你的 UUID 和密码
3. **使用TLS**: 确保始终启用 TLS 加密
4. **检查证书**: 定期验证服务器证书有效性

---

## 📞 获取帮助

如果遇到问题：
1. 检查客户端日志
2. 查看服务器状态
3. 参考项目 README.md
4. 检查配置文件格式是否正确

---

**祝使用愉快！** 🎉

