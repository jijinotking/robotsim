#!/usr/bin/env python3
"""
创建UI截图的Python脚本
用于生成界面预览图
"""

import subprocess
import sys
import time
import os
from pathlib import Path

def create_screenshot():
    """创建UI截图"""
    print("📸 创建UI截图...")
    
    # 检查是否有xvfb-run（虚拟显示）
    try:
        subprocess.run(['which', 'xvfb-run'], check=True, capture_output=True)
        has_xvfb = True
    except subprocess.CalledProcessError:
        has_xvfb = False
        print("⚠️  未找到xvfb-run，将尝试其他方法")
    
    # 设置环境变量
    env = os.environ.copy()
    
    if has_xvfb:
        # 使用虚拟显示
        cmd = [
            'xvfb-run', '-a', '-s', '-screen 0 1200x800x24',
            './robot_control_gui'
        ]
        env['DISPLAY'] = ':99'
    else:
        # 使用offscreen平台
        cmd = ['./robot_control_gui']
        env['QT_QPA_PLATFORM'] = 'offscreen'
    
    try:
        print("🚀 启动程序...")
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            cwd='/workspace'
        )
        
        # 等待程序启动
        time.sleep(3)
        
        # 如果程序还在运行，说明启动成功
        if process.poll() is None:
            print("✅ 程序启动成功，正在运行中")
            
            # 等待一段时间让界面完全加载
            time.sleep(2)
            
            # 终止程序
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                
            print("✅ 程序正常关闭")
            return True
        else:
            stdout, stderr = process.communicate()
            print(f"❌ 程序启动失败")
            if stderr:
                print(f"错误信息: {stderr.decode()}")
            return False
            
    except Exception as e:
        print(f"❌ 创建截图失败: {e}")
        return False

def create_ascii_layout():
    """创建ASCII艺术风格的界面布局图"""
    print("\n🎨 创建界面布局图...")
    
    layout_ascii = """
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           🤖 机器人控制上位机 v2.0                              │
├─────────────────────────────────────────┬───────────────────────────────────────┤
│                                         │                                       │
│            📋 关节控制区域               │           🎛️  控制面板区域            │
│  ┌─────────────────────────────────────┐ │                                       │
│  │ 关节控制 │                          │ │  ┌─────────────────────────────────┐  │
│  ├─────────────────────────────────────┤ │  │         🔗 连接控制             │  │
│  │ 🦾 左臂关节 (8个)                   │ │  │  [连接机器人] [断开连接]        │  │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐    │ │  │  [紧急停止]                     │  │
│  │  │关节1│ │关节2│ │关节3│ │关节4│    │ │  │  ────────────────────────       │  │
│  │  └─────┘ └─────┘ └─────┘ └─────┘    │ │  │  ☑️ 仿真模式                    │  │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐    │ │  └─────────────────────────────────┘  │
│  │  │关节5│ │关节6│ │关节7│ │关节8│    │ │                                       │
│  │  └─────┘ └─────┘ └─────┘ └─────┘    │ │  ┌─────────────────────────────────┐  │
│  │                                     │ │  │         📍 位置控制             │  │
│  │ 🦾 右臂关节 (8个)                   │ │  │  [复位到零位] [保存当前位置]    │  │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐    │ │  │  [加载位置]                     │  │
│  │  │关节9│ │关节10│ │关节11│ │关节12│   │ │  └─────────────────────────────────┘  │
│  │  └─────┘ └─────┘ └─────┘ └─────┘    │ │                                       │
│  │  ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐    │ │  ┌─────────────────────────────────┐  │
│  │  │关节13│ │关节14│ │关节15│ │关节16│   │ │  │         ⚡ 关节控制             │  │
│  │  └─────┘ └─────┘ └─────┘ └─────┘    │ │  │  [启用所有关节] [禁用所有关节]  │  │
│  │                                     │ │  └─────────────────────────────────┘  │
│  │ 🏃 腰部关节 (2个) | 🚗 底盘 (2个)    │ │                                       │
│  │ ⬆️ 升降机构 (1个)                    │ │  ┌─────────────────────────────────┐  │
│  └─────────────────────────────────────┘ │  │         📊 状态信息             │  │
├─────────────────────────────────────────┤ │  │  连接状态: 离线                 │  │
│                                         │ │  │  电池电量: ████████░░ 85%       │  │
│           🎮 机器人3D视图                │ │  │  系统温度: 正常                 │  │
│  ┌─────────────────────────────────────┐ │  └─────────────────────────────────┘  │
│  │    Y↑     Z↗                        │ │                                       │
│  │     │    /                          │ │  ┌─────────────────────────────────┐  │
│  │     │   /    ████████████████       │ │  │         🏃 运动状态监控         │  │
│  │     │  /     ████████████████       │ │  │  运动状态: 静止                 │  │
│  │     │ /      ████████████████       │ │  │  当前速度: 0.0 °/s              │  │
│  │     └────────→ X                    │ │  │  目标位置: --                   │  │
│  │                                     │ │  │  运动进度: ████████████ 100%    │  │
│  │   🤖 机器人3D模型渲染区域            │ │  │  活跃关节: 0/21                 │  │
│  │      (实时显示机器人姿态)            │ │  │  运动时间: 00:00                │  │
│  │                                     │ │  └─────────────────────────────────┘  │
│  └─────────────────────────────────────┘ │                                       │
│  🟢 渲染状态: 就绪                       │                                       │
└─────────────────────────────────────────┴───────────────────────────────────────┘
"""
    
    # 保存到文件
    with open('/workspace/UI_LAYOUT_PREVIEW.txt', 'w', encoding='utf-8') as f:
        f.write("# 机器人控制上位机界面布局预览\n\n")
        f.write("## 界面结构说明\n\n")
        f.write("本界面采用水平分割布局，左侧为关节控制和3D渲染区域，右侧为各种控制面板。\n\n")
        f.write("## ASCII界面布局图\n\n")
        f.write("```\n")
        f.write(layout_ascii)
        f.write("\n```\n\n")
        f.write("## 功能区域说明\n\n")
        f.write("### 左侧区域（垂直分割）\n")
        f.write("1. **关节控制标签页**：包含所有21个关节的控制滑块\n")
        f.write("   - 左臂关节：8个关节控制器\n")
        f.write("   - 右臂关节：8个关节控制器\n")
        f.write("   - 腰部关节：2个关节控制器\n")
        f.write("   - 底盘电机：2个关节控制器\n")
        f.write("   - 升降机构：1个关节控制器\n\n")
        f.write("2. **3D渲染窗口**：实时显示机器人运动状态\n")
        f.write("   - 3D坐标轴指示（X-红色，Y-绿色，Z-蓝色）\n")
        f.write("   - 网格背景提供空间参考\n")
        f.write("   - 渲染状态实时显示\n\n")
        f.write("### 右侧控制面板\n")
        f.write("1. **连接控制**：机器人连接管理和仿真模式\n")
        f.write("2. **位置控制**：位置保存、加载和复位功能\n")
        f.write("3. **关节控制**：批量启用/禁用关节\n")
        f.write("4. **状态信息**：连接状态、电池电量、系统温度\n")
        f.write("5. **运动状态监控**：实时运动状态和进度显示\n\n")
        f.write("## 新增功能\n\n")
        f.write("### 🆕 仿真模式\n")
        f.write("- 位置：连接控制面板中的复选框\n")
        f.write("- 功能：允许在不连接真实机器人的情况下进行操作\n")
        f.write("- 状态：启用时所有关节控制器可用，连接按钮被禁用\n\n")
        f.write("### 🆕 3D渲染窗口\n")
        f.write("- 位置：左侧区域下半部分\n")
        f.write("- 功能：实时显示机器人运动状态和姿态\n")
        f.write("- 状态：根据连接状态和仿真模式显示不同的渲染状态\n\n")
    
    print("✅ 界面布局图已保存到 UI_LAYOUT_PREVIEW.txt")
    return True

def main():
    """主函数"""
    print("🎨 UI界面预览生成器")
    print("=" * 50)
    
    # 检查可执行文件
    if not os.path.exists('/workspace/robot_control_gui'):
        print("❌ 可执行文件不存在，请先编译项目")
        return False
    
    # 创建截图
    screenshot_success = create_screenshot()
    
    # 创建ASCII布局图
    layout_success = create_ascii_layout()
    
    print("\n" + "=" * 50)
    print("📊 生成结果:")
    print(f"  程序启动测试: {'✅ 成功' if screenshot_success else '❌ 失败'}")
    print(f"  界面布局图: {'✅ 已生成' if layout_success else '❌ 失败'}")
    
    if screenshot_success and layout_success:
        print("\n🎉 界面预览生成完成！")
        print("\n📝 查看方式:")
        print("  1. 查看界面布局图: cat UI_LAYOUT_PREVIEW.txt")
        print("  2. 在您的本地环境运行程序查看实际界面")
        print("\n🚀 本地运行命令:")
        print("  cd ~/thu/robotsim")
        print("  ./robot_control_gui")
        
        return True
    else:
        print("\n⚠️  部分生成失败，请检查相关问题")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)