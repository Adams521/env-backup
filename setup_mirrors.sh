#!/bin/bash

# 遇到错误即停止退出
set -e

echo "========================================================="
echo "  🚀 开始自动化配置 APT、Docker 和 NVM/NPM 镜像源..."
echo "========================================================="

# ==========================================
# 1. 替换 APT 镜像源 (适用于 Ubuntu 22.04 Jammy)
# ==========================================
echo "📦 正在配置 APT 源 (阿里云 Jammy 镜像)..."

APT_SOURCE_FILE="/etc/apt/sources.list"
if [ ! -f "${APT_SOURCE_FILE}.bak" ]; then
    sudo cp $APT_SOURCE_FILE "${APT_SOURCE_FILE}.bak"
    echo "已备份原生的 sources.list 到 sources.list.bak"
fi

sudo cat > $APT_SOURCE_FILE << 'EOF'
deb https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse

deb https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
EOF

echo "✓ APT 源替换完成，正在执行 apt-get update..."
sudo apt-get update > /dev/null 2>&1 || echo "⚠️ 更新 apt 源缓存时遇到一些小警告，但这通常不影响使用。"


# ==========================================
# 2. 配置 Docker daemon.json
# ==========================================
echo "🐳 正在配置 Docker 镜像加速及容器运行时设定..."

DOCKER_CONFIG_DIR="/etc/docker"
DOCKER_DAEMON_FILE="$DOCKER_CONFIG_DIR/daemon.json"

sudo mkdir -p $DOCKER_CONFIG_DIR
if [ -f "$DOCKER_DAEMON_FILE" ] && [ ! -f "${DOCKER_DAEMON_FILE}.bak" ]; then
    sudo cp $DOCKER_DAEMON_FILE "${DOCKER_DAEMON_FILE}.bak"
    echo "已备份原生的 daemon.json 到 daemon.json.bak"
fi

sudo cat > $DOCKER_DAEMON_FILE << 'EOF'
{
  "default-address-pools": [
      {
          "base": "10.200.0.0/12",
          "size": 24
      }
  ],
  "builder": {
      "gc": {
          "defaultKeepStorage": "20GB",
          "enabled": true
      }
  },
  "experimental": false,
  "registry-mirrors": [
      "https://docker.1panel.live",
      "https://docker.1ms.run",
      "https://dytt.online",
      "https://docker-0.unsee.tech",
      "https://lispy.org",
      "https://docker.xiaogenban1993.com",
      "https://666860.xyz",
      "https://hub.rat.dev",
      "https://docker.m.daocloud.io",
      "https://demo.52013120.xyz",
      "https://proxy.vvvv.ee",
      "https://registry.cyou",
      "https://mirror.ccs.tencentyun.com",
      "https://<your_code>.mirror.aliyuncs.com"
  ],
  "runtimes": {
      "nvidia": {
          "args": [],
          "path": "nvidia-container-runtime"
      }
  }
}
EOF

# 重启 Docker 以使配置生效 (如果已安装 Docker 的话)
if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet docker; then
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "✓ Docker 配置已应用并重启了 Docker 服务。"
else
    echo "⚠️ 尚未安装 Docker 或 Docker 未在运行。配置文件已被放置，安装后会自动挂载生效。"
fi


# ==========================================
# 3. 配置 NVM 和 NPM 镜像源 (当前用户)
# ==========================================
echo "🌐 正在为您当前的用户配置 NVM 与 NPM 的国内镜像源..."

# 确保以当前用户身份操作，而不是 root
USER_BASHRC="$HOME/.bashrc"
USER_ZSHRC="$HOME/.zshrc"

NVM_MIRROR_SETTINGS="
# === NVM 和 NodeJS 镜像源 ===
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs
"

# 注入 Bash
if ! grep -q "NVM_NODEJS_ORG_MIRROR" "$USER_BASHRC" 2>/dev/null; then
    echo "$NVM_MIRROR_SETTINGS" >> "$USER_BASHRC"
fi

# 注入 Zsh (如果存在的话)
if [ -f "$USER_ZSHRC" ]; then
    if ! grep -q "NVM_NODEJS_ORG_MIRROR" "$USER_ZSHRC" 2>/dev/null; then
        echo "$NVM_MIRROR_SETTINGS" >> "$USER_ZSHRC"
    fi
fi

# 顺便设置 npm 全局的安装 registry 源 (淘宝/阿里源)
if command -v npm >/dev/null 2>&1; then
    npm config set registry https://registry.npmmirror.com/
    echo "✓ NPM registry 已被设置为 npmmirror。"
else
    # 如果还没有安装 npm，直接为其写入配置文件
    echo "registry=https://registry.npmmirror.com/" > "$HOME/.npmrc"
    echo "✓ 已生成 .npmrc 文件设置 npm registry 为 npmmirror。"
fi

echo "========================================================="
echo "  🎉 所有的国内加速源及镜像均已配置完成！"
echo "  请运行命令 'source ~/.bashrc' 或重新打开终端让 NVM 镜像生效。"
echo "========================================================="
