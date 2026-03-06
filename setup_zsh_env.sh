#!/bin/bash

# 遇到错误即停止退出
set -e

echo "========================================================="
echo "  🚀 开始自动化配置 Zsh、Oh My Zsh 及增强插件和工具..."
echo "========================================================="

# 1. 更新 apt 并安装基础依赖软件
echo "📦 正在安装必备软件: zsh, git, curl, fzf, autojump..."
sudo apt-get update
sudo apt-get install -y zsh git curl fzf autojump

# 2. 安装 Oh My Zsh (如果未安装)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🌟 正在安装 Oh My Zsh..."
    # 使用无人值守模式 (unattended) 安装，防止安装后直接进入 zsh 阻塞脚本运行
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "✅ Oh My Zsh 已经安装，跳过."
fi

# 3. 创建存放自定义插件的目录
ZSH_CUSTOM_PLUGIN_DIR="$HOME/.zsh"
mkdir -p "$ZSH_CUSTOM_PLUGIN_DIR"

# 4. 下载增强插件
echo "🔌 正在下载 Zsh 增强插件..."

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM_PLUGIN_DIR/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_PLUGIN_DIR/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM_PLUGIN_DIR/zsh-syntax-highlighting"
fi

# zsh-completions
if [ ! -d "$ZSH_CUSTOM_PLUGIN_DIR/zsh-completions" ]; then
    git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM_PLUGIN_DIR/zsh-completions"
fi

# zsh-history-substring-search
if [ ! -d "$ZSH_CUSTOM_PLUGIN_DIR/zsh-history-substring-search" ]; then
    git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM_PLUGIN_DIR/zsh-history-substring-search"
fi

# 5. 配置 ~/.zshrc (追加写入，如果已存在就不会重复写入)
echo "⚙️ 正在配置 ~/.zshrc..."

ZSHRC_FILE="$HOME/.zshrc"

# 一个辅助写入的函数，如果检测到这行不存在才会写入
append_if_not_exists() {
    grep -qF "$1" "$ZSHRC_FILE" || echo "$1" >> "$ZSHRC_FILE"
}

# 追加插件加载源
append_if_not_exists 'source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh'
append_if_not_exists 'source ~/.zsh/zsh-completions/zsh-completions.plugin.zsh'
append_if_not_exists 'source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh'
append_if_not_exists 'source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh'

# 追加工具集成 (Ubuntu 下 autojump 通常在 /usr/share/autojump/autojump.zsh)
append_if_not_exists '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
append_if_not_exists '. /usr/share/autojump/autojump.zsh'

# 初始化额外补全配置
append_if_not_exists 'fpath=(~/.zfunc $fpath); autoload -Uz compinit && compinit'

# 6. 将当前用户的默认 Shell 更改为 zsh
echo "🔄 正在将默认 Shell 切换为 Zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    echo "✅ 默认 Shell 已更改，请在安装完成后注销或重启终端生效。"
else
    echo "✅ 当前默认 Shell 已经是 Zsh。"
fi

echo "========================================================="
echo "  🎉 安装与配置完成！"
echo "  请运行命令 'zsh' 或重新打开终端体验新的环境。"
echo "========================================================="
