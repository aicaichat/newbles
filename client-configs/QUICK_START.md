# 快速开始 - 本地使用代理

## 🚀 最快方式（推荐）

### Windows / macOS / Linux
1. **下载客户端**：
   - Windows: [v2rayN](https://github.com/2dust/v2rayN/releases)
   - macOS: [v2rayU](https://github.com/yanue/V2rayU/releases) 或 [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev/releases)
   - Linux: [v2rayA](https://github.com/v2rayA/v2rayA) 或 Clash Verge Rev

2. **导入配置**：
   - 复制以下 vmess 链接：
     ```
     vmess://eyJ2IjoiMiIsInBzIjoiYWkuYmxlc3MudG9wIiwiYWRkIjoiYWkuYmxlc3MudG9wIiwicG9ydCI6IjQ0MyIsInR5cGUiOiJub25lIiwiaWQiOiIyNWMwOWU2MC1lNjlkLTRiNmItYjExOS0zMDAxODBlZjdmYmIiLCJhaWQiOiIwIiwibmV0Ijoid3MiLCJwYXRoIjoiL2JzIiwiaG9zdCI6ImFpLmJsZXNzLnRvcCIsInRscyI6InRscyJ9
     ```
   - 在客户端中选择"从剪贴板导入"或"扫描二维码"

3. **启动代理**：启用系统代理

---

## 📋 服务器信息速查

### VMess 协议
```
服务器: ai.bless.top
端口: 443
UUID: 25c09e60-e69d-4b6b-b119-300180ef7fbb
传输: WebSocket
路径: /bs
TLS: 启用
```

### 本地代理端口
- **V2Ray**: SOCKS5 `127.0.0.1:1080`, HTTP `127.0.0.1:1081`
- **Clash**: HTTP `127.0.0.1:7890`, SOCKS5 `127.0.0.1:7891`

---

## 📱 移动端

### Android
1. 安装 [v2rayNG](https://github.com/2dust/v2rayNG/releases)
2. 导入上面的 vmess 链接
3. 启动代理

### iOS
1. 安装 Shadowrocket（App Store）
2. 添加 VMess 节点，填写服务器信息
3. 启用代理

---

## ✅ 测试连接

```bash
# 测试代理
curl --socks5 127.0.0.1:1080 https://www.google.com

# 查看IP
curl --socks5 127.0.0.1:1080 https://ip.sb
```

---

## 📁 配置文件

- **详细指南**: `LOCAL_USAGE_GUIDE.md`
- **V2Ray配置**: `v2ray-client.json`
- **Clash配置**: `clash-config.yaml`
- **分享链接**: `vmess-link.txt`

---

**更多详细信息请查看 `LOCAL_USAGE_GUIDE.md`**

