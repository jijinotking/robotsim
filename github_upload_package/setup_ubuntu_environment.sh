#!/bin/bash

# Ubuntu环境自动安装脚本
# 支持Ubuntu 18.04/20.04/22.04
# 从零开始安装所有依赖，包括Miniconda、Qt5等

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

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要使用root用户运行此脚本"
        log_info "正确的使用方法: ./setup_ubuntu_environment.sh"
        exit 1
    fi
}

# 检查Ubuntu版本
check_ubuntu_version() {
    if ! command -v lsb_release &> /dev/null; then
        log_error "无法检测Ubuntu版本，请确保运行在Ubuntu系统上"
        exit 1
    fi
    
    local version=$(lsb_release -rs)
    local major_version=$(echo $version | cut -d. -f1)
    
    if [[ $major_version -lt 18 ]]; then
        log_error "不支持的Ubuntu版本: $version"
        log_info "支持的版本: Ubuntu 18.04, 20.04, 22.04"
        exit 1
    fi
    
    log_info "检测到Ubuntu版本: $version ✓"
}

# 更新系统包
update_system() {
    log_step "更新系统包..."
    
    sudo apt update
    sudo apt upgrade -y
    
    log_info "系统包更新完成 ✓"
}

# 安装基础开发工具
install_basic_tools() {
    log_step "安装基础开发工具..."
    
    local packages=(
        "build-essential"
        "cmake"
        "git"
        "wget"
        "curl"
        "vim"
        "nano"
        "htop"
        "tree"
        "unzip"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "pkg-config"
        "netcat-openbsd"
    )
    
    for package in "${packages[@]}"; do
        log_info "安装 $package..."
        sudo apt install -y "$package"
    done
    
    log_info "基础开发工具安装完成 ✓"
}

# 安装Qt5开发环境
install_qt5() {
    log_step "安装Qt5开发环境..."
    
    local qt_packages=(
        "qtbase5-dev"
        "qtbase5-dev-tools"
        "qtcreator"
        "qt5-qmake"
        "qtchooser"
        "libqt5serialport5-dev"
        "libqt5network5"
        "libqt5widgets5"
        "libqt5gui5"
        "libqt5core5a"
        "qttranslations5-l10n"
        "qt5-gtk-platformtheme"
        "qt5-image-formats-plugins"
    )
    
    for package in "${qt_packages[@]}"; do
        log_info "安装 $package..."
        sudo apt install -y "$package"
    done
    
    # 验证Qt安装
    if command -v qmake &> /dev/null; then
        local qt_version=$(qmake --version | head -1)
        log_info "Qt5安装完成: $qt_version ✓"
    else
        log_error "Qt5安装失败"
        exit 1
    fi
}

# 安装Python3和相关工具
install_python() {
    log_step "安装Python3环境..."
    
    local python_packages=(
        "python3"
        "python3-pip"
        "python3-dev"
        "python3-venv"
        "python3-setuptools"
        "python3-wheel"
    )
    
    for package in "${python_packages[@]}"; do
        log_info "安装 $package..."
        sudo apt install -y "$package"
    done
    
    # 验证Python安装
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version)
        log_info "Python3安装完成: $python_version ✓"
    else
        log_error "Python3安装失败"
        exit 1
    fi
}

# 安装Miniconda
install_miniconda() {
    log_step "安装Miniconda..."
    
    local miniconda_dir="$HOME/miniconda3"
    
    # 检查是否已安装
    if [ -d "$miniconda_dir" ] && command -v conda &> /dev/null; then
        log_info "Miniconda已安装，跳过安装步骤"
        return 0
    fi
    
    # 下载Miniconda
    local miniconda_url="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    local miniconda_installer="/tmp/miniconda.sh"
    
    log_info "下载Miniconda安装包..."
    wget -q "$miniconda_url" -O "$miniconda_installer"
    
    # 安装Miniconda
    log_info "安装Miniconda到 $miniconda_dir..."
    bash "$miniconda_installer" -b -p "$miniconda_dir"
    
    # 初始化conda
    log_info "初始化conda环境..."
    "$miniconda_dir/bin/conda" init bash
    
    # 清理安装包
    rm -f "$miniconda_installer"
    
    log_info "Miniconda安装完成 ✓"
    log_warn "请重新启动终端或运行 'source ~/.bashrc' 来激活conda"
}

# 创建conda环境
create_conda_env() {
    log_step "创建conda环境..."
    
    # 确保conda可用
    if ! command -v conda &> /dev/null; then
        # 尝试加载conda
        if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
        else
            log_error "无法找到conda，请重新启动终端后再运行此脚本"
            exit 1
        fi
    fi
    
    local env_name="robot_control"
    
    # 检查环境是否已存在
    if conda env list | grep -q "$env_name"; then
        log_info "conda环境 '$env_name' 已存在，跳过创建"
        return 0
    fi
    
    # 创建环境
    log_info "创建conda环境: $env_name"
    conda create -n "$env_name" python=3.9 -y
    
    # 激活环境并安装包
    log_info "激活环境并安装Python包..."
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
    conda activate "$env_name"
    
    # 安装常用Python包
    local python_packages=(
        "numpy"
        "matplotlib"
        "scipy"
        "pandas"
        "jupyter"
        "ipython"
    )
    
    for package in "${python_packages[@]}"; do
        log_info "安装Python包: $package"
        conda install -n "$env_name" "$package" -y
    done
    
    log_info "conda环境创建完成 ✓"
}

# 复制项目文件
setup_project() {
    log_step "设置项目文件..."
    
    local project_dir="$HOME/robot_control_gui"
    local current_dir=$(pwd)
    
    # 创建项目目录
    if [ -d "$project_dir" ]; then
        log_warn "项目目录已存在，备份旧版本..."
        mv "$project_dir" "${project_dir}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    mkdir -p "$project_dir"
    
    # 复制文件
    log_info "复制项目文件到 $project_dir..."
    
    # 复制源代码文件
    local source_files=(
        "*.cpp"
        "*.h"
        "*.pro"
        "*.ui"
        "*.py"
        "*.sh"
        "*.md"
        "Makefile"
    )
    
    for pattern in "${source_files[@]}"; do
        if ls $pattern 1> /dev/null 2>&1; then
            cp $pattern "$project_dir/" 2>/dev/null || true
        fi
    done
    
    # 设置脚本权限
    chmod +x "$project_dir"/*.sh 2>/dev/null || true
    chmod +x "$project_dir"/*.py 2>/dev/null || true
    
    log_info "项目文件设置完成 ✓"
}

# 创建编译脚本
create_build_script() {
    log_step "创建编译脚本..."
    
    local project_dir="$HOME/robot_control_gui"
    local build_script="$project_dir/build_project.sh"
    
    cat > "$build_script" << 'EOF'
#!/bin/bash

# 项目编译脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================"
echo "🔨 编译机器人控制上位机"
echo "========================================"
echo ""

# 检查Qt环境
if ! command -v qmake &> /dev/null; then
    log_error "qmake未找到，请确保Qt5已正确安装"
    exit 1
fi

# 清理旧的编译文件
log_step "清理旧的编译文件..."
make clean 2>/dev/null || true
rm -f robot_control_gui
rm -f *.o
rm -f moc_*.cpp
rm -f ui_*.h
rm -f Makefile

# 生成Makefile
log_step "生成Makefile..."
qmake robot_control_gui.pro

# 编译项目
log_step "编译项目..."
make -j$(nproc)

# 检查编译结果
if [ -f "robot_control_gui" ]; then
    log_info "✅ 编译成功！"
    echo ""
    echo "可执行文件: ./robot_control_gui"
    echo "启动演示: ./start_demo.sh"
    echo ""
else
    log_error "❌ 编译失败"
    exit 1
fi

echo "========================================"
EOF

    chmod +x "$build_script"
    log_info "编译脚本创建完成 ✓"
}

# 设置环境变量
setup_environment() {
    log_step "设置环境变量..."
    
    local bashrc="$HOME/.bashrc"
    
    # 备份bashrc
    cp "$bashrc" "${bashrc}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 添加Qt环境变量
    if ! grep -q "# Qt环境变量" "$bashrc"; then
        cat >> "$bashrc" << 'EOF'

# Qt环境变量
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib/x86_64-linux-gnu/qt5/plugins
export QT_PLUGIN_PATH=/usr/lib/x86_64-linux-gnu/qt5/plugins
EOF
        log_info "Qt环境变量已添加到 ~/.bashrc"
    fi
    
    log_info "环境变量设置完成 ✓"
}

# 验证安装
verify_installation() {
    log_step "验证安装..."
    
    local project_dir="$HOME/robot_control_gui"
    
    # 检查基本命令
    local commands=("gcc" "g++" "make" "qmake" "python3")
    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            log_info "✓ $cmd"
        else
            log_error "✗ $cmd 未找到"
            return 1
        fi
    done
    
    # 检查项目文件
    cd "$project_dir"
    local required_files=("main.cpp" "robot_control_gui.pro" "robot_simulator.py")
    for file in "${required_files[@]}"; do
        if [ -f "$file" ]; then
            log_info "✓ $file"
        else
            log_error "✗ $file 未找到"
            return 1
        fi
    done
    
    log_info "安装验证通过 ✅"
}

# 显示完成信息
show_completion_info() {
    echo ""
    echo "========================================"
    echo "🎉 安装完成！"
    echo "========================================"
    echo ""
    echo "📁 项目位置: $HOME/robot_control_gui"
    echo ""
    echo "🚀 快速开始:"
    echo "  1. 重新加载环境变量:"
    echo "     source ~/.bashrc"
    echo ""
    echo "  2. 进入项目目录:"
    echo "     cd ~/robot_control_gui"
    echo ""
    echo "  3. 编译项目:"
    echo "     ./build_project.sh"
    echo ""
    echo "  4. 运行演示:"
    echo "     ./start_demo.sh"
    echo ""
    echo "📚 其他有用的命令:"
    echo "  - 验证安装: ./verify_installation.sh"
    echo "  - 查看文档: cat README.md"
    echo "  - 卸载程序: ./uninstall.sh"
    echo ""
    echo "🔧 如果遇到问题:"
    echo "  1. 检查系统日志"
    echo "  2. 运行验证脚本"
    echo "  3. 查看项目文档"
    echo ""
    echo "========================================"
    echo "感谢使用机器人控制上位机！"
    echo "========================================"
}

# 主函数
main() {
    echo "========================================"
    echo "🤖 机器人控制上位机环境安装"
    echo "========================================"
    echo ""
    echo "这个脚本将安装以下组件:"
    echo "  • 基础开发工具 (gcc, make, cmake等)"
    echo "  • Qt5开发环境"
    echo "  • Python3和相关工具"
    echo "  • Miniconda"
    echo "  • 项目源代码和脚本"
    echo ""
    echo "预计安装时间: 10-20分钟"
    echo "需要网络连接下载软件包"
    echo ""
    
    read -p "是否继续安装？(Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
    
    echo ""
    echo "开始安装..."
    echo ""
    
    # 执行安装步骤
    check_root
    check_ubuntu_version
    update_system
    install_basic_tools
    install_qt5
    install_python
    install_miniconda
    create_conda_env
    setup_project
    create_build_script
    setup_environment
    verify_installation
    show_completion_info
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查上面的错误信息"; exit 1' ERR

# 运行主函数
main "$@"