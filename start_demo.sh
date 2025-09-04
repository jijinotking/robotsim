#!/bin/bash

echo "机器人运动控制上位机演示"
echo "=========================="
echo ""
echo "这个演示包含："
echo "1. QT上位机程序 (robot_control_gui)"
echo "2. 机器人模拟器 (robot_simulator.py)"
echo ""
echo "使用说明："
echo "1. 首先启动机器人模拟器"
echo "2. 然后启动QT上位机"
echo "3. 在上位机中点击'连接机器人'按钮"
echo "4. 开始控制机器人关节"
echo ""

# 检查是否有显示环境
if [ -z "$DISPLAY" ]; then
    echo "警告: 没有检测到图形显示环境"
    echo "如果要运行QT程序，请确保："
    echo "1. 在有图形界面的环境中运行"
    echo "2. 或者设置X11转发"
    echo ""
fi

echo "选择要启动的程序："
echo "1) 启动机器人模拟器"
echo "2) 启动QT上位机 (需要图形界面)"
echo "3) 启动无头模式演示 (命令行版本)"
echo "4) 同时启动模拟器和QT上位机"
echo "5) 同时启动模拟器和无头模式演示"
echo "6) 查看项目文件"
echo "7) 退出"
echo ""

read -p "请选择 (1-7): " choice

case $choice in
    1)
        echo "启动机器人模拟器..."
        python3 robot_simulator.py
        ;;
    2)
        echo "启动QT上位机..."
        if [ -z "$DISPLAY" ]; then
            echo "错误: 需要图形显示环境才能运行QT程序"
            echo "建议使用选项3（无头模式演示）"
            exit 1
        fi
        ./robot_control_gui
        ;;
    3)
        echo "启动无头模式演示（命令行版本）..."
        echo "这个版本不需要图形界面，适合在服务器环境中使用"
        echo "请先在另一个终端启动机器人模拟器: python3 robot_simulator.py"
        echo "然后在演示程序中输入 'connect' 连接到模拟器"
        echo ""
        python3 run_headless_demo.py
        ;;
    4)
        echo "同时启动模拟器和QT上位机..."
        if [ -z "$DISPLAY" ]; then
            echo "错误: 需要图形显示环境才能运行QT程序"
            echo "建议使用选项5（模拟器+无头模式演示）"
            exit 1
        fi
        echo "启动机器人模拟器（后台运行）..."
        python3 robot_simulator.py &
        SIMULATOR_PID=$!
        sleep 2
        echo "启动QT上位机..."
        ./robot_control_gui
        echo "关闭机器人模拟器..."
        kill $SIMULATOR_PID 2>/dev/null
        ;;
    5)
        echo "同时启动模拟器和无头模式演示..."
        echo "启动机器人模拟器（后台运行）..."
        python3 robot_simulator.py &
        SIMULATOR_PID=$!
        sleep 2
        echo "启动无头模式演示..."
        echo "在演示程序中输入 'connect' 连接到模拟器"
        echo ""
        python3 run_headless_demo.py
        echo "关闭机器人模拟器..."
        kill $SIMULATOR_PID 2>/dev/null
        ;;
    6)
        echo "项目文件列表："
        echo "==============="
        ls -la *.cpp *.h *.pro *.py *.md *.sh 2>/dev/null
        echo ""
        echo "主要文件说明："
        echo "- robot_control_gui: QT上位机可执行文件"
        echo "- robot_simulator.py: 机器人模拟器"
        echo "- run_headless_demo.py: 无头模式演示程序"
        echo "- main.cpp: 主程序入口"
        echo "- mainwindow.cpp/h: 主窗口实现"
        echo "- robotcontroller.cpp/h: 机器人控制器"
        echo "- jointcontrolwidget.cpp/h: 关节控制组件"
        echo "- README.md: 详细使用说明"
        ;;
    7)
        echo "退出"
        exit 0
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac