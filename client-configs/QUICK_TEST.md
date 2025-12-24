# 快速测试 Clash 配置

## 🚀 最快测试方法（3步）

### 方法1：使用测试脚本（最简单）

```bash
# 进入配置目录
cd /Users/mac/Downloads/vpn/client-configs

# 运行测试脚本
./test-clash.sh
```

这个脚本会自动测试：
- ✅ 服务器连接
- ✅ 端口连通性
- ✅ UUID 格式
- ✅ Clash 服务状态
- ✅ 代理功能
- ✅ IP 地址变化

---

### 方法2：使用 Clash 客户端（推荐）

1. **下载并安装 Clash Verge Rev**
   - Windows: https://github.com/clash-verge-rev/clash-verge-rev/releases
   - macOS: `brew install --cask clash-verge-rev`

2. **导入配置文件**
   - 打开 Clash Verge Rev
   - 导入 `clash-config.yaml` 文件

3. **测试连接**
   - 选择节点：`VMess-ai.bless.top`
   - 启用系统代理
   - 访问 https://www.google.com
   - 访问 https://ip.sb 查看IP

---

### 方法3：命令行快速测试

```bash
# 1. 测试服务器连接
curl -v https://ai.bless.top/bs

# 2. 测试端口
nc -zv ai.bless.top 443

# 3. 如果 Clash 正在运行，测试代理
curl -x http://127.0.0.1:7890 https://ip.sb

# 4. 对比本地IP和代理IP
echo "本地IP:"
curl -s https://ip.sb
echo "代理IP:"
curl -s -x http://127.0.0.1:7890 https://ip.sb
```

---

## ✅ 成功标志

配置测试成功的标志：

1. ✅ **服务器可达**：能连接到 `ai.bless.top:443`
2. ✅ **Clash 启动**：端口 7890 和 7891 正在监听
3. ✅ **代理工作**：能通过代理访问网站
4. ✅ **IP 改变**：代理IP与本地IP不同
5. ✅ **能访问 Google**：通过代理可以访问 Google

---

## 🐛 如果测试失败

### 问题1：无法连接服务器
```bash
# 检查服务器状态
ping ai.bless.top

# 检查端口
nc -zv ai.bless.top 443
```

### 问题2：Clash 未运行
```bash
# 启动 Clash（命令行）
clash -d ~/.config/clash

# 或使用 Clash Verge Rev 客户端
```

### 问题3：代理不工作
- 检查 Clash 日志
- 确认选择了正确的代理节点
- 检查配置参数是否正确

---

## 📋 配置参数检查清单

确保以下参数正确：

- [x] 服务器：`ai.bless.top`
- [x] 端口：`443`
- [x] UUID：`25c09e60-e69d-4b6b-b119-300180ef7fbb`
- [x] 路径：`/bs`
- [x] TLS：`true`
- [x] 网络：`ws` (WebSocket)

---

**详细测试方法请查看 `TEST_CLASH_CONFIG.md`**

