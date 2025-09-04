# 🪟 Windows可执行文件生成指南

## 📋 概述

本指南将帮助您在Windows系统上编译并打包机器人控制上位机为可执行的.exe文件。

## 🛠️ 方法一：Windows本地编译（推荐）

### 第一步：安装Qt开发环境

#### 1.1 下载Qt安装器
- 访问 [Qt官网](https://www.qt.io/download-qt-installer)
- 下载 `qt-unified-windows-x64-online.exe`
- 或使用离线安装器（推荐）

#### 1.2 安装Qt
```
推荐配置：
- Qt版本：Qt 5.15.2 或 Qt 6.x
- 编译器：MinGW 8.1.0 64-bit 或 MSVC 2019 64-bit
- 组件：
  ✅ Qt Charts
  ✅ Qt OpenGL
  ✅ Qt SerialPort
  ✅ Qt Network
  ✅ Qt Widgets
  ✅ MinGW 8.1.0 64-bit (或MSVC)
  ✅ Qt Creator IDE
  ✅ CMake
  ✅ Ninja
```

#### 1.3 安装Git for Windows
- 下载：https://git-scm.com/download/win
- 安装时选择"Git Bash"和"Git GUI"

### 第二步：获取源代码

#### 2.1 克隆项目
```cmd
# 打开Git Bash或命令提示符
git clone https://github.com/jijinotking/robotsim.git
cd robotsim
```

#### 2.2 检查文件
确认以下文件存在：
- `mainwindow.h`
- `mainwindow.cpp`
- `robotcontroller.h`
- `robotcontroller.cpp`
- `jointcontrolwidget.h`
- `jointcontrolwidget.cpp`
- `main.cpp`
- `robot_control_gui.pro`

### 第三步：编译项目

#### 3.1 使用Qt Creator（图形界面方式）
1. 启动Qt Creator
2. 文件 → 打开文件或项目
3. 选择 `robot_control_gui.pro`
4. 选择编译套件（MinGW或MSVC）
5. 点击"配置项目"
6. 点击左下角的"运行"按钮（绿色三角形）

#### 3.2 使用命令行（推荐）
```cmd
# 打开Qt命令提示符（开始菜单搜索"Qt 5.15.2 (MinGW 8.1.0 64-bit)"）
cd /d C:\path\to\robotsim

# 生成Makefile
qmake robot_control_gui.pro

# 编译项目
mingw32-make
# 或者如果使用MSVC：nmake

# 编译完成后会生成 robot_control_gui.exe
```

### 第四步：打包部署

#### 4.1 使用windeployqt工具
```cmd
# 创建部署目录
mkdir deploy
copy robot_control_gui.exe deploy\

# 使用windeployqt自动复制依赖
cd deploy
windeployqt robot_control_gui.exe

# 如果需要调试信息
windeployqt --debug robot_control_gui.exe

# 如果需要发布版本（更小）
windeployqt --release robot_control_gui.exe
```

#### 4.2 手动添加额外依赖（如果需要）
```cmd
# 复制Qt运行时库（如果windeployqt遗漏）
copy "%QTDIR%\bin\Qt5Core.dll" deploy\
copy "%QTDIR%\bin\Qt5Gui.dll" deploy\
copy "%QTDIR%\bin\Qt5Widgets.dll" deploy\
copy "%QTDIR%\bin\Qt5Network.dll" deploy\
copy "%QTDIR%\bin\Qt5SerialPort.dll" deploy\
copy "%QTDIR%\bin\Qt5OpenGL.dll" deploy\

# 复制MinGW运行时（如果使用MinGW）
copy "%QTDIR%\bin\libgcc_s_seh-1.dll" deploy\
copy "%QTDIR%\bin\libstdc++-6.dll" deploy\
copy "%QTDIR%\bin\libwinpthread-1.dll" deploy\
```

### 第五步：测试部署包
```cmd
cd deploy
robot_control_gui.exe
```

## 🔧 方法二：使用批处理脚本自动化

创建 `build_windows.bat` 文件：

```batch
@echo off
echo ========================================
echo 🔨 编译Windows版机器人控制上位机
echo ========================================

REM 设置Qt环境变量（根据您的安装路径调整）
set QTDIR=C:\Qt\5.15.2\mingw81_64
set PATH=%QTDIR%\bin;%PATH%

REM 清理旧文件
echo [STEP] 清理旧文件...
if exist robot_control_gui.exe del robot_control_gui.exe
if exist Makefile del Makefile
if exist *.o del *.o
if exist moc_*.cpp del moc_*.cpp
if exist ui_*.h del ui_*.h

REM 生成Makefile
echo [STEP] 生成Makefile...
qmake robot_control_gui.pro
if errorlevel 1 (
    echo [ERROR] qmake失败
    pause
    exit /b 1
)

REM 编译项目
echo [STEP] 编译项目...
mingw32-make
if errorlevel 1 (
    echo [ERROR] 编译失败
    pause
    exit /b 1
)

REM 创建部署目录
echo [STEP] 创建部署包...
if exist deploy rmdir /s /q deploy
mkdir deploy
copy robot_control_gui.exe deploy\

REM 自动部署依赖
cd deploy
windeployqt --release robot_control_gui.exe

echo [SUCCESS] ✅ 编译完成！
echo 可执行文件位置: %CD%\robot_control_gui.exe
echo.
echo 测试运行:
robot_control_gui.exe

pause
```

## 📦 方法三：创建安装包

### 3.1 使用NSIS创建安装程序

#### 安装NSIS
- 下载：https://nsis.sourceforge.io/Download
- 安装NSIS编译器

#### 创建安装脚本 `installer.nsi`：
```nsis
; 机器人控制上位机安装脚本
!define APPNAME "机器人控制上位机"
!define COMPANYNAME "您的公司名"
!define DESCRIPTION "轮臂机器人控制软件"
!define VERSIONMAJOR 2
!define VERSIONMINOR 0
!define VERSIONBUILD 0

RequestExecutionLevel admin

InstallDir "$PROGRAMFILES64\${APPNAME}"

Name "${APPNAME}"
Icon "icon.ico"
outFile "RobotControlSetup.exe"

page directory
page instfiles

section "install"
    setOutPath $INSTDIR
    
    ; 复制主程序
    file "deploy\robot_control_gui.exe"
    
    ; 复制Qt依赖
    file /r "deploy\*.*"
    
    ; 创建开始菜单快捷方式
    createDirectory "$SMPROGRAMS\${APPNAME}"
    createShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\robot_control_gui.exe"
    createShortCut "$SMPROGRAMS\${APPNAME}\卸载.lnk" "$INSTDIR\uninstall.exe"
    
    ; 创建桌面快捷方式
    createShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\robot_control_gui.exe"
    
    ; 写入卸载信息
    writeUninstaller "$INSTDIR\uninstall.exe"
    
    ; 注册表信息
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$INSTDIR\uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$INSTDIR"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMajor" ${VERSIONMAJOR}
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMinor" ${VERSIONMINOR}
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1
sectionEnd

section "uninstall"
    delete "$INSTDIR\robot_control_gui.exe"
    delete "$INSTDIR\*.*"
    rmDir /r "$INSTDIR"
    
    delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
    delete "$SMPROGRAMS\${APPNAME}\卸载.lnk"
    rmDir "$SMPROGRAMS\${APPNAME}"
    
    delete "$DESKTOP\${APPNAME}.lnk"
    
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
sectionEnd
```

#### 编译安装包：
```cmd
"C:\Program Files (x86)\NSIS\makensis.exe" installer.nsi
```

### 3.2 使用Inno Setup（替代方案）
- 下载：https://jrsoftware.org/isinfo.php
- 使用图形界面创建安装脚本

## 🚀 快速开始脚本

创建 `quick_build.bat`：

```batch
@echo off
title 机器人控制上位机 - Windows构建工具

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    🤖 机器人控制上位机                        ║
echo ║                     Windows构建工具                          ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

echo 请选择构建选项:
echo [1] 编译项目
echo [2] 编译并打包
echo [3] 创建安装包
echo [4] 清理项目
echo [0] 退出
echo.

set /p choice=请输入选项 (0-4): 

if "%choice%"=="1" goto compile
if "%choice%"=="2" goto package
if "%choice%"=="3" goto installer
if "%choice%"=="4" goto clean
if "%choice%"=="0" goto exit
goto start

:compile
echo [执行] 编译项目...
call build_windows.bat
goto end

:package
echo [执行] 编译并打包...
call build_windows.bat
echo [INFO] 打包完成，文件位于 deploy 目录
goto end

:installer
echo [执行] 创建安装包...
if not exist deploy\robot_control_gui.exe (
    echo [ERROR] 请先编译项目
    goto end
)
"C:\Program Files (x86)\NSIS\makensis.exe" installer.nsi
echo [INFO] 安装包创建完成: RobotControlSetup.exe
goto end

:clean
echo [执行] 清理项目...
if exist *.exe del *.exe
if exist *.o del *.o
if exist moc_*.* del moc_*.*
if exist ui_*.h del ui_*.h
if exist Makefile del Makefile
if exist deploy rmdir /s /q deploy
echo [INFO] 清理完成
goto end

:end
echo.
pause

:exit
```

## 🐛 常见问题解决

### 问题1：找不到Qt
```cmd
# 设置Qt环境变量
set QTDIR=C:\Qt\5.15.2\mingw81_64
set PATH=%QTDIR%\bin;%PATH%
```

### 问题2：编译错误
```cmd
# 确保使用正确的编译器
# MinGW用户：
mingw32-make clean
qmake
mingw32-make

# MSVC用户：
nmake clean
qmake
nmake
```

### 问题3：运行时缺少DLL
```cmd
# 使用dependency walker检查依赖
# 或重新运行windeployqt
windeployqt --debug --force robot_control_gui.exe
```

### 问题4：中文显示问题
在main.cpp中添加：
```cpp
#include <QTextCodec>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    
    // 设置中文编码
    QTextCodec::setCodecForLocale(QTextCodec::codecForName("UTF-8"));
    
    MainWindow window;
    window.show();
    
    return app.exec();
}
```

## 📁 最终目录结构

```
robotsim/
├── robot_control_gui.exe          # 主程序
├── deploy/                        # 部署目录
│   ├── robot_control_gui.exe      # 可分发的主程序
│   ├── Qt5Core.dll                # Qt核心库
│   ├── Qt5Gui.dll                 # Qt GUI库
│   ├── Qt5Widgets.dll             # Qt控件库
│   ├── Qt5Network.dll             # Qt网络库
│   ├── Qt5SerialPort.dll          # Qt串口库
│   ├── Qt5OpenGL.dll              # Qt OpenGL库
│   ├── platforms/                 # 平台插件
│   ├── imageformats/              # 图像格式插件
│   └── ...                        # 其他依赖文件
├── RobotControlSetup.exe          # 安装包
├── build_windows.bat              # 构建脚本
├── quick_build.bat                # 快速构建脚本
└── installer.nsi                  # NSIS安装脚本
```

## 🎯 部署检查清单

- [ ] Qt开发环境已安装
- [ ] 项目编译成功
- [ ] robot_control_gui.exe可以运行
- [ ] windeployqt打包完成
- [ ] 在没有Qt环境的机器上测试
- [ ] 所有功能正常工作
- [ ] 中文界面显示正确
- [ ] 创建安装包（可选）

## 📞 技术支持

如果在Windows编译过程中遇到问题，请提供：
1. Windows版本和架构
2. Qt版本和编译器
3. 完整的错误信息
4. 编译日志

这样我可以更好地帮助您解决问题！