#!/bin/bash

echo "🔧 修复Qt显示问题"
echo "=================="

# 检查当前环境
echo "当前环境信息："
echo "DISPLAY: $DISPLAY"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo "WAYLAND_DISPLAY: $WAYLAND_DISPLAY"

# 方案1: 尝试使用虚拟显示
echo ""
echo "方案1: 安装虚拟显示支持..."
sudo apt update
sudo apt install -y xvfb x11-utils

# 方案2: 设置QT使用offscreen平台
echo ""
echo "方案2: 创建offscreen版本的启动脚本..."
cat > start_gui_offscreen.sh << 'EOF'
#!/bin/bash
echo "启动Qt应用（offscreen模式）..."
export QT_QPA_PLATFORM=offscreen
./robot_control_gui
EOF
chmod +x start_gui_offscreen.sh

# 方案3: 创建使用Xvfb的启动脚本
cat > start_gui_xvfb.sh << 'EOF'
#!/bin/bash
echo "启动Qt应用（Xvfb虚拟显示）..."

# 启动虚拟显示服务器
Xvfb :99 -screen 0 1024x768x24 &
XVFB_PID=$!

# 设置显示环境变量
export DISPLAY=:99

# 等待Xvfb启动
sleep 2

# 启动Qt应用
./robot_control_gui

# 清理
kill $XVFB_PID 2>/dev/null
EOF
chmod +x start_gui_xvfb.sh

# 方案4: 创建VNC版本
echo ""
echo "方案3: 安装VNC支持..."
sudo apt install -y tightvncserver

cat > start_gui_vnc.sh << 'EOF'
#!/bin/bash
echo "启动Qt应用（VNC模式）..."

# 设置VNC密码（如果没有设置过）
if [ ! -f ~/.vnc/passwd ]; then
    mkdir -p ~/.vnc
    echo "设置VNC密码..."
    echo "请输入VNC密码（6-8位）："
    vncpasswd
fi

# 启动VNC服务器
vncserver :1 -geometry 1024x768 -depth 24

echo "VNC服务器已启动在 :1"
echo "您可以使用VNC客户端连接到 localhost:5901"
echo "然后在VNC会话中运行: ./robot_control_gui"
echo ""
echo "要停止VNC服务器，请运行: vncserver -kill :1"
EOF
chmod +x start_gui_vnc.sh

# 测试哪种方案可用
echo ""
echo "🧪 测试可用的解决方案..."

echo "测试1: offscreen模式"
timeout 5s bash -c 'export QT_QPA_PLATFORM=offscreen; ./robot_control_gui --help' 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ offscreen模式可用"
    OFFSCREEN_OK=1
else
    echo "❌ offscreen模式不可用"
    OFFSCREEN_OK=0
fi

echo "测试2: Xvfb虚拟显示"
if command -v Xvfb >/dev/null 2>&1; then
    echo "✅ Xvfb已安装"
    XVFB_OK=1
else
    echo "❌ Xvfb未安装"
    XVFB_OK=0
fi

echo ""
echo "📋 解决方案总结："
echo "=================="

if [ $OFFSCREEN_OK -eq 1 ]; then
    echo "✅ 推荐方案1: 使用offscreen模式"
    echo "   运行命令: ./start_gui_offscreen.sh"
    echo "   注意: 这种模式下看不到界面，但程序可以运行"
fi

if [ $XVFB_OK -eq 1 ]; then
    echo "✅ 推荐方案2: 使用Xvfb虚拟显示"
    echo "   运行命令: ./start_gui_xvfb.sh"
    echo "   注意: 这种模式下程序在虚拟显示中运行"
fi

echo "✅ 方案3: 使用VNC远程桌面"
echo "   运行命令: ./start_gui_vnc.sh"
echo "   然后使用VNC客户端连接查看界面"

echo ""
echo "🎯 最佳实践建议："
echo "=================="
echo "1. 如果只需要测试功能，使用命令行模式："
echo "   python3 run_headless_demo.py"
echo ""
echo "2. 如果需要看到图形界面，在本地机器上运行："
echo "   - 将项目复制到有图形界面的Ubuntu机器"
echo "   - 或使用VNC/远程桌面连接"
echo ""
echo "3. 如果在服务器环境，推荐使用Web界面版本"
echo "   （需要额外开发Web前端）"

echo ""
echo "🔧 修复完成！请选择合适的启动方式。"