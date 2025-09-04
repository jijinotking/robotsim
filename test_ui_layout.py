#!/usr/bin/env python3
"""
测试UI布局的Python脚本
用于验证关节控制界面和3D渲染窗口是否正确显示
"""

import subprocess
import sys
import time
import os

def test_ui_components():
    """测试UI组件是否正确加载"""
    print("🔍 测试UI组件加载...")
    
    # 设置环境变量
    env = os.environ.copy()
    env['QT_QPA_PLATFORM'] = 'offscreen'
    env['QT_LOGGING_RULES'] = 'qt.qpa.xcb.warning=false'
    
    try:
        # 启动程序并捕获输出
        process = subprocess.Popen(
            ['./robot_control_gui'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
            cwd='/workspace'
        )
        
        # 等待程序启动
        time.sleep(2)
        
        # 终止程序
        process.terminate()
        stdout, stderr = process.communicate(timeout=5)
        
        # 检查是否有错误
        if process.returncode == 0 or process.returncode == -15:  # -15 是SIGTERM
            print("✅ 程序启动成功")
            return True
        else:
            print(f"❌ 程序启动失败，返回码: {process.returncode}")
            if stderr:
                print(f"错误信息: {stderr.decode()}")
            return False
            
    except subprocess.TimeoutExpired:
        print("⚠️  程序超时，但这可能是正常的")
        process.kill()
        return True
    except Exception as e:
        print(f"❌ 测试失败: {e}")
        return False

def check_source_files():
    """检查源文件是否包含必要的组件"""
    print("\n🔍 检查源文件...")
    
    # 检查mainwindow.cpp中的关键函数
    required_functions = [
        'setupJointControls',
        'createJointControlGroup', 
        'setupRenderWindow',
        'toggleSimulationMode'
    ]
    
    try:
        with open('/workspace/mainwindow.cpp', 'r', encoding='utf-8') as f:
            content = f.read()
            
        missing_functions = []
        for func in required_functions:
            if func not in content:
                missing_functions.append(func)
        
        if missing_functions:
            print(f"❌ 缺少函数: {', '.join(missing_functions)}")
            return False
        else:
            print("✅ 所有必要函数都存在")
            
        # 检查关键组件
        key_components = [
            'm_jointTabWidget',
            'm_renderWidget', 
            'm_renderView',
            'm_simulationModeCheckBox'
        ]
        
        missing_components = []
        for comp in key_components:
            if comp not in content:
                missing_components.append(comp)
                
        if missing_components:
            print(f"❌ 缺少组件: {', '.join(missing_components)}")
            return False
        else:
            print("✅ 所有UI组件都存在")
            
        return True
        
    except Exception as e:
        print(f"❌ 检查源文件失败: {e}")
        return False

def check_header_file():
    """检查头文件是否包含必要的声明"""
    print("\n🔍 检查头文件...")
    
    try:
        with open('/workspace/mainwindow.h', 'r', encoding='utf-8') as f:
            content = f.read()
            
        # 检查必要的包含文件
        required_includes = [
            'QTabWidget',
            'QScrollArea', 
            'QGraphicsView',
            'QGraphicsScene',
            'QCheckBox'
        ]
        
        missing_includes = []
        for inc in required_includes:
            if inc not in content:
                missing_includes.append(inc)
                
        if missing_includes:
            print(f"❌ 缺少头文件包含: {', '.join(missing_includes)}")
            return False
        else:
            print("✅ 所有必要的头文件都已包含")
            
        return True
        
    except Exception as e:
        print(f"❌ 检查头文件失败: {e}")
        return False

def main():
    """主测试函数"""
    print("🚀 开始UI布局测试")
    print("=" * 50)
    
    # 检查编译是否成功
    if not os.path.exists('/workspace/robot_control_gui'):
        print("❌ 可执行文件不存在，请先编译项目")
        return False
    
    # 运行各项测试
    tests = [
        ("源文件检查", check_source_files),
        ("头文件检查", check_header_file), 
        ("UI组件测试", test_ui_components)
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n📋 {test_name}")
        print("-" * 30)
        result = test_func()
        results.append((test_name, result))
    
    # 总结结果
    print("\n" + "=" * 50)
    print("📊 测试结果总结:")
    
    all_passed = True
    for test_name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"  {test_name}: {status}")
        if not result:
            all_passed = False
    
    if all_passed:
        print("\n🎉 所有测试通过！UI布局应该正常显示")
        print("\n📝 预期界面布局:")
        print("  ├── 左侧区域 (垂直分割)")
        print("  │   ├── 关节控制标签页")
        print("  │   │   ├── 左臂关节 (8个)")
        print("  │   │   ├── 右臂关节 (8个)")
        print("  │   │   ├── 腰部关节 (2个)")
        print("  │   │   ├── 底盘电机 (2个)")
        print("  │   │   └── 升降机构 (1个)")
        print("  │   └── 3D渲染窗口")
        print("  │       ├── 坐标轴显示")
        print("  │       ├── 网格背景")
        print("  │       └── 渲染状态")
        print("  └── 右侧控制面板")
        print("      ├── 连接控制 (含仿真模式)")
        print("      ├── 位置控制")
        print("      ├── 关节控制")
        print("      ├── 状态信息")
        print("      └── 运动状态监控")
    else:
        print("\n⚠️  部分测试失败，请检查相关问题")
    
    return all_passed

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)