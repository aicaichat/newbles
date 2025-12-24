# Clash 配置测试指南

本指南提供多种方法测试你的 Clash 配置是否真的可行。

## 🧪 方法1：使用 Clash 客户端测试（推荐）

### 步骤1：安装 Clash 客户端

**Windows:**
- 下载 [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev/releases)
- 或 [Clash for Windows](https://github.com/Fndroid/clash_for_windows_pkg/releases)

**macOS:**
```bash
brew install --cask clash-verge-rev
```

**Linux:**
- 下载 [Clash Verge Rev AppImage](https://github.com/clash-verge-rev/clash-verge-rev/releases)

### 步骤2：导入配置

1. 打开 Clash 客户端
2. 创建配置文件（如 `test-config.yaml`）
3. 将你的配置粘贴进去：

```yaml
port: 7890
socks-port: 7891
redir-port: 7892
mixed-port: 7890
allow-lan: true
mode: Rule
log-level: info
external-controller: 127.0.0.1:9090

proxies:
  - name: "VMess-ai.bless.top"
    type: vmess
    server: ai.bless.top
    port: 443
    uuid: 25c09e60-e69d-4b6b-b119-300180ef7fbb
    alterId: 0
    cipher: auto
    tls: true
    skip-cert-verify: false
    servername: ai.bless.top
    network: ws
    ws-opts:
      path: /bs
      headers:
        Host: ai.bless.top

proxy-groups:
  - name: "Proxy"
    type: select
    proxies:
      - "VMess-ai.bless.top"
      - DIRECT

rules:
  - MATCH,Proxy
```

4. 保存并加载配置

### 步骤3：测试连接

1. **选择节点**：在客户端中选择 `VMess-ai.bless.top`
2. **启用系统代理**：打开系统代理开关
3. **测试延迟**：右键节点 → 测试延迟（或点击延迟测试）
4. **访问测试网站**：
   - https://www.google.com
   - https://www.youtube.com
   - https://ip.sb （查看当前IP）

### 步骤4：检查日志

在客户端中查看日志，确认：
- ✅ 连接成功：看到 "connected" 或 "proxy VMess-ai.bless.top"
- ❌ 连接失败：查看错误信息

---

## 🖥️ 方法2：使用命令行 Clash 测试

### 安装 Clash

**macOS:**
```bash
brew install clash
```

**Linux:**
```bash
# 下载最新版本
wget https://github.com/Dreamacro/clash/releases/download/v1.18.0/clash-linux-amd64-v1.18.0.gz
gunzip clash-linux-amd64-v1.18.0.gz
chmod +x clash-linux-amd64-v1.18.0
sudo mv clash-linux-amd64-v1.18.0 /usr/local/bin/clash
```

**Windows:**
- 下载 [Clash for Windows](https://github.com/Fndroid/clash_for_windows_pkg/releases)

### 创建测试配置文件

```bash
# 创建测试配置目录
mkdir -p ~/.config/clash-test
cd ~/.config/clash-test

# 创建配置文件
cat > config.yaml << 'EOF'
port: 7890
socks-port: 7891
redir-port: 7892
mixed-port: 7890
allow-lan: true
mode: Rule
log-level: info
external-controller: 127.0.0.1:9090

proxies:
  - name: "VMess-ai.bless.top"
    type: vmess
    server: ai.bless.top
    port: 443
    uuid: 25c09e60-e69d-4b6b-b119-300180ef7fbb
    alterId: 0
    cipher: auto
    tls: true
    skip-cert-verify: false
    servername: ai.bless.top
    network: ws
    ws-opts:
      path: /bs
      headers:
        Host: ai.bless.top

proxy-groups:
  - name: "Proxy"
    type: select
    proxies:
      - "VMess-ai.bless.top"
      - DIRECT

rules:
  - MATCH,Proxy
EOF
```

### 启动 Clash 并测试

```bash
# 启动 Clash（前台运行，方便查看日志）
clash -d ~/.config/clash-test

# 在另一个终端测试
# 测试 HTTP 代理
curl -x http://127.0.0.1:7890 https://www.google.com -I

# 测试 SOCKS5 代理
curl --socks5 127.0.0.1:7891 https://www.google.com -I

# 查看当前IP
curl -x http://127.0.0.1:7890 https://ip.sb

# 测试延迟
time curl -x http://127.0.0.1:7890 https://www.google.com -I
```

---

## 🔍 方法3：配置语法验证

### 使用 yq 验证 YAML 语法

```bash
# 安装 yq
brew install yq  # macOS
# 或
sudo apt install yq  # Linux

# 验证配置文件语法
yq eval . test-config.yaml

# 如果语法正确，会输出配置内容
# 如果语法错误，会显示错误信息
```

### 使用 Python 验证

```bash
# 创建验证脚本
cat > validate_clash.py << 'EOF'
import yaml
import sys

try:
    with open('test-config.yaml', 'r') as f:
        config = yaml.safe_load(f)
    
    # 检查必需字段
    required_fields = ['proxies', 'proxy-groups', 'rules']
    for field in required_fields:
        if field not in config:
            print(f"❌ 缺少必需字段: {field}")
            sys.exit(1)
    
    # 检查代理配置
    if not config['proxies']:
        print("❌ proxies 列表为空")
        sys.exit(1)
    
    proxy = config['proxies'][0]
    required_proxy_fields = ['name', 'type', 'server', 'port', 'uuid']
    for field in required_proxy_fields:
        if field not in proxy:
            print(f"❌ 代理配置缺少字段: {field}")
            sys.exit(1)
    
    print("✅ 配置文件语法正确")
    print(f"✅ 代理名称: {proxy['name']}")
    print(f"✅ 服务器: {proxy['server']}:{proxy['port']}")
    
except yaml.YAMLError as e:
    print(f"❌ YAML 语法错误: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ 验证失败: {e}")
    sys.exit(1)
EOF

# 运行验证
python3 validate_clash.py
```

---

## 🌐 方法4：直接测试服务器连接

### 测试服务器可达性

```bash
# 测试域名解析
nslookup ai.bless.top
# 或
dig ai.bless.top

# 测试端口连通性
nc -zv ai.bless.top 443
# 或
telnet ai.bless.top 443

# 测试 HTTPS 连接
curl -v https://ai.bless.top/bs
```

### 测试 WebSocket 连接

```bash
# 使用 wscat 测试 WebSocket
# 安装 wscat
npm install -g wscat

# 测试 WebSocket 连接
wscat -c wss://ai.bless.top/bs \
  -H "Host: ai.bless.top" \
  -H "User-Agent: Mozilla/5.0"
```

---

## 🧪 方法5：使用在线工具测试

### 使用 Clash 配置验证器

1. 访问 [Clash 配置生成器](https://www.v2fly.org/config/outbound.html)
2. 将配置转换为 JSON 格式验证
3. 检查配置项是否完整

### 使用代理测试工具

```bash
# 使用 proxychains 测试
# 安装 proxychains
brew install proxychains-ng  # macOS
sudo apt install proxychains  # Linux

# 配置 proxychains
echo "socks5 127.0.0.1 7891" >> /etc/proxychains.conf

# 测试
proxychains curl https://www.google.com
```

---

## 📊 方法6：完整测试脚本

创建一个完整的测试脚本：

```bash
cat > test_clash_config.sh << 'EOF'
#!/bin/bash

echo "🧪 Clash 配置测试脚本"
echo "===================="

CONFIG_FILE="test-config.yaml"
CLASH_PORT=7890
SOCKS_PORT=7891

# 1. 检查配置文件是否存在
echo ""
echo "1️⃣ 检查配置文件..."
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 配置文件不存在: $CONFIG_FILE"
    exit 1
fi
echo "✅ 配置文件存在"

# 2. 验证 YAML 语法
echo ""
echo "2️⃣ 验证 YAML 语法..."
if command -v yq &> /dev/null; then
    if yq eval . "$CONFIG_FILE" > /dev/null 2>&1; then
        echo "✅ YAML 语法正确"
    else
        echo "❌ YAML 语法错误"
        yq eval . "$CONFIG_FILE"
        exit 1
    fi
else
    echo "⚠️  yq 未安装，跳过语法验证"
fi

# 3. 检查必需字段
echo ""
echo "3️⃣ 检查配置字段..."
if grep -q "proxies:" "$CONFIG_FILE" && \
   grep -q "proxy-groups:" "$CONFIG_FILE" && \
   grep -q "rules:" "$CONFIG_FILE"; then
    echo "✅ 必需字段存在"
else
    echo "❌ 缺少必需字段"
    exit 1
fi

# 4. 检查代理配置
echo ""
echo "4️⃣ 检查代理配置..."
if grep -q "server: ai.bless.top" "$CONFIG_FILE" && \
   grep -q "uuid: 25c09e60-e69d-4b6b-b119-300180ef7fbb" "$CONFIG_FILE" && \
   grep -q "path: /bs" "$CONFIG_FILE"; then
    echo "✅ 代理配置正确"
else
    echo "❌ 代理配置不完整"
    exit 1
fi

# 5. 测试服务器连接
echo ""
echo "5️⃣ 测试服务器连接..."
if nc -zv -w 5 ai.bless.top 443 2>&1 | grep -q "succeeded"; then
    echo "✅ 服务器端口 443 可访问"
else
    echo "❌ 无法连接到服务器端口 443"
    echo "   请检查："
    echo "   - 服务器是否运行"
    echo "   - 防火墙是否开放端口"
    echo "   - 域名是否正确"
fi

# 6. 测试 Clash 是否运行
echo ""
echo "6️⃣ 检查 Clash 服务..."
if nc -zv -w 2 127.0.0.1 $CLASH_PORT 2>&1 | grep -q "succeeded"; then
    echo "✅ Clash HTTP 代理端口 $CLASH_PORT 正在监听"
    
    # 测试代理功能
    echo ""
    echo "7️⃣ 测试代理功能..."
    TEST_URL="https://ip.sb"
    PROXY_IP=$(curl -s -x http://127.0.0.1:$CLASH_PORT $TEST_URL --max-time 10)
    
    if [ -n "$PROXY_IP" ]; then
        echo "✅ 代理工作正常"
        echo "   当前IP: $PROXY_IP"
        
        # 测试访问 Google
        echo ""
        echo "8️⃣ 测试访问 Google..."
        if curl -s -x http://127.0.0.1:$CLASH_PORT https://www.google.com -I --max-time 10 | grep -q "HTTP"; then
            echo "✅ 可以访问 Google"
        else
            echo "⚠️  无法访问 Google（可能是网络问题）"
        fi
    else
        echo "❌ 代理无法正常工作"
        echo "   请检查："
        echo "   - Clash 是否正常运行"
        echo "   - 配置是否正确加载"
        echo "   - 节点是否可用"
    fi
else
    echo "⚠️  Clash 未运行或端口未监听"
    echo "   请先启动 Clash："
    echo "   clash -d ~/.config/clash"
fi

echo ""
echo "===================="
echo "✅ 测试完成"
EOF

chmod +x test_clash_config.sh
./test_clash_config.sh
```

---

## 🔧 方法7：使用 Clash API 测试

如果 Clash 正在运行，可以使用 API 测试：

```bash
# 检查 Clash 是否运行
curl http://127.0.0.1:9090/version

# 获取代理列表
curl http://127.0.0.1:9090/proxies

# 测试特定代理
curl -X PUT http://127.0.0.1:9090/proxies/Proxy \
  -H "Content-Type: application/json" \
  -d '{"name": "VMess-ai.bless.top"}'

# 测试代理延迟
curl http://127.0.0.1:9090/proxies/VMess-ai.bless.top/delay?timeout=5000&url=https://www.google.com

# 获取当前使用的代理
curl http://127.0.0.1:9090/proxies/Proxy
```

---

## ✅ 成功标准

配置测试成功的标志：

1. ✅ **配置文件语法正确**：YAML 格式无误
2. ✅ **服务器可达**：能连接到 `ai.bless.top:443`
3. ✅ **Clash 启动成功**：无错误日志
4. ✅ **代理端口监听**：`7890` 和 `7891` 端口正常
5. ✅ **代理功能正常**：能通过代理访问网站
6. ✅ **IP 已改变**：通过代理访问时 IP 发生变化
7. ✅ **延迟合理**：代理延迟在可接受范围内（< 500ms）

---

## 🐛 常见问题排查

### 问题1：配置文件语法错误
```bash
# 检查缩进（YAML 对缩进敏感）
# 确保使用空格而不是 Tab
# 检查冒号后是否有空格
```

### 问题2：无法连接服务器
```bash
# 检查服务器状态
ping ai.bless.top

# 检查端口
nc -zv ai.bless.top 443

# 检查防火墙
```

### 问题3：代理无法工作
```bash
# 检查 Clash 日志
tail -f ~/.config/clash/logs/clash.log

# 检查代理选择
# 确保选择了正确的代理节点
```

### 问题4：UUID 错误
```bash
# 验证 UUID 格式
echo "25c09e60-e69d-4b6b-b119-300180ef7fbb" | grep -E "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
```

---

## 📝 快速测试清单

- [ ] 配置文件语法正确
- [ ] 服务器地址正确：`ai.bless.top`
- [ ] 端口正确：`443`
- [ ] UUID 正确：`25c09e60-e69d-4b6b-b119-300180ef7fbb`
- [ ] WebSocket 路径正确：`/bs`
- [ ] TLS 已启用：`tls: true`
- [ ] Clash 启动成功
- [ ] 代理端口正常监听
- [ ] 能通过代理访问网站
- [ ] IP 地址已改变

---

**完成以上测试后，你的配置就可以正常使用了！** 🎉

