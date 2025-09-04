#!/usr/bin/env python3
"""
机器人模拟器 - 用于测试上位机
模拟一个21自由度的轮臂机器人
"""

import socket
import json
import threading
import time
import math
from datetime import datetime

class RobotSimulator:
    def __init__(self, host='127.0.0.1', port=8080):
        self.host = host
        self.port = port
        self.socket = None
        self.client_socket = None
        self.running = False
        
        # 机器人状态
        self.joint_positions = [0.0] * 21  # 21个关节位置
        self.joint_velocities = [0.0] * 21  # 21个关节速度
        self.joint_torques = [0.0] * 21     # 21个关节扭矩
        self.joint_enabled = [True] * 21    # 21个关节使能状态
        
        self.battery_level = 85.0
        self.emergency_stop = False
        self.error_message = ""
        
        # 关节限制
        self.joint_limits = self._init_joint_limits()
        
        print(f"机器人模拟器初始化完成")
        print(f"监听地址: {host}:{port}")
        print(f"支持21个自由度:")
        print(f"  - 左臂: 8个关节 (ID: 0-7)")
        print(f"  - 右臂: 8个关节 (ID: 8-15)")
        print(f"  - 腰部: 2个关节 (ID: 16-17)")
        print(f"  - 底盘: 2个电机 (ID: 18-19)")
        print(f"  - 升降: 1个电机 (ID: 20)")
    
    def _init_joint_limits(self):
        """初始化关节限制"""
        limits = {}
        
        # 左臂和右臂关节 (0-15): -180 到 180 度
        for i in range(16):
            limits[i] = (-180.0, 180.0)
        
        # 腰部关节 (16-17): -90 到 90 度
        for i in range(16, 18):
            limits[i] = (-90.0, 90.0)
        
        # 底盘电机 (18-19): -1000 到 1000 (速度单位)
        for i in range(18, 20):
            limits[i] = (-1000.0, 1000.0)
        
        # 升降机构 (20): 0 到 500 (位置单位)
        limits[20] = (0.0, 500.0)
        
        return limits
    
    def start_server(self):
        """启动TCP服务器"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.socket.bind((self.host, self.port))
            self.socket.listen(1)
            
            print(f"服务器启动，等待连接...")
            self.running = True
            
            while self.running:
                try:
                    client_socket, addr = self.socket.accept()
                    print(f"客户端连接: {addr}")
                    self.client_socket = client_socket
                    
                    # 启动状态发送线程
                    status_thread = threading.Thread(target=self._send_status_loop)
                    status_thread.daemon = True
                    status_thread.start()
                    
                    # 处理客户端消息
                    self._handle_client(client_socket)
                    
                except socket.error as e:
                    if self.running:
                        print(f"服务器错误: {e}")
                    break
                    
        except Exception as e:
            print(f"启动服务器失败: {e}")
        finally:
            self.stop_server()
    
    def _handle_client(self, client_socket):
        """处理客户端消息"""
        buffer = ""
        
        try:
            while self.running:
                data = client_socket.recv(1024).decode('utf-8')
                if not data:
                    break
                
                buffer += data
                
                # 处理完整的消息（以换行符分隔）
                while '\n' in buffer:
                    line, buffer = buffer.split('\n', 1)
                    if line.strip():
                        self._process_command(line.strip())
                        
        except socket.error as e:
            print(f"客户端连接错误: {e}")
        finally:
            client_socket.close()
            self.client_socket = None
            print("客户端断开连接")
    
    def _process_command(self, command):
        """处理接收到的命令"""
        print(f"[{datetime.now().strftime('%H:%M:%S')}] 收到命令: {command}")
        
        try:
            # 尝试解析JSON命令
            if command.startswith('{'):
                cmd_data = json.loads(command)
                self._handle_json_command(cmd_data)
            else:
                # 处理文本命令
                self._handle_text_command(command)
                
        except json.JSONDecodeError:
            # 处理文本命令
            self._handle_text_command(command)
        except Exception as e:
            print(f"处理命令错误: {e}")
            self.error_message = str(e)
    
    def _handle_json_command(self, cmd_data):
        """处理JSON格式的命令"""
        command = cmd_data.get('command', '')
        joint_id = cmd_data.get('joint', -1)
        value = cmd_data.get('value', 0.0)
        
        if command == 'position' and 0 <= joint_id < 21:
            # 限制关节角度
            min_val, max_val = self.joint_limits[joint_id]
            value = max(min_val, min(max_val, value))
            
            self.joint_positions[joint_id] = value
            print(f"设置关节 {joint_id} 位置: {value:.2f}")
            
        elif command == 'velocity' and 0 <= joint_id < 21:
            self.joint_velocities[joint_id] = value
            print(f"设置关节 {joint_id} 速度: {value:.2f}")
            
        elif command == 'torque' and 0 <= joint_id < 21:
            self.joint_torques[joint_id] = value
            print(f"设置关节 {joint_id} 扭矩: {value:.2f}")
    
    def _handle_text_command(self, command):
        """处理文本格式的命令"""
        cmd_parts = command.split()
        cmd = cmd_parts[0].upper()
        
        if cmd == 'EMERGENCY_STOP':
            self.emergency_stop = True
            # 停止所有关节
            self.joint_velocities = [0.0] * 21
            print("紧急停止激活！")
            
        elif cmd == 'RESET_ZERO':
            self.emergency_stop = False
            self.joint_positions = [0.0] * 21
            self.joint_velocities = [0.0] * 21
            print("机器人复位到零位")
            
        elif cmd == 'ENABLE_ALL':
            self.joint_enabled = [True] * 21
            print("所有关节已使能")
            
        elif cmd == 'DISABLE_ALL':
            self.joint_enabled = [False] * 21
            print("所有关节已失能")
            
        elif cmd == 'ENABLE_JOINT' and len(cmd_parts) > 1:
            try:
                joint_id = int(cmd_parts[1])
                if 0 <= joint_id < 21:
                    self.joint_enabled[joint_id] = True
                    print(f"关节 {joint_id} 已使能")
            except ValueError:
                pass
                
        elif cmd == 'DISABLE_JOINT' and len(cmd_parts) > 1:
            try:
                joint_id = int(cmd_parts[1])
                if 0 <= joint_id < 21:
                    self.joint_enabled[joint_id] = False
                    print(f"关节 {joint_id} 已失能")
            except ValueError:
                pass
    
    def _send_status_loop(self):
        """定期发送机器人状态"""
        while self.running and self.client_socket:
            try:
                status = self._get_robot_status()
                status_json = json.dumps(status) + '\n'
                self.client_socket.send(status_json.encode('utf-8'))
                time.sleep(0.1)  # 10Hz发送频率
                
            except socket.error:
                break
            except Exception as e:
                print(f"发送状态错误: {e}")
                break
    
    def _get_robot_status(self):
        """获取机器人状态"""
        # 模拟电池电量变化
        self.battery_level += (math.sin(time.time() * 0.1) * 0.1)
        self.battery_level = max(20.0, min(100.0, self.battery_level))
        
        # 模拟关节位置的微小变化（模拟真实机器人的反馈）
        noisy_positions = []
        for i, pos in enumerate(self.joint_positions):
            if self.joint_enabled[i] and not self.emergency_stop:
                # 添加小的噪声来模拟真实反馈
                noise = math.sin(time.time() * 2 + i) * 0.1
                noisy_positions.append(pos + noise)
            else:
                noisy_positions.append(pos)
        
        return {
            'joints': noisy_positions,
            'velocities': self.joint_velocities,
            'torques': self.joint_torques,
            'enabled': self.joint_enabled,
            'battery': round(self.battery_level, 1),
            'emergency_stop': self.emergency_stop,
            'error': self.error_message,
            'timestamp': int(time.time() * 1000)
        }
    
    def stop_server(self):
        """停止服务器"""
        self.running = False
        if self.client_socket:
            try:
                self.client_socket.close()
            except:
                pass
        if self.socket:
            try:
                self.socket.close()
            except:
                pass
        print("服务器已停止")
    
    def print_status(self):
        """打印当前状态"""
        print("\n" + "="*50)
        print("机器人状态:")
        print(f"电池电量: {self.battery_level:.1f}%")
        print(f"紧急停止: {'是' if self.emergency_stop else '否'}")
        print(f"错误信息: {self.error_message if self.error_message else '无'}")
        
        print("\n关节位置:")
        joint_names = [
            "左臂1", "左臂2", "左臂3", "左臂4", "左臂5", "左臂6", "左臂7", "左臂8",
            "右臂1", "右臂2", "右臂3", "右臂4", "右臂5", "右臂6", "右臂7", "右臂8",
            "腰部1", "腰部2", "底盘1", "底盘2", "升降"
        ]
        
        for i in range(0, 21, 7):
            line = ""
            for j in range(7):
                if i + j < 21:
                    name = joint_names[i + j]
                    pos = self.joint_positions[i + j]
                    enabled = "✓" if self.joint_enabled[i + j] else "✗"
                    line += f"{name}:{pos:6.1f}°{enabled} "
            print(line)
        print("="*50)

def main():
    """主函数"""
    print("机器人模拟器启动中...")
    print("这个模拟器将模拟一个21自由度的轮臂机器人")
    print("可以与QT上位机进行通信测试")
    print("按 Ctrl+C 退出")
    
    simulator = RobotSimulator()
    
    try:
        # 启动状态打印线程
        def status_printer():
            while True:
                time.sleep(5)
                simulator.print_status()
        
        status_thread = threading.Thread(target=status_printer)
        status_thread.daemon = True
        status_thread.start()
        
        # 启动服务器
        simulator.start_server()
        
    except KeyboardInterrupt:
        print("\n正在关闭模拟器...")
        simulator.stop_server()
        print("模拟器已关闭")

if __name__ == "__main__":
    main()