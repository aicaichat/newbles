# Clash Verge Rev 配置步骤

## ✅ 第1步：打开 Clash Verge Rev

1. 打开"启动台"（Launchpad）
2. 找到并打开 **Clash Verge** 应用
3. 首次打开可能需要授权网络权限，点击"允许"

---

## ✅ 第2步：导入配置

### 方法A：导入 YAML 配置文件（推荐）⭐

**方式1：使用本地配置文件**

1. 在 Clash Verge 中，点击左侧菜单的 **"配置"** 标签
2. 点击右上角的 **"+"** 按钮或 **"导入"** 按钮
3. 选择 **"从文件导入"** 或 **"Import from File"**
4. 浏览并选择项目中的配置文件：
   ```
   /Users/mac/Downloads/vpn/client-configs/clash-config.yaml
   ```
5. 配置文件会自动导入并显示在列表中

**方式2：从服务器导出配置（推荐）⭐**

如果配置文件不在本地，可以从服务器自动导出：

1. **在服务器上执行**：
   ```bash
   cd /root/newbles
   bash scripts/export-clash-config.sh
   ```

2. **下载配置文件**：
   ```bash
   # 在本地执行
   scp root@your-server:/root/newbles/clash-config-exported.yaml ./
   ```

3. **导入到 Clash Verge**：
   - 点击 **"配置"** → **"导入"**
   - 选择下载的 `clash-config-exported.yaml` 文件

**详细说明**：查看 [服务器端导出配置.md](./服务器端导出配置.md)

### 方法B：使用 VMess 链接导入

1. 在 Clash Verge 中，点击左侧菜单的 **"代理"** 标签
2. 点击 **"添加"** 或 **"+"** 按钮
3. 选择 **"从剪贴板导入"** 或粘贴以下 VMess 链接：
   ```
   vmess://eyJ2IjoiMiIsInBzIjoiYWkuYmxlc3MudG9wIiwiYWRkIjoiYWkuYmxlc3MudG9wIiwicG9ydCI6IjQ0MyIsInR5cGUiOiJub25lIiwiaWQiOiIyNWMwOWU2MC1lNjlkLTRiNmItYjExOS0zMDAxODBlZjdmYmIiLCJhaWQiOiIwIiwibmV0Ijoid3MiLCJwYXRoIjoiL2JzIiwiaG9zdCI6ImFpLmJsZXNzLnRvcCIsInRscyI6InRscyJ9
   ```

---

## ✅ 第3步：选择节点

1. 点击左侧菜单的 **"代理"** 标签
2. 在代理组 **"Proxy"** 中，选择节点：**"VMess-ai.bless.top"**

---

## ✅ 第4步：选择代理模式

### 方式1：系统代理模式（推荐日常使用）

1. 点击 Clash Verge 窗口右上角的 **"系统代理"** 开关
2. 或点击菜单栏的 Clash Verge 图标（顶部状态栏）
3. 选择 **"系统代理"** 或 **"System Proxy"**

**特点**：
- ✅ 性能好，速度快
- ✅ 不需要系统权限
- ✅ 适合日常浏览和大多数应用

### 方式2：TUN 模式（虚拟网卡）⭐ 推荐

**适合需要代理所有应用的场景**（包括游戏、命令行工具等）

#### 使用 TUN 模式配置

1. **导入 TUN 配置**：
   - 点击 **"配置"** 标签
   - 导入 `client-configs/clash-config-tun.yaml` 文件
   - **或从服务器导出**：在服务器上执行 `bash scripts/export-clash-config-tun.sh`，然后下载生成的配置文件

2. **启用 TUN 模式**：
   - 点击 **"设置"** 标签（或菜单栏图标 → 设置）
   - 找到 **"TUN 模式"** 开关并开启
   - **首次使用需要授权**：macOS 会弹出权限提示，点击 **"允许"**

3. **启动 TUN 模式**：
   - 点击右上角的 **"TUN 模式"** 开关
   - 或点击菜单栏图标 → **"TUN 模式"** → **"开启"**

**特点**：
- ✅ 代理所有应用（包括不支持系统代理的应用）
- ✅ 无需在每个应用中单独配置
- ✅ 统一 DNS 处理
- ⚠️ 需要系统权限授权

**详细说明**：查看 [TUN模式使用指南.md](./TUN模式使用指南.md)

---

## ✅ 第5步：验证连接

### 浏览器测试

打开浏览器访问：
- https://www.google.com
- https://www.youtube.com

如果页面正常加载，说明代理工作正常！✅

### 命令行测试

在终端执行：

```bash
# 测试代理连接
curl --proxy http://127.0.0.1:7890 https://www.google.com

# 查看当前IP地址
curl --proxy http://127.0.0.1:7890 https://ip.sb
```

---

## 📋 配置文件路径

如果使用方法A导入，配置文件位置：
```
/Users/mac/Downloads/vpn/client-configs/clash-config.yaml
```

---

## 🎯 快速操作

### 切换节点
- 点击 **"代理"** 标签 → 选择不同的节点

### 开启/关闭代理
- 点击右上角的 **"系统代理"** 开关
- 或点击菜单栏图标 → **"系统代理"** → **"开启/关闭"**

### 查看连接日志
- 点击左侧菜单的 **"日志"** 标签
- 可以查看连接详情和错误信息

### 测试延迟
- 在 **"代理"** 标签中，节点旁边会显示延迟（ping）
- 延迟越低，连接越快

---

## 🐛 常见问题

### 1. 无法连接

**检查清单**：
- ✅ Clash Verge 是否已启动
- ✅ 是否选择了正确的节点（VMess-ai.bless.top）
- ✅ 系统代理是否已启用
- ✅ 查看"日志"标签是否有错误信息

### 2. 连接慢

- ✅ 检查网络连接
- ✅ 尝试重启 Clash Verge
- ✅ 查看节点延迟（在"代理"标签中）

### 3. 某些网站无法访问

- ✅ 检查代理模式（规则/全局/直连）
- ✅ 查看"日志"标签了解连接详情

---

## 📝 配置说明

当前配置的代理信息：
- **服务器**: ai.bless.top
- **端口**: 443
- **协议**: VMess (WebSocket + TLS)
- **路径**: /bs
- **本地端口**: HTTP 7890, SOCKS5 7891

---

## 🎉 完成！

配置完成后，你的所有网络流量都会通过代理服务器。可以正常访问被限制的网站了！

---

**提示**：Clash Verge 会在菜单栏显示图标，可以快速开启/关闭代理。

