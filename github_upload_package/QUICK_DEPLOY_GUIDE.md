# 机器人控制上位机 - 快速部署指南

## 📦 部署包下载

**文件名**: `robot_control_gui_v1.0_ubuntu.tar.gz`  
**大小**: 144KB  
**支持系统**: Ubuntu 18.04/20.04/22.04  

## 🚀 一键部署（推荐）

### 1. 下载并解压
```bash
# 下载部署包（替换为实际下载链接）
wget [下载链接]/robot_control_gui_v1.0_ubuntu.tar.gz

# 解压
tar -xzf robot_control_gui_v1.0_ubuntu.tar.gz
cd robot_control_gui_package
```

### 2. 运行自动安装脚本
```bash
# 给脚本执行权限
chmod +x setup_ubuntu_environment.sh

# 运行安装脚本（需要sudo权限安装系统包）
./setup_ubuntu_environment.sh
```

### 3. 重新加载环境
```bash
# 重新加载bash环境
source ~/.bashrc

# 或者重新打开终端
```

### 4. 编译和运行
```bash
# 进入项目目录
cd ~/robot_control_gui

# 编译项目
./build_project.sh

# 运行演示
./start_demo.sh
```

## 🛠️ 手动部署（高级用户）

如果自动安装脚本遇到问题，可以手动执行以下步骤：

### 1. 安装系统依赖
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装基础工具
sudo apt install -y build-essential cmake git wget curl

# 安装Qt5开发环境
sudo apt install -y qtbase5-dev qtbase5-dev-tools qtcreator \
    qt5-qmake qtchooser libqt5serialport5-dev qttranslations5-l10n

# 安装Python3
sudo apt install -y python3 python3-pip python3-dev python3-venv
```

### 2. 安装Miniconda（可选）
```bash
# 下载Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# 安装
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda3

# 初始化
$HOME/miniconda3/bin/conda init bash
source ~/.bashrc

# 创建环境
conda create -n robot_control python=3.9 -y
conda activate robot_control
```

### 3. 设置项目
```bash
# 创建项目目录
mkdir -p ~/robot_control_gui
cd ~/robot_control_gui

# 复制项目文件（从解压的部署包）
cp /path/to/robot_control_gui_package/* .

# 设置权限
chmod +x *.sh *.py
```

### 4. 编译项目
```bash
# 清理并编译
qmake robot_control_gui.pro
make clean
make -j$(nproc)
```

## 🧪 验证安装

### 运行验证脚本
```bash
cd ~/robot_control_gui
./verify_installation.sh
```

### 手动验证
```bash
# 检查Qt环境
qmake --version

# 检查Python环境
python3 --version

# 检查项目文件
ls -la ~/robot_control_gui/

# 检查可执行文件
./robot_control_gui --version 2>/dev/null || echo "需要图形界面"
```

## 🎮 使用方法

### 图形界面模式（推荐）
```bash
cd ~/robot_control_gui

# 启动完整演示（模拟器+GUI）
./start_demo.sh
# 选择选项5: 同时启动模拟器和QT上位机

# 或者分别启动
# 终端1: 启动模拟器
python3 robot_simulator.py

# 终端2: 启动GUI
./robot_control_gui
```

### 命令行模式（无图形界面）
```bash
cd ~/robot_control_gui

# 启动命令行演示
./start_demo.sh
# 选择选项5: 同时启动模拟器和无头模式演示

# 或者分别启动
# 终端1: 启动模拟器
python3 robot_simulator.py

# 终端2: 启动命令行界面
python3 run_headless_demo.py
```

## 🔧 常见问题解决

### 1. Qt相关错误
```bash
# 错误: qmake: command not found
sudo apt install qt5-qmake qtbase5-dev

# 错误: could not connect to display
export DISPLAY=:0  # 或使用命令行模式

# 错误: Qt platform plugin "xcb" 
sudo apt install qt5-gtk-platformtheme
```

### 2. 编译错误
```bash
# 错误: No rule to make target
qmake robot_control_gui.pro
make clean && make

# 错误: cannot find -lQt5SerialPort
sudo apt install libqt5serialport5-dev

# 错误: Permission denied
chmod +x robot_control_gui
```

### 3. Python错误
```bash
# 错误: python3: command not found
sudo apt install python3 python3-pip

# 错误: ModuleNotFoundError
pip3 install numpy matplotlib  # 根据需要安装

# 错误: conda: command not found
source ~/.bashrc  # 重新加载环境
```

### 4. 网络连接问题
```bash
# 检查端口占用
netstat -tuln | grep 8080

# 检查防火墙
sudo ufw status
sudo ufw allow 8080  # 如果需要
```

## 📁 项目结构

```
~/robot_control_gui/
├── main.cpp                    # 主程序入口
├── mainwindow.h/cpp           # 主窗口实现
├── robotcontroller.h/cpp      # 机器人控制器
├── jointcontrolwidget.h/cpp   # 关节控制组件
├── robot_control_gui.pro      # Qt项目文件
├── mainwindow.ui              # UI界面文件
├── robot_simulator.py         # Python机器人模拟器
├── run_headless_demo.py       # 无头模式演示
├── build_project.sh           # 编译脚本
├── start_demo.sh              # 启动脚本
├── verify_installation.sh     # 验证脚本
├── uninstall.sh               # 卸载脚本
├── README.md                  # 项目说明
├── PROJECT_SUMMARY.md         # 项目总结
└── DEPLOYMENT_README.md       # 部署说明
```

## 🗑️ 卸载

```bash
cd ~/robot_control_gui
./uninstall.sh
```

## 📞 技术支持

如果遇到问题，请按以下顺序排查：

1. **运行验证脚本**: `./verify_installation.sh`
2. **查看系统日志**: `journalctl -f`
3. **检查环境变量**: `env | grep -E "(PATH|QT|CONDA)"`
4. **重新安装**: 删除项目目录后重新部署

## 🎯 快速测试

部署完成后，可以运行以下命令快速测试：

```bash
cd ~/robot_control_gui

# 测试编译
./build_project.sh

# 测试模拟器
timeout 5s python3 robot_simulator.py &
sleep 1
echo '{"command":"position","joint":0,"value":45.0}' | nc localhost 8080
pkill -f robot_simulator.py

# 测试无头模式（需要手动退出）
# python3 run_headless_demo.py
```

---

**版本**: 1.0  
**更新日期**: 2024年  
**支持系统**: Ubuntu 18.04/20.04/22.04  
**许可证**: MIT