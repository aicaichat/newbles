#!/bin/bash
set -e

echo "🧪 测试 Xray 替代方案..."

# 停止现有服务
echo "⏹️  停止现有服务..."
sudo docker-compose down 2>/dev/null || true
sudo docker stop xray-test 2>/dev/null || true
sudo docker rm xray-test 2>/dev/null || true

# 安装 netcat（如果没有）
if ! command -v nc &> /dev/null; then
    echo "📦 安装 netcat..."
    sudo yum install -y nc 2>/dev/null || sudo apt-get install -y netcat 2>/dev/null || echo "请手动安装 nc 工具"
fi

echo ""
echo "🚀 启动 Xray..."
sudo docker-compose -f docker-compose-xray.yml up -d

# 等待启动
sleep 8

echo "🔍 检查 Xray 状态..."
if sudo docker ps | grep -q xray-trojan; then
    echo "✅ Xray 容器运行正常"
    
    # 查看日志
    echo ""
    echo "📋 Xray 日志："
    sudo docker logs xray-trojan
    
    echo ""
    echo "🧪 测试端口连接..."
    
    # 测试方法1：使用 telnet
    if command -v telnet &> /dev/null; then
        echo "使用 telnet 测试端口..."
        timeout 3 telnet 127.0.0.1 8443 < /dev/null && echo "✅ 端口 8443 可访问" || echo "telnet 测试完成"
    fi
    
    # 测试方法2：使用 curl
    echo "使用 curl 测试端口..."
    curl -v --connect-timeout 3 127.0.0.1:8443 2>&1 | head -5 || echo "curl 测试完成"
    
    # 测试方法3：检查端口监听
    echo ""
    echo "检查端口监听状态："
    sudo netstat -tlnp | grep 8443 || echo "未找到 8443 端口监听"
    
    # 测试方法4：docker 内部端口检查
    echo ""
    echo "检查容器内端口："
    sudo docker exec xray-trojan netstat -tln | grep 8443 || echo "容器内未监听 8443"
    
    echo ""
    if sudo docker logs xray-trojan 2>&1 | grep -qE "(started|listening|ready)"; then
        echo "✅ Xray 看起来启动成功！"
        echo ""
        echo "🎉 下一步："
        echo "1. 测试 nginx 到 Xray 的连接"
        echo "2. 测试 Clash 客户端连接"
        echo ""
        echo "🔧 测试 nginx 反代："
        echo "curl -H 'Upgrade: websocket' -H 'Connection: Upgrade' -H 'Host: ai.bless.top' https://ai.bless.top/bs"
    else
        echo "❌ Xray 可能启动失败，请检查日志"
    fi
    
else
    echo "❌ Xray 容器启动失败"
    sudo docker logs xray-trojan 2>&1 || echo "无法获取日志"
fi

echo ""
echo "📊 当前状态："
sudo docker ps | grep xray || echo "没有运行的 xray 容器" 