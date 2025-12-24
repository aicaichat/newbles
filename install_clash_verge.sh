#!/bin/bash

set -e

echo "==== 安装 Clash Verge for macOS ===="

# 1. 安装 Homebrew（如果未安装）
if ! command -v brew &>/dev/null; then
  echo "Homebrew 未安装，正在安装..."
  /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"
fi

# 2. 安装 Clash Verge
brew tap clash-verge-rev/clash-verge
brew install --cask clash-verge

echo "==== Clash Verge 安装完成！===="

# 3. 打开 Clash Verge
open -a "Clash Verge"

echo "==== 请在 Clash Verge 中导入你的 clash-config.yaml 配置文件 ===="
echo "1. 打开 Clash Verge"
echo "2. 点击左侧 Profiles（配置文件）"
echo "3. 选择 Import（导入）-> 选择你的 clash-config.yaml"
echo "4. 选择节点，启用系统代理即可科学上网！"