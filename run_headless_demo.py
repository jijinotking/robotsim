#!/usr/bin/env python3
"""
无头模式演示 - 在没有图形界面的环境中演示上位机功能
通过命令行界面模拟上位机的主要功能
"""

import json
import socket
import threading
import time
import sys
from datetime import datetime

class HeadlessRobotController:
    def __init__(self):
        self.socket = None
        self.connected = False
        self.joint_positions = [0.0] * 21
        self.joint_names = [
            "左臂1", "左臂2", "左臂3", "左臂4", "左臂5", "左臂6", "左臂7", "左臂8",
            "右臂1", "右臂2", "右臂3", "右臂4", "右臂5", "右臂6", "右臂7", "右臂8",
            "腰部1", "腰部2", "底盘1", "底盘2", "升降"
        ]
        self.battery_level = 0.0
        self.emergency_stop = False
        
    def connect_to_robot(self, host='127.0.0.1', port=8080):
        """连接到机器人"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((host, port))
            self.connected = True
            print(f"✅ 成功连接到机器人 {host}:{port}")
            
            # 启动状态接收线程
            status_thread = threading.Thread(target=self._receive_status)
            status_thread.daemon = True
            status_thread.start()
            
            return True
        except Exception as e:
            print(f"❌ 连接失败: {e}")
            return False
    
    def disconnect(self):
        """断开连接"""
        self.connected = False
        if self.socket:
            self.socket.close()
        print("🔌 已断开连接")
    
    def _receive_status(self):
        """接收机器人状态"""
        buffer = ""
        while self.connected:
            try:
                data = self.socket.recv(1024).decode('utf-8')
                if not data:
                    break
                
                buffer += data
                while '\n' in buffer:
                    line, buffer = buffer.split('\n', 1)
                    if line.strip():
                        self._process_status(line.strip())
                        
            except Exception as e:
                if self.connected:
                    print(f"❌ 接收状态错误: {e}")
                break
    
    def _process_status(self, status_json):
        """处理状态数据"""
        try:
            status = json.loads(status_json)
            if 'joints' in status:
                self.joint_positions = status['joints'][:21]
            if 'battery' in status:
                self.battery_level = status['battery']
            if 'emergency_stop' in status:
                self.emergency_stop = status['emergency_stop']
        except json.JSONDecodeError:
            pass
    
    def send_command(self, command):
        """发送命令"""
        if not self.connected:
            print("❌ 未连接到机器人")
            return False
        
        try:
            if isinstance(command, dict):
                command_str = json.dumps(command) + '\n'
            else:
                command_str = str(command) + '\n'
            
            self.socket.send(command_str.encode('utf-8'))
            return True
        except Exception as e:
            print(f"❌ 发送命令失败: {e}")
            return False
    
    def set_joint_position(self, joint_id, angle):
        """设置关节位置"""
        if 0 <= joint_id < 21:
            command = {
                "command": "position",
                "joint": joint_id,
                "value": float(angle),
                "timestamp": int(time.time() * 1000)
            }
            if self.send_command(command):
                print(f"📐 设置 {self.joint_names[joint_id]} 到 {angle:.1f}°")
                return True
        return False
    
    def emergency_stop(self):
        """紧急停止"""
        if self.send_command("EMERGENCY_STOP"):
            print("🚨 紧急停止已激活")
            return True
        return False
    
    def reset_to_zero(self):
        """复位到零位"""
        if self.send_command("RESET_ZERO"):
            print("🏠 机器人已复位到零位")
            return True
        return False
    
    def enable_all_joints(self):
        """使能所有关节"""
        if self.send_command("ENABLE_ALL"):
            print("⚡ 所有关节已使能")
            return True
        return False
    
    def disable_all_joints(self):
        """失能所有关节"""
        if self.send_command("DISABLE_ALL"):
            print("🔒 所有关节已失能")
            return True
        return False
    
    def show_status(self):
        """显示当前状态"""
        print("\n" + "="*60)
        print("🤖 机器人状态")
        print("="*60)
        print(f"🔋 电池电量: {self.battery_level:.1f}%")
        print(f"🚨 紧急停止: {'是' if self.emergency_stop else '否'}")
        print(f"🔗 连接状态: {'已连接' if self.connected else '未连接'}")
        
        print("\n📐 关节位置:")
        for i in range(0, 21, 7):
            line = ""
            for j in range(7):
                if i + j < 21:
                    idx = i + j
                    name = self.joint_names[idx]
                    pos = self.joint_positions[idx] if idx < len(self.joint_positions) else 0.0
                    line += f"{name}:{pos:6.1f}° "
            print(f"   {line}")
        print("="*60)

def print_help():
    """打印帮助信息"""
    print("""
🤖 机器人运动控制上位机 - 无头模式演示

可用命令:
  connect              - 连接到机器人模拟器
  disconnect           - 断开连接
  status               - 显示机器人状态
  set <关节ID> <角度>   - 设置关节角度 (例: set 0 45.0)
  zero                 - 复位所有关节到零位
  stop                 - 紧急停止
  enable               - 使能所有关节
  disable              - 失能所有关节
  demo                 - 运行演示动作
  help                 - 显示此帮助信息
  quit                 - 退出程序

关节ID对应:
  0-7:   左臂关节1-8
  8-15:  右臂关节1-8
  16-17: 腰部关节1-2
  18-19: 底盘电机1-2
  20:    升降机构

示例:
  set 0 45.0    # 设置左臂关节1到45度
  set 8 -30.0   # 设置右臂关节1到-30度
""")

def run_demo_sequence(controller):
    """运行演示动作序列"""
    if not controller.connected:
        print("❌ 请先连接到机器人")
        return
    
    print("🎭 开始演示动作序列...")
    
    # 演示序列
    demo_actions = [
        ("复位到零位", lambda: controller.reset_to_zero()),
        ("左臂关节1 -> 45°", lambda: controller.set_joint_position(0, 45.0)),
        ("右臂关节1 -> -45°", lambda: controller.set_joint_position(8, -45.0)),
        ("腰部关节1 -> 30°", lambda: controller.set_joint_position(16, 30.0)),
        ("升降机构 -> 100mm", lambda: controller.set_joint_position(20, 100.0)),
        ("等待2秒", lambda: time.sleep(2)),
        ("左臂关节2 -> 90°", lambda: controller.set_joint_position(1, 90.0)),
        ("右臂关节2 -> -90°", lambda: controller.set_joint_position(9, -90.0)),
        ("等待2秒", lambda: time.sleep(2)),
        ("复位到零位", lambda: controller.reset_to_zero()),
    ]
    
    for i, (description, action) in enumerate(demo_actions, 1):
        print(f"  {i:2d}. {description}")
        action()
        time.sleep(1)
    
    print("✅ 演示动作序列完成")

def main():
    print("🤖 机器人运动控制上位机 - 无头模式演示")
    print("=" * 50)
    print("这是一个命令行版本的机器人控制界面")
    print("适用于没有图形显示的环境")
    print("输入 'help' 查看可用命令")
    print("=" * 50)
    
    controller = HeadlessRobotController()
    
    try:
        while True:
            try:
                command = input("\n🤖 > ").strip().lower()
                
                if command == 'quit' or command == 'exit':
                    break
                elif command == 'help':
                    print_help()
                elif command == 'connect':
                    controller.connect_to_robot()
                elif command == 'disconnect':
                    controller.disconnect()
                elif command == 'status':
                    controller.show_status()
                elif command == 'zero':
                    controller.reset_to_zero()
                elif command == 'stop':
                    controller.emergency_stop()
                elif command == 'enable':
                    controller.enable_all_joints()
                elif command == 'disable':
                    controller.disable_all_joints()
                elif command == 'demo':
                    run_demo_sequence(controller)
                elif command.startswith('set '):
                    try:
                        parts = command.split()
                        if len(parts) == 3:
                            joint_id = int(parts[1])
                            angle = float(parts[2])
                            controller.set_joint_position(joint_id, angle)
                        else:
                            print("❌ 格式错误，使用: set <关节ID> <角度>")
                    except ValueError:
                        print("❌ 参数错误，关节ID必须是整数，角度必须是数字")
                elif command == '':
                    continue
                else:
                    print(f"❌ 未知命令: {command}")
                    print("输入 'help' 查看可用命令")
                    
            except KeyboardInterrupt:
                print("\n\n👋 用户中断，正在退出...")
                break
            except EOFError:
                print("\n\n👋 输入结束，正在退出...")
                break
                
    finally:
        controller.disconnect()
        print("👋 再见！")

if __name__ == "__main__":
    main()