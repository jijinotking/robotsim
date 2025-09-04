#!/bin/bash

# 项目编译脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
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

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "========================================"
echo "🔨 编译机器人控制上位机"
echo "========================================"
echo ""

# 检查当前目录
if [ ! -f "robot_control_gui.pro" ]; then
    log_error "未找到项目文件 robot_control_gui.pro"
    log_info "请确保在项目根目录运行此脚本"
    exit 1
fi

# 检查Qt环境
log_step "检查编译环境..."
if ! command -v qmake &> /dev/null; then
    log_error "qmake未找到，请确保Qt5已正确安装"
    log_info "安装命令: sudo apt install qtbase5-dev qt5-qmake"
    exit 1
fi

if ! command -v make &> /dev/null; then
    log_error "make未找到，请安装build-essential"
    log_info "安装命令: sudo apt install build-essential"
    exit 1
fi

# 显示环境信息
log_info "Qt版本: $(qmake --version | head -1)"
log_info "编译器: $(gcc --version | head -1)"
log_info "CPU核心数: $(nproc)"

# 清理旧的编译文件
log_step "清理旧的编译文件..."
make clean 2>/dev/null || true
rm -f robot_control_gui
rm -f *.o
rm -f moc_*.cpp
rm -f ui_*.h
rm -f Makefile
log_info "清理完成"

# 生成Makefile
log_step "生成Makefile..."
if ! qmake robot_control_gui.pro; then
    log_error "qmake执行失败"
    exit 1
fi
log_info "Makefile生成成功"

# 编译项目
log_step "编译项目..."
echo "使用 $(nproc) 个并行任务进行编译..."

if ! make -j$(nproc); then
    log_error "编译失败"
    echo ""
    log_info "常见解决方案:"
    echo "  1. 检查Qt5开发包是否完整安装"
    echo "  2. 检查是否缺少依赖库"
    echo "  3. 尝试单线程编译: make"
    echo "  4. 查看详细错误信息"
    exit 1
fi

# 检查编译结果
log_step "检查编译结果..."
if [ -f "robot_control_gui" ]; then
    log_info "✅ 编译成功！"
    
    # 显示文件信息
    local file_size=$(du -h robot_control_gui | cut -f1)
    local file_perms=$(ls -l robot_control_gui | cut -d' ' -f1)
    
    echo ""
    echo "📁 编译输出:"
    echo "  文件名: robot_control_gui"
    echo "  大小: $file_size"
    echo "  权限: $file_perms"
    echo "  位置: $(pwd)/robot_control_gui"
    
    # 检查依赖库
    log_step "检查依赖库..."
    if command -v ldd &> /dev/null; then
        echo ""
        echo "🔗 依赖库检查:"
        if ldd robot_control_gui | grep -q "not found"; then
            log_warn "发现缺失的依赖库:"
            ldd robot_control_gui | grep "not found"
            echo ""
            log_info "可能需要安装额外的Qt5运行时库"
        else
            log_info "所有依赖库都已找到 ✓"
        fi
    fi
    
    echo ""
    echo "🚀 运行方法:"
    echo "  直接运行: ./robot_control_gui"
    echo "  启动演示: ./start_demo.sh"
    echo "  无头模式: python3 run_headless_demo.py"
    
else
    log_error "❌ 编译失败 - 未生成可执行文件"
    
    echo ""
    log_info "故障排除建议:"
    echo "  1. 检查编译错误信息"
    echo "  2. 确认Qt5开发包完整安装:"
    echo "     sudo apt install qtbase5-dev libqt5serialport5-dev"
    echo "  3. 检查系统架构兼容性"
    echo "  4. 尝试重新运行: ./build_project.sh"
    
    exit 1
fi

echo ""
echo "========================================"
echo "🎉 编译完成！"
echo "========================================"