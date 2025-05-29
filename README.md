# Trojan-Go Docker 一键部署（含 Clash 配置导出）

## 目录结构

```
vpn/
  docker-compose.yml
  trojan-go/
    config.json
  cert/
    # 证书文件自动生成
  clash/
    clash-config.yaml
    trojan-proxy-snippet.yaml
  scripts/
    apply-cert.sh
    deploy.sh
```

## 部署流程

1. 修改 `scripts/apply-cert.sh` 中的邮箱（可选）
2. 运行一键部署脚本：
   ```bash
   bash scripts/deploy.sh
   ```
3. Clash 配置文件生成于 `clash/clash-config.yaml`

## 其他说明
- 证书自动续期，trojan-go 容器自动重载
- Clash 代理片段见 `clash/trojan-proxy-snippet.yaml` 