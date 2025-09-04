# 🔧 故障排除指南

## 常见问题及解决方案

### 1. 段错误（Segmentation Fault）

**问题描述**：
```
./start_demo.sh: 第 38 行： 54936 段错误 （核心已转储） ./robot_control_gui
```

**原因分析**：
这通常是由于Qt应用无法连接到图形显示服务器导致的。

**解决方案**：

#### 方案A: 使用命令行模式（推荐）
```bash
./start_demo.sh
# 选择选项3或5（无头模式演示）
```

#### 方案B: 在有图形界面的环境中运行
```bash
# 如果您在本地Ubuntu桌面环境
./start_demo.sh
# 选择选项2或4

# 如果通过SSH连接，启用X11转发
ssh -X username@hostname
cd ~/robot_control_gui
./start_demo.sh
```

#### 方案C: 使用offscreen模式
```bash
export QT_QPA_PLATFORM=offscreen
./robot_control_gui
```

### 2. Qt平台插件错误

**问题描述**：
```
qt.qpa.xcb: could not connect to display
qt.qpa.plugin: Could not load the Qt platform plugin "xcb"
```

**解决方案**：

#### 检查显示环境
```bash
echo $DISPLAY
echo $WAYLAND_DISPLAY
```

#### 安装必要的包
```bash
sudo apt update
sudo apt install -y libqt5gui5 qt5-qmltooling-plugins
```

#### 使用虚拟显示
```bash
# 安装Xvfb
sudo apt install -y xvfb

# 启动虚拟显示
Xvfb :99 -screen 0 1024x768x24 &
export DISPLAY=:99
./robot_control_gui
```

### 3. 编译错误

**问题描述**：
```
fatal error: QtWidgets/QApplication: No such file or directory
```

**解决方案**：
```bash
# 安装Qt开发包
sudo apt update
sudo apt install -y qtbase5-dev qtbase5-dev-tools libqt5serialport5-dev

# 重新编译
./build_project.sh
```

### 4. Python模拟器连接失败

**问题描述**：
```
ConnectionRefusedError: [Errno 111] Connection refused
```

**解决方案**：

#### 检查模拟器是否运行
```bash
# 检查端口占用
netstat -tuln | grep 8080

# 如果没有输出，启动模拟器
python3 robot_simulator.py
```

#### 检查防火墙设置
```bash
# Ubuntu防火墙
sudo ufw status
sudo ufw allow 8080

# 或临时关闭防火墙测试
sudo ufw disable
```

### 5. 权限问题

**问题描述**：
```
Permission denied
```

**解决方案**：
```bash
# 给脚本执行权限
chmod +x *.sh

# 给可执行文件权限
chmod +x robot_control_gui
```

### 6. 依赖库缺失

**问题描述**：
```
error while loading shared libraries: libQt5Core.so.5
```

**解决方案**：
```bash
# 检查依赖
ldd robot_control_gui

# 安装缺失的库
sudo apt install -y libqt5core5a libqt5gui5 libqt5widgets5 libqt5network5 libqt5serialport5

# 更新库缓存
sudo ldconfig
```

### 7. conda环境冲突

**问题描述**：
```
/bin/bash: /home/user/miniconda3/envs/xxx/lib/libtinfo.so.6: no version information available
```

**解决方案**：

#### 方案A: 临时禁用conda
```bash
# 临时禁用conda
conda deactivate
# 或
export PATH="/usr/bin:/bin:$PATH"

# 运行程序
./start_demo.sh
```

#### 方案B: 使用系统Python
```bash
# 使用系统Python运行
/usr/bin/python3 robot_simulator.py
```

#### 方案C: 修复conda环境
```bash
# 运行修复脚本
./fix_ubuntu_issues.sh
```

### 8. 网络端口冲突

**问题描述**：
```
OSError: [Errno 98] Address already in use
```

**解决方案**：
```bash
# 查找占用端口的进程
sudo netstat -tulpn | grep 8080
sudo lsof -i :8080

# 杀死占用进程
sudo kill -9 <PID>

# 或使用不同端口
# 修改robot_simulator.py中的端口号
```

## 🔍 诊断工具

### 系统信息检查
```bash
# 检查系统版本
lsb_release -a

# 检查Qt版本
qmake --version

# 检查Python版本
python3 --version

# 检查显示环境
echo "DISPLAY: $DISPLAY"
echo "XDG_SESSION_TYPE: $XDG_SESSION_TYPE"
```

### 运行环境检查
```bash
# 检查图形环境
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    echo "✅ 图形环境可用"
else
    echo "❌ 无图形环境"
fi

# 检查Qt平台插件
export QT_DEBUG_PLUGINS=1
./robot_control_gui --help
```

### 网络连接检查
```bash
# 检查本地连接
telnet localhost 8080

# 检查端口监听
ss -tuln | grep 8080
```

## 🆘 获取帮助

### 收集诊断信息
```bash
# 创建诊断报告
cat > diagnostic_report.txt << EOF
系统信息:
$(lsb_release -a)

Qt版本:
$(qmake --version)

Python版本:
$(python3 --version)

显示环境:
DISPLAY=$DISPLAY
WAYLAND_DISPLAY=$WAYLAND_DISPLAY
XDG_SESSION_TYPE=$XDG_SESSION_TYPE

依赖检查:
$(ldd robot_control_gui | head -10)

端口检查:
$(netstat -tuln | grep 8080)

错误日志:
$(tail -20 /var/log/syslog | grep -i error)
EOF

echo "诊断报告已保存到 diagnostic_report.txt"
```

### 联系支持
如果以上解决方案都无法解决问题，请：

1. 运行诊断脚本收集信息
2. 记录具体的错误信息
3. 说明您的运行环境（本地/SSH/Docker等）
4. 提供诊断报告

## 🎯 最佳实践

### 推荐的运行环境
1. **本地Ubuntu桌面**：完整的图形界面支持
2. **SSH + X11转发**：`ssh -X` 连接远程机器
3. **VNC远程桌面**：完整的远程图形环境
4. **命令行模式**：无需图形界面，适合服务器环境

### 避免常见问题
1. 在服务器环境优先使用命令行模式
2. 确保所有脚本有执行权限
3. 检查防火墙和端口占用
4. 避免在conda环境中运行系统级程序
5. 定期更新系统和依赖包

---

💡 **提示**：大多数问题都可以通过使用命令行模式（选项3或5）来避免，这是在服务器环境中的推荐方式。