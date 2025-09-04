# 🤖 Robot Control GUI - 机器人运动控制上位机

[![Qt](https://img.shields.io/badge/Qt-5.15+-green.svg)](https://qt.io/)
[![Python](https://img.shields.io/badge/Python-3.9+-blue.svg)](https://python.org/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-18.04%2B-orange.svg)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

一个功能完整的21自由度轮臂机器人运动控制上位机，使用Qt5开发，支持图形界面和命令行两种模式。

## ✨ 主要特性

- 🎯 **21自由度控制**: 左臂8关节 + 右臂8关节 + 腰部2关节 + 底盘2电机 + 升降1电机
- 🖥️ **现代化界面**: 基于Qt5的直观图形用户界面
- 📊 **实时状态监控**: 运动状态、速度、进度实时显示
- 🔧 **多种控制模式**: 单关节控制、批量操作、位置保存/加载
- 🌐 **多协议通信**: TCP/UDP/Serial端口支持
- 💻 **跨平台兼容**: 支持图形界面和命令行模式
- 🛡️ **安全保护**: 紧急停止、关节限位、使能控制

## 🚀 快速开始

### 一键安装（推荐）

```bash
# 下载部署包
wget https://github.com/jijinotking/robotsim/releases/download/v1.0/robot_control_gui_v1.0_ubuntu.tar.gz

# 解压并安装
tar -xzf robot_control_gui_v1.0_ubuntu.tar.gz
cd robot_control_gui_package
./setup_ubuntu_simple.sh

# 编译和运行
cd ~/robot_control_gui
./build_project.sh
./start_demo.sh
```

### 手动安装

```bash
# 安装依赖
sudo apt update
sudo apt install -y qtbase5-dev qtbase5-dev-tools libqt5serialport5-dev \
    build-essential cmake python3 python3-pip git

# 克隆仓库
git clone https://github.com/jijinotking/robotsim.git
cd robotsim

# 编译项目
qmake robot_control_gui.pro
make -j$(nproc)

# 运行
./robot_control_gui
```

## 📱 界面预览

### 主控制界面
- 左侧：21个关节的独立控制面板
- 右侧：连接控制、位置管理、运动状态监控
- 底部：系统日志显示

### 运动状态面板（新功能）
- 🟢 **运动状态**: 静止/运动中/离线状态指示
- ⚡ **当前速度**: 实时显示综合运动速度
- 🎯 **目标位置**: 当前设置的目标位置
- 📊 **运动进度**: 可视化进度条
- 🔧 **活跃关节**: 显示启用的关节数量
- ⏱️ **运动时间**: 持续运动时间统计

## 🎮 使用方法

### 图形界面模式

```bash
# 启动完整演示
./start_demo.sh
# 选择选项4: 同时启动模拟器和GUI

# 基本操作流程
1. 点击"连接机器人"按钮
2. 调整各关节角度值
3. 观察运动状态面板的实时反馈
4. 使用"保存位置"/"加载位置"管理预设
5. 紧急情况下点击"紧急停止"
```

### 命令行模式

```bash
# 启动命令行演示
./start_demo.sh
# 选择选项5: 无头模式演示

# 可用命令
connect          # 连接机器人
status           # 查看状态
set 0 45.0       # 设置关节0到45度
enable 0         # 使能关节0
disable 0        # 失能关节0
zero             # 所有关节归零
quit             # 退出程序
```

## 🏗️ 项目结构

```
robot_control_gui/
├── 📁 src/                     # 源代码
│   ├── main.cpp               # 程序入口
│   ├── mainwindow.h/cpp       # 主窗口（含运动状态显示）
│   ├── robotcontroller.h/cpp  # 机器人控制器
│   └── jointcontrolwidget.h/cpp # 关节控制组件
├── 📁 simulator/              # Python模拟器
│   ├── robot_simulator.py     # 机器人模拟器
│   └── run_headless_demo.py   # 命令行演示
├── 📁 scripts/                # 部署脚本
│   ├── setup_ubuntu_simple.sh # 简化安装脚本
│   ├── build_project.sh       # 编译脚本
│   └── start_demo.sh          # 启动脚本
└── 📁 docs/                   # 文档
    ├── README.md              # 项目说明
    ├── QUICK_DEPLOY_GUIDE.md  # 快速部署指南
    └── UI_MODIFICATION_GUIDE.md # 界面修改指南
```

## 🔧 系统要求

- **操作系统**: Ubuntu 18.04/20.04/22.04
- **内存**: 至少2GB可用空间
- **依赖**: Qt5.15+, Python3.9+, GCC编译器
- **网络**: 需要网络连接下载依赖包

## 📊 技术栈

- **前端**: Qt5 C++ (图形界面)
- **后端**: Python3 (模拟器)
- **通信**: JSON over TCP/UDP/Serial
- **构建**: qmake + make
- **部署**: Shell脚本自动化

## 🛠️ 开发指南

### 添加新功能

1. **修改界面**: 参考 `docs/UI_MODIFICATION_GUIDE.md`
2. **扩展控制器**: 在 `robotcontroller.cpp` 中添加新方法
3. **通信协议**: 修改JSON消息格式
4. **编译测试**: 运行 `./build_project.sh`

### 自定义机器人配置

```cpp
// 在 mainwindow.cpp 中修改关节配置
const int LEFT_ARM_JOINTS = 8;   // 左臂关节数
const int RIGHT_ARM_JOINTS = 8;  // 右臂关节数
const int WAIST_JOINTS = 2;      // 腰部关节数
const int CHASSIS_MOTORS = 2;    // 底盘电机数
const int LIFT_MOTORS = 1;       // 升降电机数
```

## 🐛 故障排除

### 常见问题

1. **编译失败**
   ```bash
   sudo apt install qtbase5-dev libqt5serialport5-dev
   ```

2. **无法连接机器人**
   ```bash
   # 检查端口占用
   netstat -tuln | grep 8080
   ```

3. **图形界面无法显示**
   ```bash
   # 使用命令行模式
   python3 run_headless_demo.py
   ```

4. **conda环境冲突**
   ```bash
   ./fix_ubuntu_issues.sh
   ```

### 获取帮助

- 📖 查看详细文档: `docs/`
- 🔍 运行诊断: `./verify_installation.sh`
- 🐛 提交Issue: [GitHub Issues](https://github.com/jijinotking/robotsim/issues)

## 📈 版本历史

### v1.0 (2024)
- ✅ 完整的21自由度控制界面
- ✅ 实时运动状态监控
- ✅ TCP/UDP/Serial通信支持
- ✅ Python模拟器
- ✅ 自动化部署脚本
- ✅ 图形界面和命令行双模式

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 👥 作者

- **开发者**: jijinotking
- **邮箱**: [您的邮箱]
- **GitHub**: [@jijinotking](https://github.com/jijinotking)

## 🙏 致谢

- Qt框架提供的优秀GUI支持
- Python社区的丰富生态
- Ubuntu系统的稳定平台
- 所有贡献者和用户的支持

---

⭐ 如果这个项目对您有帮助，请给个Star支持一下！

🤖 **开始您的机器人控制之旅吧！**