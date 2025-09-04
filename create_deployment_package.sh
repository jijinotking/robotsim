#!/bin/bash

# 创建完整的部署包
# 这个脚本将创建一个包含所有必要文件的压缩包，用户可以下载后直接部署

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 创建部署包目录
PACKAGE_DIR="/tmp/robot_control_gui_package"
PACKAGE_NAME="robot_control_gui_v1.0_ubuntu.tar.gz"

log_step "创建部署包..."

# 清理并创建目录
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# 复制所有项目文件
log_info "复制项目文件..."
cp -r /workspace/* "$PACKAGE_DIR/" 2>/dev/null || true

# 创建部署包的README
cat > "$PACKAGE_DIR/DEPLOYMENT_README.md" << 'EOF'
# 机器人运动控制上位机 - 部署包

## 系统要求
- Ubuntu 18.04/20.04/22.04
- 至少2GB可用磁盘空间
- 网络连接（用于下载依赖）

## 快速部署

### 1. 解压部署包
```bash
tar -xzf robot_control_gui_v1.0_ubuntu.tar.gz
cd robot_control_gui_package
```

### 2. 运行环境安装脚本
```bash
chmod +x setup_ubuntu_environment.sh
./setup_ubuntu_environment.sh
```

### 3. 编译和运行
```bash
# 重新加载环境变量
source ~/.bashrc

# 进入项目目录
cd ~/robot_control_gui

# 编译项目
./build_project.sh

# 运行演示
./start_demo.sh
```

## 文件说明

### 核心源代码
- `main.cpp` - 主程序入口
- `mainwindow.h/cpp` - 主窗口实现
- `robotcontroller.h/cpp` - 机器人控制器
- `jointcontrolwidget.h/cpp` - 关节控制组件
- `robot_control_gui.pro` - Qt项目文件
- `mainwindow.ui` - UI界面文件

### Python模拟器
- `robot_simulator.py` - 机器人模拟器
- `run_headless_demo.py` - 无头模式演示

### 部署脚本
- `setup_ubuntu_environment.sh` - 环境安装脚本
- `build_project.sh` - 编译脚本
- `start_demo.sh` - 启动脚本

### 文档
- `README.md` - 项目说明
- `PROJECT_SUMMARY.md` - 项目总结
- `DEPLOYMENT_README.md` - 部署说明（本文件）

## 功能特性

### 机器人配置
- 左臂: 8个关节 (ID: 0-7)
- 右臂: 8个关节 (ID: 8-15)
- 腰部: 2个关节 (ID: 16-17)
- 底盘: 2个电机 (ID: 18-19)
- 升降: 1个电机 (ID: 20)

### 主要功能
- 实时关节角度控制
- 机器人零位设置
- 位置保存/加载
- 紧急停止功能
- 多种通信协议支持
- 图形界面和命令行模式

## 故障排除

### 常见问题

1. **编译失败**
   - 确保Qt5正确安装: `qmake --version`
   - 检查依赖包: `sudo apt install qtbase5-dev`

2. **无法运行图形界面**
   - 检查显示环境: `echo $DISPLAY`
   - 使用无头模式: 选择启动脚本中的选项3

3. **Python环境问题**
   - 激活conda环境: `conda activate robot_control`
   - 检查Python版本: `python --version`

4. **网络连接问题**
   - 检查防火墙设置
   - 确认端口8080未被占用

### 获取帮助
如果遇到问题，请检查：
1. 系统日志: `journalctl -f`
2. 应用日志: 查看终端输出
3. 环境变量: `env | grep -E "(PATH|QT|CONDA)"`

## 版本信息
- 版本: 1.0
- 支持系统: Ubuntu 18.04/20.04/22.04
- Qt版本: 5.15+
- Python版本: 3.9+

## 许可证
MIT License - 详见项目文档
EOF

# 创建安装验证脚本
cat > "$PACKAGE_DIR/verify_installation.sh" << 'EOF'
#!/bin/bash

# 安装验证脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "========================================"
echo "🔍 机器人控制上位机安装验证"
echo "========================================"
echo ""

# 检查系统信息
log_info "系统信息:"
echo "  操作系统: $(lsb_release -d | cut -f2)"
echo "  内核版本: $(uname -r)"
echo "  架构: $(uname -m)"
echo ""

# 检查基础工具
log_info "检查基础工具..."
tools=("gcc" "g++" "make" "git" "wget" "curl")
for tool in "${tools[@]}"; do
    if command -v "$tool" &> /dev/null; then
        echo "  ✓ $tool"
    else
        echo "  ✗ $tool (未安装)"
    fi
done
echo ""

# 检查Qt环境
log_info "检查Qt环境..."
if command -v qmake &> /dev/null; then
    echo "  ✓ qmake: $(qmake --version | head -1)"
    
    # 检查Qt模块
    qt_modules=("QtCore" "QtWidgets" "QtNetwork" "QtSerialPort")
    for module in "${qt_modules[@]}"; do
        if pkg-config --exists Qt5${module#Qt} 2>/dev/null; then
            echo "  ✓ $module"
        else
            echo "  ✗ $module (未安装)"
        fi
    done
else
    log_error "  ✗ qmake未找到"
fi
echo ""

# 检查Python环境
log_info "检查Python环境..."
if command -v python3 &> /dev/null; then
    echo "  ✓ Python: $(python3 --version)"
else
    log_error "  ✗ Python3未找到"
fi

if command -v conda &> /dev/null; then
    echo "  ✓ Conda: $(conda --version)"
    
    # 检查robot_control环境
    if conda env list | grep -q robot_control; then
        echo "  ✓ robot_control环境已创建"
    else
        log_warn "  ⚠ robot_control环境未创建"
    fi
else
    log_warn "  ⚠ Conda未找到"
fi
echo ""

# 检查项目文件
log_info "检查项目文件..."
project_dir="$HOME/robot_control_gui"
if [ -d "$project_dir" ]; then
    echo "  ✓ 项目目录: $project_dir"
    
    cd "$project_dir"
    
    # 检查源代码文件
    source_files=("main.cpp" "mainwindow.cpp" "robotcontroller.cpp" "jointcontrolwidget.cpp" "robot_control_gui.pro")
    for file in "${source_files[@]}"; do
        if [ -f "$file" ]; then
            echo "  ✓ $file"
        else
            log_warn "  ⚠ $file (缺失)"
        fi
    done
    
    # 检查Python文件
    python_files=("robot_simulator.py" "run_headless_demo.py")
    for file in "${python_files[@]}"; do
        if [ -f "$file" ]; then
            echo "  ✓ $file"
        else
            log_warn "  ⚠ $file (缺失)"
        fi
    done
    
    # 检查脚本文件
    script_files=("build_project.sh" "start_demo.sh")
    for file in "${script_files[@]}"; do
        if [ -f "$file" ] && [ -x "$file" ]; then
            echo "  ✓ $file (可执行)"
        else
            log_warn "  ⚠ $file (缺失或不可执行)"
        fi
    done
    
    # 检查编译状态
    if [ -f "robot_control_gui" ]; then
        echo "  ✓ robot_control_gui (已编译)"
    else
        log_warn "  ⚠ robot_control_gui (未编译)"
    fi
    
else
    log_error "  ✗ 项目目录不存在: $project_dir"
fi
echo ""

# 检查网络连接
log_info "检查网络连接..."
if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "  ✓ 网络连接正常"
else
    log_warn "  ⚠ 网络连接异常"
fi
echo ""

# 检查端口占用
log_info "检查端口占用..."
if netstat -tuln 2>/dev/null | grep -q ":8080 "; then
    log_warn "  ⚠ 端口8080已被占用"
else
    echo "  ✓ 端口8080可用"
fi
echo ""

# 总结
echo "========================================"
echo "📋 验证总结"
echo "========================================"
echo ""

# 给出建议
if command -v qmake &> /dev/null && command -v python3 &> /dev/null; then
    log_info "✅ 基础环境检查通过"
    echo ""
    echo "🚀 建议的下一步操作:"
    echo "  1. cd $project_dir"
    echo "  2. ./build_project.sh"
    echo "  3. ./start_demo.sh"
else
    log_error "❌ 环境检查未通过"
    echo ""
    echo "🔧 建议的修复操作:"
    echo "  1. 重新运行环境安装脚本"
    echo "  2. 检查错误日志"
    echo "  3. 手动安装缺失的组件"
fi

echo ""
echo "========================================"
EOF

chmod +x "$PACKAGE_DIR/verify_installation.sh"

# 创建卸载脚本
cat > "$PACKAGE_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

# 卸载脚本

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "========================================"
echo "🗑️  机器人控制上位机卸载程序"
echo "========================================"
echo ""

log_warn "这将删除以下内容:"
echo "  - 项目目录: $HOME/robot_control_gui"
echo "  - Conda环境: robot_control"
echo "  - 相关环境变量"
echo ""
echo "注意: 不会卸载系统级别的包 (Qt5, Miniconda等)"
echo ""

read -p "确定要继续卸载吗？(y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "卸载已取消"
    exit 0
fi

# 删除项目目录
if [ -d "$HOME/robot_control_gui" ]; then
    log_info "删除项目目录..."
    rm -rf "$HOME/robot_control_gui"
    echo "  ✓ 项目目录已删除"
fi

# 删除conda环境
if command -v conda &> /dev/null; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh" 2>/dev/null || true
    if conda env list | grep -q robot_control; then
        log_info "删除conda环境..."
        conda env remove -n robot_control -y
        echo "  ✓ robot_control环境已删除"
    fi
fi

# 清理环境变量 (可选)
read -p "是否清理bashrc中的相关环境变量？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "清理环境变量..."
    
    # 备份bashrc
    cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 删除conda相关行
    sed -i '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$HOME/.bashrc"
    
    # 删除Qt相关行
    sed -i '/# Qt环境变量/d' "$HOME/.bashrc"
    sed -i '/export QT_QPA_PLATFORM/d' "$HOME/.bashrc"
    
    echo "  ✓ 环境变量已清理"
    echo "  ✓ bashrc备份已保存"
fi

echo ""
echo "========================================"
echo "✅ 卸载完成"
echo "========================================"
echo ""
echo "如果需要完全清理系统，还可以手动执行:"
echo "  sudo apt remove qtbase5-dev qtcreator"
echo "  rm -rf ~/miniconda3"
echo ""
echo "感谢使用机器人控制上位机！"
echo "========================================"
EOF

chmod +x "$PACKAGE_DIR/uninstall.sh"

# 创建压缩包
log_info "创建压缩包..."
cd /tmp
tar -czf "$PACKAGE_NAME" robot_control_gui_package/

# 移动到workspace
mv "$PACKAGE_NAME" /workspace/

# 清理临时目录
rm -rf "$PACKAGE_DIR"

log_info "部署包创建完成: /workspace/$PACKAGE_NAME"

# 显示包信息
echo ""
echo "========================================"
echo "📦 部署包信息"
echo "========================================"
echo "文件名: $PACKAGE_NAME"
echo "大小: $(du -h /workspace/$PACKAGE_NAME | cut -f1)"
echo "位置: /workspace/$PACKAGE_NAME"
echo ""
echo "包含内容:"
echo "  ✓ 完整的Qt5源代码"
echo "  ✓ Python模拟器和演示程序"
echo "  ✓ 自动化部署脚本"
echo "  ✓ 编译和启动脚本"
echo "  ✓ 详细的文档和说明"
echo "  ✓ 安装验证和卸载脚本"
echo ""
echo "用户使用方法:"
echo "  1. 下载: $PACKAGE_NAME"
echo "  2. 解压: tar -xzf $PACKAGE_NAME"
echo "  3. 安装: cd robot_control_gui_package && ./setup_ubuntu_environment.sh"
echo "  4. 使用: cd ~/robot_control_gui && ./start_demo.sh"
echo "========================================"