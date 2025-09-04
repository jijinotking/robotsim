#!/bin/bash

# Ubuntu环境问题修复脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================"
echo "🔧 Ubuntu环境问题修复"
echo "========================================"
echo ""

# 1. 修复PPA源问题
fix_ppa_sources() {
    log_step "修复PPA源问题..."
    
    # 删除有问题的PPA源
    if [ -f "/etc/apt/sources.list.d/jonathonf-ubuntu-ffmpeg-4-jammy.list" ]; then
        log_info "删除有问题的ffmpeg-4 PPA源..."
        sudo rm -f /etc/apt/sources.list.d/jonathonf-ubuntu-ffmpeg-4-jammy.list
    fi
    
    # 清理apt缓存
    log_info "清理apt缓存..."
    sudo apt clean
    sudo apt autoclean
    
    # 更新软件源
    log_info "更新软件源..."
    sudo apt update
    
    log_info "PPA源问题修复完成 ✓"
}

# 2. 修复conda环境冲突
fix_conda_conflicts() {
    log_step "修复conda环境冲突..."
    
    # 临时禁用conda环境
    if [[ "$CONDA_DEFAULT_ENV" != "" ]]; then
        log_info "检测到活跃的conda环境: $CONDA_DEFAULT_ENV"
        log_info "建议在base环境中运行安装脚本"
        
        # 切换到base环境
        if command -v conda &> /dev/null; then
            log_info "切换到conda base环境..."
            conda activate base 2>/dev/null || true
        fi
    fi
    
    # 检查libtinfo冲突
    if [ -f "$CONDA_PREFIX/lib/libtinfo.so.6" ]; then
        log_warn "检测到conda环境中的libtinfo库可能与系统冲突"
        log_info "建议临时重命名该文件"
        
        read -p "是否临时重命名冲突的库文件？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mv "$CONDA_PREFIX/lib/libtinfo.so.6" "$CONDA_PREFIX/lib/libtinfo.so.6.backup" 2>/dev/null || true
            log_info "已备份冲突的库文件"
        fi
    fi
    
    log_info "conda环境冲突修复完成 ✓"
}

# 3. 安装必要的依赖
install_dependencies() {
    log_step "安装必要的依赖..."
    
    # 更新包列表
    sudo apt update
    
    # 安装基础工具
    local basic_packages=(
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "curl"
        "wget"
    )
    
    for package in "${basic_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            log_info "安装 $package..."
            sudo apt install -y "$package"
        else
            log_info "$package 已安装 ✓"
        fi
    done
    
    log_info "依赖安装完成 ✓"
}

# 4. 创建干净的安装环境
create_clean_environment() {
    log_step "创建干净的安装环境..."
    
    # 创建临时脚本，在干净环境中运行
    cat > /tmp/clean_install.sh << 'EOF'
#!/bin/bash

# 在干净环境中运行安装
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
unset CONDA_DEFAULT_ENV
unset CONDA_PREFIX
unset CONDA_PYTHON_EXE
unset CONDA_EXE

# 运行原始安装脚本
cd "$1"
./setup_ubuntu_environment.sh
EOF
    
    chmod +x /tmp/clean_install.sh
    
    log_info "干净环境脚本创建完成 ✓"
}

# 5. 验证修复结果
verify_fixes() {
    log_step "验证修复结果..."
    
    # 检查apt源
    if sudo apt update 2>&1 | grep -q "错误\|Error"; then
        log_warn "apt源仍有问题，但可能不影响安装"
    else
        log_info "apt源正常 ✓"
    fi
    
    # 检查基本命令
    local commands=("curl" "wget" "sudo" "apt")
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            log_info "$cmd 可用 ✓"
        else
            log_error "$cmd 不可用"
        fi
    done
    
    log_info "修复验证完成 ✓"
}

# 主函数
main() {
    log_info "开始修复Ubuntu环境问题..."
    echo ""
    
    fix_ppa_sources
    echo ""
    
    fix_conda_conflicts
    echo ""
    
    install_dependencies
    echo ""
    
    create_clean_environment
    echo ""
    
    verify_fixes
    echo ""
    
    echo "========================================"
    echo "✅ 修复完成！"
    echo "========================================"
    echo ""
    echo "现在可以重新运行安装脚本："
    echo ""
    echo "方法1 (推荐): 在干净环境中运行"
    echo "  /tmp/clean_install.sh $(pwd)"
    echo ""
    echo "方法2: 直接运行"
    echo "  ./setup_ubuntu_environment.sh"
    echo ""
    echo "方法3: 手动安装"
    echo "  按照QUICK_DEPLOY_GUIDE.md中的手动部署步骤"
    echo ""
    echo "========================================"
}

# 运行主函数
main "$@"