#!/bin/bash

# 一键下载和安装脚本
# 用户可以直接运行这个脚本来下载和安装整个项目

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

# 项目信息
PROJECT_NAME="机器人运动控制上位机"
VERSION="1.0"
PACKAGE_NAME="robot_control_gui_v1.0_ubuntu.tar.gz"

# 这里应该是实际的下载链接，用户需要替换
DOWNLOAD_URL="https://github.com/your-username/robot-control-gui/releases/download/v1.0/${PACKAGE_NAME}"

# 如果没有提供下载链接，使用本地文件（用于演示）
LOCAL_PACKAGE="/workspace/${PACKAGE_NAME}"

echo "========================================"
echo "🤖 ${PROJECT_NAME} v${VERSION}"
echo "========================================"
echo ""
echo "这个脚本将自动下载和安装机器人控制上位机"
echo ""
echo "系统要求:"
echo "  • Ubuntu 18.04/20.04/22.04"
echo "  • 至少2GB可用磁盘空间"
echo "  • 网络连接"
echo "  • sudo权限"
echo ""

# 检查系统
check_system() {
    log_step "检查系统环境..."
    
    # 检查Ubuntu版本
    if ! command -v lsb_release &> /dev/null; then
        log_error "无法检测系统版本，请确保运行在Ubuntu系统上"
        exit 1
    fi
    
    local version=$(lsb_release -rs)
    local major_version=$(echo $version | cut -d. -f1)
    
    if [[ $major_version -lt 18 ]]; then
        log_error "不支持的Ubuntu版本: $version"
        log_info "支持的版本: Ubuntu 18.04, 20.04, 22.04"
        exit 1
    fi
    
    log_info "系统版本: Ubuntu $version ✓"
    
    # 检查磁盘空间
    local available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=2097152  # 2GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        log_warn "可用磁盘空间不足2GB，可能影响安装"
    else
        log_info "磁盘空间充足 ✓"
    fi
    
    # 检查网络连接
    if ping -c 1 8.8.8.8 &> /dev/null; then
        log_info "网络连接正常 ✓"
    else
        log_warn "网络连接异常，可能影响下载"
    fi
}

# 下载部署包
download_package() {
    log_step "下载部署包..."
    
    local temp_dir="/tmp/robot_control_gui_install"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # 如果本地文件存在，直接复制（用于演示）
    if [ -f "$LOCAL_PACKAGE" ]; then
        log_info "使用本地部署包: $LOCAL_PACKAGE"
        cp "$LOCAL_PACKAGE" .
    else
        # 实际部署时应该从网络下载
        log_info "从网络下载: $DOWNLOAD_URL"
        
        if command -v wget &> /dev/null; then
            wget "$DOWNLOAD_URL" -O "$PACKAGE_NAME"
        elif command -v curl &> /dev/null; then
            curl -L "$DOWNLOAD_URL" -o "$PACKAGE_NAME"
        else
            log_error "未找到wget或curl，无法下载文件"
            log_info "请手动下载 $PACKAGE_NAME 并放在当前目录"
            exit 1
        fi
    fi
    
    # 验证下载
    if [ ! -f "$PACKAGE_NAME" ]; then
        log_error "下载失败，未找到 $PACKAGE_NAME"
        exit 1
    fi
    
    local file_size=$(du -h "$PACKAGE_NAME" | cut -f1)
    log_info "下载完成: $PACKAGE_NAME ($file_size)"
}

# 解压和安装
extract_and_install() {
    log_step "解压部署包..."
    
    # 解压
    tar -xzf "$PACKAGE_NAME"
    
    if [ ! -d "robot_control_gui_package" ]; then
        log_error "解压失败，未找到项目目录"
        exit 1
    fi
    
    cd robot_control_gui_package
    log_info "解压完成 ✓"
    
    # 运行安装脚本
    log_step "运行环境安装脚本..."
    
    if [ ! -f "setup_ubuntu_environment.sh" ]; then
        log_error "未找到安装脚本"
        exit 1
    fi
    
    chmod +x setup_ubuntu_environment.sh
    
    # 运行安装脚本
    if ./setup_ubuntu_environment.sh; then
        log_info "环境安装完成 ✓"
    else
        log_error "环境安装失败"
        exit 1
    fi
}

# 编译项目
build_project() {
    log_step "编译项目..."
    
    # 重新加载环境
    source ~/.bashrc 2>/dev/null || true
    
    # 进入项目目录
    local project_dir="$HOME/robot_control_gui"
    
    if [ ! -d "$project_dir" ]; then
        log_error "项目目录不存在: $project_dir"
        exit 1
    fi
    
    cd "$project_dir"
    
    # 运行编译脚本
    if [ -f "build_project.sh" ]; then
        chmod +x build_project.sh
        if ./build_project.sh; then
            log_info "项目编译完成 ✓"
        else
            log_error "项目编译失败"
            exit 1
        fi
    else
        log_error "未找到编译脚本"
        exit 1
    fi
}

# 运行验证
run_verification() {
    log_step "验证安装..."
    
    local project_dir="$HOME/robot_control_gui"
    cd "$project_dir"
    
    if [ -f "verify_installation.sh" ]; then
        chmod +x verify_installation.sh
        ./verify_installation.sh
    else
        log_warn "未找到验证脚本，跳过验证"
    fi
}

# 显示完成信息
show_completion() {
    echo ""
    echo "========================================"
    echo "🎉 安装完成！"
    echo "========================================"
    echo ""
    echo "📁 项目位置: $HOME/robot_control_gui"
    echo ""
    echo "🚀 快速开始:"
    echo "  cd ~/robot_control_gui"
    echo "  ./start_demo.sh"
    echo ""
    echo "📖 查看文档:"
    echo "  cat ~/robot_control_gui/README.md"
    echo ""
    echo "🔧 如果遇到问题:"
    echo "  ./verify_installation.sh  # 验证安装"
    echo "  ./uninstall.sh           # 卸载程序"
    echo ""
    echo "========================================"
    echo "感谢使用${PROJECT_NAME}！"
    echo "========================================"
}

# 清理临时文件
cleanup() {
    log_step "清理临时文件..."
    
    local temp_dir="/tmp/robot_control_gui_install"
    if [ -d "$temp_dir" ]; then
        rm -rf "$temp_dir"
        log_info "临时文件清理完成"
    fi
}

# 错误处理
handle_error() {
    log_error "安装过程中发生错误"
    log_info "请检查上面的错误信息并重试"
    
    echo ""
    echo "常见问题解决:"
    echo "  1. 确保有sudo权限"
    echo "  2. 检查网络连接"
    echo "  3. 确保磁盘空间充足"
    echo "  4. 重新运行此脚本"
    
    cleanup
    exit 1
}

# 主函数
main() {
    # 设置错误处理
    trap handle_error ERR
    
    # 确认安装
    read -p "是否继续安装？(Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "安装已取消"
        exit 0
    fi
    
    echo ""
    
    # 执行安装步骤
    check_system
    download_package
    extract_and_install
    build_project
    run_verification
    cleanup
    show_completion
}

# 运行主函数
main "$@"