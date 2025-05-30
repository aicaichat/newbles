#!/bin/bash
set -e

echo "🧪 测试不同的 trojan-go 配置..."

# 停止当前容器
sudo docker-compose down

echo "📋 当前可用的配置文件："
echo "1. trojan-go/config.json (transport 配置)"
echo "2. trojan-go/config.json.websocket (完整 websocket 配置)"

echo ""
echo "🔍 检查容器内配置同步..."

# 方案1：使用当前 transport 配置
echo "方案1：测试 transport 配置..."
sudo docker-compose up -d
sleep 5

echo "容器内配置文件："
sudo docker exec trojan-go cat /config.json 2>/dev/null || echo "无法读取容器内配置"

echo "trojan-go 日志："
sudo docker logs trojan-go 2>&1 | tail -5

# 检查是否还有 TLS 错误
if sudo docker logs trojan-go 2>&1 | grep -q "tls failed to load key pair"; then
    echo "❌ 方案1失败，仍有 TLS 错误"
    
    echo ""
    echo "方案2：尝试完整 websocket 配置..."
    
    # 停止容器
    sudo docker-compose down
    
    # 备份原配置
    cp trojan-go/config.json trojan-go/config.json.backup
    
    # 使用新配置
    cp trojan-go/config.json.websocket trojan-go/config.json
    
    # 重新启动
    sudo docker-compose up -d --force-recreate
    sleep 5
    
    echo "新配置下的日志："
    sudo docker logs trojan-go 2>&1 | tail -5
    
    if sudo docker logs trojan-go 2>&1 | grep -q "tls failed to load key pair"; then
        echo "❌ 方案2也失败"
        echo ""
        echo "🔧 可能需要："
        echo "1. 检查 trojan-go 镜像版本"
        echo "2. 使用不同的 trojan-go 实现"
        echo "3. 检查是否需要其他配置参数"
        
        # 恢复原配置
        cp trojan-go/config.json.backup trojan-go/config.json
    else
        echo "✅ 方案2成功！"
    fi
else
    echo "✅ 方案1成功！"
fi

echo ""
echo "📊 当前服务状态："
sudo docker ps | grep trojan-go
echo ""
echo "🔍 查看完整日志: sudo docker logs trojan-go" 