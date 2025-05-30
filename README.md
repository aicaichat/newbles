# VPN 代理服务部署

这个项目包含多种代理服务的配置，包括 V2Ray 和 Xray 的 Docker 部署配置。

## 目录结构

```
vpn/
├── v2ray/                    # V2Ray 配置文件
│   ├── config.json          # V2Ray 后端配置（nginx 反代）
│   └── config-direct.json   # V2Ray 直接暴露配置
├── xray/                    # Xray 配置文件
│   └── config.json          # Xray Trojan 配置
├── client-configs/          # 客户端配置示例
│   ├── v2ray-client.json    # V2Ray 客户端配置
│   └── xray-trojan-client.json # Xray Trojan 客户端配置
├── docker-compose-v2ray.yml        # V2Ray 后端部署
├── docker-compose-v2ray-direct.yml # V2Ray 直接暴露部署
├── docker-compose-xray.yml         # Xray 部署
└── cert/                    # 证书目录
```

## 部署说明

### 1. V2Ray 后端模式（推荐）
```bash
# 使用 nginx 作为前端反向代理
docker-compose -f docker-compose-v2ray.yml up -d
```

### 2. V2Ray 直接暴露模式
```bash
# 直接暴露 443 端口，需要停止 nginx
docker-compose -f docker-compose-v2ray-direct.yml up -d
```

### 3. Xray Trojan 模式
```bash
# 使用 Xray 的 Trojan 协议
docker-compose -f docker-compose-xray.yml up -d
```

## 重要说明

- 所有配置中的 UUID 和密码都是示例，部署前请修改
- 证书路径：`/root/newbles/cert/`
- WebSocket 路径：`/bs`
- 域名：`ai.bless.top`

## 客户端配置

客户端配置示例文件位于 `client-configs/` 目录中，根据服务端部署方式选择对应的客户端配置。 