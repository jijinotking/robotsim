#!/bin/bash

# 简化版Ubuntu环境安装脚本
# 避免conda冲突，只安装必要的Qt5和编译环境

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
echo "🤖 机器人控制上位机 - 简化安装"
echo "========================================"
echo ""
echo "这个脚本只安装Qt5开发环境和编译工具"
echo "不会安装或修改conda环境"
echo ""

# 检查系统
check_system() {
    log_step "检查系统环境..."
    
    if ! command -v lsb_release &> /dev/null; then
        log_error "无法检测Ubuntu版本"
        exit 1
    fi
    
    local version=$(lsb_release -rs)
    log_info "系统版本: Ubuntu $version ✓"
}

# 清理有问题的源
clean_sources() {
    log_step "清理软件源..."
    
    # 删除有问题的PPA源
    sudo rm -f /etc/apt/sources.list.d/jonathonf-ubuntu-ffmpeg-4-jammy.list 2>/dev/null || true
    
    # 清理apt缓存
    sudo apt clean
    sudo apt autoclean
    
    log_info "软件源清理完成 ✓"
}

# 更新系统
update_system() {
    log_step "更新系统包..."
    
    # 更新包列表，忽略错误
    sudo apt update || log_warn "部分软件源更新失败，但不影响安装"
    
    # 升级系统（可选）
    read -p "是否升级系统包？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo apt upgrade -y
    fi
    
    log_info "系统更新完成 ✓"
}

# 安装Qt5和编译工具
install_qt_and_tools() {
    log_step "安装Qt5开发环境和编译工具..."
    
    local packages=(
        # 基础编译工具
        "build-essential"
        "cmake"
        "make"
        "gcc"
        "g++"
        "pkg-config"
        
        # Qt5开发环境
        "qtbase5-dev"
        "qtbase5-dev-tools"
        "qt5-qmake"
        "qtchooser"
        "libqt5serialport5-dev"
        "libqt5network5"
        "libqt5widgets5"
        "libqt5gui5"
        "libqt5core5a"
        
        # Qt5可选组件
        "qttranslations5-l10n"
        "qt5-gtk-platformtheme"
        
        # 系统工具
        "git"
        "wget"
        "curl"
        "vim"
        "nano"
        "tree"
        "netcat-openbsd"
        
        # Python3 (使用系统版本)
        "python3"
        "python3-pip"
        "python3-dev"
    )
    
    log_info "开始安装软件包..."
    for package in "${packages[@]}"; do
        log_info "安装 $package..."
        if sudo apt install -y "$package"; then
            echo "  ✓ $package"
        else
            log_warn "  ⚠ $package 安装失败，跳过"
        fi
    done
    
    log_info "软件包安装完成 ✓"
}

# 验证安装
verify_installation() {
    log_step "验证安装..."
    
    # 检查Qt
    if command -v qmake &> /dev/null; then
        local qt_version=$(qmake --version | head -1)
        log_info "✓ Qt: $qt_version"
    else
        log_error "✗ qmake未找到"
        return 1
    fi
    
    # 检查编译工具
    local tools=("gcc" "g++" "make" "cmake")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_info "✓ $tool"
        else
            log_error "✗ $tool未找到"
            return 1
        fi
    done
    
    # 检查Python
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version)
        log_info "✓ $python_version"
    else
        log_error "✗ Python3未找到"
        return 1
    fi
    
    log_info "安装验证通过 ✅"
}

# 设置项目
setup_project() {
    log_step "设置项目文件..."
    
    local project_dir="$HOME/robot_control_gui"
    local current_dir=$(pwd)
    
    # 备份现有项目
    if [ -d "$project_dir" ]; then
        log_warn "项目目录已存在，创建备份..."
        mv "$project_dir" "${project_dir}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 创建项目目录
    mkdir -p "$project_dir"
    
    # 复制文件
    log_info "复制项目文件..."
    cp *.cpp *.h *.pro *.ui *.py *.sh *.md "$project_dir/" 2>/dev/null || true
    
    # 设置权限
    chmod +x "$project_dir"/*.sh 2>/dev/null || true
    chmod +x "$project_dir"/*.py 2>/dev/null || true
    
    log_info "项目文件设置完成 ✓"
    log_info "项目位置: $project_dir"
}

# 创建编译脚本
create_build_script() {
    log_step "创建编译脚本..."
    
    local project_dir="$HOME/robot_control_gui"
    local build_script="$project_dir/build_project.sh"
    
    # 如果脚本已存在，跳过
    if [ -f "$build_script" ]; then
        log_info "编译脚本已存在，跳过创建"
        return 0
    fi
    
    cat > "$build_script" << 'EOF'
#!/bin/bash

# 项目编译脚本

set -e

echo "🔨 编译机器人控制上位机..."

# 检查环境
if ! command -v qmake &> /dev/null; then
    echo "❌ qmake未找到，请先安装Qt5开发环境"
    exit 1
fi

# 清理旧文件
echo "清理旧的编译文件..."
make clean 2>/dev/null || true
rm -f robot_control_gui *.o moc_*.cpp ui_*.h Makefile

# 生成Makefile
echo "生成Makefile..."
qmake robot_control_gui.pro

# 编译
echo "编译项目..."
make -j$(nproc)

# 检查结果
if [ -f "robot_control_gui" ]; then
    echo "✅ 编译成功！"
    echo "运行: ./robot_control_gui"
else
    echo "❌ 编译失败"
    exit 1
fi
EOF
    
    chmod +x "$build_script"
    log_info "编译脚本创建完成 ✓"
}

# 显示完成信息
show_completion() {
    echo ""
    echo "========================================"
    echo "🎉 简化安装完成！"
    echo "========================================"
    echo ""
    echo "📁 项目位置: $HOME/robot_control_gui"
    echo ""
    echo "🚀 下一步操作:"
    echo "  1. 进入项目目录:"
    echo "     cd ~/robot_control_gui"
    echo ""
    echo "  2. 编译项目:"
    echo "     ./build_project.sh"
    echo ""
    echo "  3. 运行演示:"
    echo "     ./start_demo.sh"
    echo ""
    echo "💡 提示:"
    echo "  - 如果需要conda环境，请手动创建"
    echo "  - Python模拟器使用系统Python3运行"
    echo "  - 如果遇到图形界面问题，使用无头模式"
    echo ""
    echo "========================================"
}

# 主函数
main() {
    read -p "是否继续简化安装？(Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
    
    echo ""
    
    check_system
    clean_sources
    update_system
    install_qt_and_tools
    verify_installation
    setup_project
    create_build_script
    show_completion
}

# 错误处理
trap 'log_error "安装过程中发生错误"; exit 1' ERR

# 运行主函数
main "$@"