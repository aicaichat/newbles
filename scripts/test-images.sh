#!/bin/bash
set -e

echo "🐳 测试不同的 trojan-go 镜像..."

# 镜像列表
IMAGES=(
    "p4gefau1t/trojan-go:latest"
    "trojango/trojan-go:latest"  
    "teddysun/trojan-go:v0.10.6"
)

# 恢复简单的 websocket 配置
echo "📝 使用简单的 websocket 配置..."
cat > trojan-go/config.json << 'EOF'
{
  "run_type": "server",
  "local_addr": "127.0.0.1",
  "local_port": 8443,
  "remote_addr": "httpbin.org",
  "remote_port": 80,
  "password": [
    "mySecureBlessPassword123"
  ],
  "websocket": {
    "enabled": true,
    "path": "/bs",
    "host": "ai.bless.top"
  }
}
EOF

# 备份原 docker-compose
cp docker-compose.yml docker-compose.yml.backup

for IMAGE in "${IMAGES[@]}"; do
    echo ""
    echo "🧪 测试镜像: $IMAGE"
    
    # 停止当前容器
    sudo docker-compose down 2>/dev/null || true
    
    # 更新镜像
    sed -i "s|image:.*|image: $IMAGE|" docker-compose.yml
    
    echo "启动容器..."
    sudo docker-compose up -d
    
    # 等待启动
    sleep 8
    
    # 检查日志
    echo "检查日志..."
    LOGS=$(sudo docker logs trojan-go 2>&1 | tail -10)
    
    if echo "$LOGS" | grep -q "tls failed to load key pair"; then
        echo "❌ $IMAGE 失败 - 仍有 TLS 错误"
    elif echo "$LOGS" | grep -q "listening\|server started\|websocket enabled"; then
        echo "✅ $IMAGE 成功启动！"
        echo "成功的日志："
        echo "$LOGS"
        
        # 测试端口
        if timeout 3 nc -z 127.0.0.1 8443; then
            echo "✅ 端口 8443 可访问"
            echo ""
            echo "🎉 找到可用镜像: $IMAGE"
            echo "配置文件已保存，可以继续使用"
            break
        else
            echo "⚠️  端口 8443 不可访问，但容器启动了"
        fi
    else
        echo "❓ $IMAGE 状态不明确"
        echo "日志:"
        echo "$LOGS"
    fi
    
    # 短暂停顿
    sleep 2
done

echo ""
echo "📊 当前容器状态:"
sudo docker ps | grep trojan-go || echo "没有运行的 trojan-go 容器"

echo ""
echo "🔍 如需查看详细日志: sudo docker logs trojan-go" 