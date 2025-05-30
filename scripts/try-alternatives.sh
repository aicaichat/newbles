#!/bin/bash
set -e

echo "🔧 尝试 trojan-go 的替代方案..."

# 停止现有服务
echo "⏹️  停止现有服务..."
sudo docker-compose down 2>/dev/null || true

# 方案1：测试 Xray
echo ""
echo "🧪 方案1: 测试 Xray-core..."

if [ ! -d "xray" ]; then
    mkdir -p xray
fi

# 确保 xray 配置存在
if [ ! -f "xray/config.json" ]; then
    echo "创建 Xray 配置..."
    # 配置已经在上面创建了
fi

echo "启动 Xray..."
sudo docker run -d \
    --name xray-test \
    --restart unless-stopped \
    -p 127.0.0.1:8443:8443 \
    -v "$(pwd)/xray/config.json:/etc/xray/config.json:ro" \
    ghcr.io/xtls/xray-core:latest \
    xray -config /etc/xray/config.json

sleep 5

echo "检查 Xray 状态..."
if sudo docker ps | grep -q xray-test; then
    echo "✅ Xray 容器运行正常"
    
    # 查看日志
    echo "Xray 日志："
    sudo docker logs xray-test 2>&1 | tail -5
    
    # 测试端口
    if timeout 3 nc -z 127.0.0.1 8443; then
        echo "✅ 端口 8443 可访问"
        echo ""
        echo "🎉 Xray 方案成功！"
        echo ""
        echo "📋 使用方法："
        echo "1. nginx 反代配置保持不变"
        echo "2. Clash 配置保持不变"
        echo "3. 使用 docker-compose-xray.yml 启动: sudo docker-compose -f docker-compose-xray.yml up -d"
        echo ""
        echo "要继续使用 Xray，请执行："
        echo "  sudo docker stop xray-test && sudo docker rm xray-test"
        echo "  sudo docker-compose -f docker-compose-xray.yml up -d"
        exit 0
    else
        echo "❌ 端口 8443 不可访问"
    fi
else
    echo "❌ Xray 容器启动失败"
    sudo docker logs xray-test 2>&1 | tail -10
fi

# 清理测试容器
sudo docker stop xray-test 2>/dev/null || true
sudo docker rm xray-test 2>/dev/null || true

# 方案2：尝试不同的 trojan-go 运行方式
echo ""
echo "🧪 方案2: 尝试原生 trojan-go 运行..."

# 下载 trojan-go 二进制文件
if [ ! -f "/tmp/trojan-go" ]; then
    echo "下载 trojan-go 二进制文件..."
    wget -O /tmp/trojan-go.tar.gz https://github.com/p4gefau1t/trojan-go/releases/download/v0.10.6/trojan-go-linux-amd64.tar.gz
    tar -xzf /tmp/trojan-go.tar.gz -C /tmp/
    chmod +x /tmp/trojan-go
fi

echo "尝试原生运行 trojan-go..."
timeout 10 /tmp/trojan-go -config trojan-go/config.json &
NATIVE_PID=$!
sleep 3

if kill -0 $NATIVE_PID 2>/dev/null; then
    echo "✅ 原生 trojan-go 运行成功"
    
    if timeout 3 nc -z 127.0.0.1 8443; then
        echo "✅ 端口 8443 可访问"
        echo ""
        echo "🎉 原生运行成功！可能是 Docker 环境问题"
        echo "建议使用原生安装而不是 Docker"
    fi
    
    kill $NATIVE_PID 2>/dev/null || true
else
    echo "❌ 原生 trojan-go 也失败"
fi

echo ""
echo "📊 总结："
echo "如果 Xray 成功，建议切换到 Xray"
echo "如果原生成功，建议使用原生安装"
echo "否则可能需要考虑其他代理协议" 