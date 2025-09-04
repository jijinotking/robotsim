@echo off
chcp 65001 >nul
title 机器人控制上位机 - Windows构建工具

:start
cls
echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    🤖 机器人控制上位机                        ║
echo ║                     Windows构建工具 v2.0                     ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.
echo 当前目录: %CD%
echo.
echo 请选择操作:
echo.
echo   [1] 🔨 编译项目
echo   [2] 📦 编译并打包
echo   [3] 🧪 测试运行
echo   [4] 🧹 清理项目
echo   [5] 📋 查看项目信息
echo   [6] 🔧 环境检查
echo   [0] 🚪 退出
echo.
echo ────────────────────────────────────────────────────────────────

set /p choice=请输入选项 (0-6): 

if "%choice%"=="1" goto compile
if "%choice%"=="2" goto package
if "%choice%"=="3" goto test
if "%choice%"=="4" goto clean
if "%choice%"=="5" goto info
if "%choice%"=="6" goto check_env
if "%choice%"=="0" goto exit
echo [ERROR] 无效选项，请重新选择
timeout /t 2 >nul
goto start

:compile
echo.
echo ════════════════════════════════════════════════════════════════
echo 🔨 编译项目
echo ════════════════════════════════════════════════════════════════
call build_windows.bat
goto end

:package
echo.
echo ════════════════════════════════════════════════════════════════
echo 📦 编译并打包
echo ════════════════════════════════════════════════════════════════
call build_windows.bat
if exist deploy\robot_control_gui.exe (
    echo.
    echo [SUCCESS] ✅ 打包完成！
    echo 📁 部署文件位置: %CD%\deploy\
    echo 📋 包含文件:
    dir deploy\ /b | findstr /v /c:"platforms" /c:"imageformats" /c:"styles"
    echo    + platforms\ (平台插件)
    echo    + imageformats\ (图像格式插件)
    echo    + 其他Qt依赖库...
) else (
    echo [ERROR] ❌ 打包失败
)
goto end

:test
echo.
echo ════════════════════════════════════════════════════════════════
echo 🧪 测试运行
echo ════════════════════════════════════════════════════════════════
if exist deploy\robot_control_gui.exe (
    echo [INFO] 启动部署版本...
    cd deploy
    start robot_control_gui.exe
    cd ..
    echo [INFO] 程序已启动，请检查界面是否正常显示
) else if exist robot_control_gui.exe (
    echo [INFO] 启动开发版本...
    start robot_control_gui.exe
    echo [INFO] 程序已启动，请检查界面是否正常显示
) else (
    echo [ERROR] ❌ 未找到可执行文件，请先编译项目
)
goto end

:clean
echo.
echo ════════════════════════════════════════════════════════════════
echo 🧹 清理项目
echo ════════════════════════════════════════════════════════════════
echo [INFO] 正在清理编译文件...

if exist robot_control_gui.exe (
    del robot_control_gui.exe
    echo [CLEAN] robot_control_gui.exe
)

if exist Makefile (
    del Makefile*
    echo [CLEAN] Makefile
)

if exist debug (
    rmdir /s /q debug
    echo [CLEAN] debug\
)

if exist release (
    rmdir /s /q release
    echo [CLEAN] release\
)

if exist deploy (
    rmdir /s /q deploy
    echo [CLEAN] deploy\
)

for %%f in (*.o moc_*.cpp moc_*.h ui_*.h qrc_*.cpp) do (
    if exist %%f (
        del %%f
        echo [CLEAN] %%f
    )
)

echo [SUCCESS] ✅ 清理完成
goto end

:info
echo.
echo ════════════════════════════════════════════════════════════════
echo 📋 项目信息
echo ════════════════════════════════════════════════════════════════
echo 项目名称: 机器人控制上位机
echo 版本: v2.0
echo 描述: 轮臂机器人控制软件，支持21个关节控制和3D可视化
echo.
echo 📁 项目文件:
if exist robot_control_gui.pro echo   ✅ robot_control_gui.pro (项目文件)
if exist mainwindow.h echo   ✅ mainwindow.h (主窗口头文件)
if exist mainwindow.cpp echo   ✅ mainwindow.cpp (主窗口实现)
if exist robotcontroller.h echo   ✅ robotcontroller.h (机器人控制器头文件)
if exist robotcontroller.cpp echo   ✅ robotcontroller.cpp (机器人控制器实现)
if exist jointcontrolwidget.h echo   ✅ jointcontrolwidget.h (关节控制组件头文件)
if exist jointcontrolwidget.cpp echo   ✅ jointcontrolwidget.cpp (关节控制组件实现)
if exist main.cpp echo   ✅ main.cpp (主程序入口)

echo.
echo 🎯 功能特性:
echo   • 21个关节控制 (左臂8+右臂8+腰部2+底盘2+升降1)
echo   • 3D机器人可视化渲染窗口
echo   • 仿真模式支持
echo   • 实时运动状态监控
echo   • 位置保存和加载
echo   • 串口通信支持

echo.
echo 📊 编译状态:
if exist robot_control_gui.exe (
    echo   ✅ 开发版本已编译
) else (
    echo   ❌ 开发版本未编译
)

if exist deploy\robot_control_gui.exe (
    echo   ✅ 部署版本已打包
    echo   📁 部署目录大小:
    for /f "tokens=3" %%a in ('dir deploy /s /-c ^| find "个文件"') do echo      %%a 字节
) else (
    echo   ❌ 部署版本未打包
)

goto end

:check_env
echo.
echo ════════════════════════════════════════════════════════════════
echo 🔧 环境检查
echo ════════════════════════════════════════════════════════════════

echo [检查] Qt安装...
set QT_FOUND=0
for %%p in (C:\Qt\5.15.2\mingw81_64 C:\Qt\5.15.2\msvc2019_64 C:\Qt\6.2.0\mingw_64 C:\Qt\6.2.0\msvc2019_64) do (
    if exist "%%p\bin\qmake.exe" (
        echo   ✅ 找到Qt: %%p
        set QT_FOUND=1
    )
)

if %QT_FOUND%==0 (
    echo   ❌ 未找到Qt安装
    echo   💡 请安装Qt开发环境
)

echo.
echo [检查] 编译工具...
where qmake >nul 2>&1
if %errorlevel%==0 (
    echo   ✅ qmake 可用
    qmake -v | findstr "QMake version"
) else (
    echo   ❌ qmake 不可用
)

where mingw32-make >nul 2>&1
if %errorlevel%==0 (
    echo   ✅ MinGW make 可用
) else (
    echo   ⚠️  MinGW make 不可用
)

where nmake >nul 2>&1
if %errorlevel%==0 (
    echo   ✅ MSVC nmake 可用
) else (
    echo   ⚠️  MSVC nmake 不可用
)

echo.
echo [检查] Git...
where git >nul 2>&1
if %errorlevel%==0 (
    echo   ✅ Git 可用
    git --version
) else (
    echo   ❌ Git 不可用
)

echo.
echo [检查] 系统信息...
echo   💻 操作系统: %OS%
echo   🏗️  处理器架构: %PROCESSOR_ARCHITECTURE%
echo   👤 用户: %USERNAME%
echo   📁 当前目录: %CD%

goto end

:end
echo.
echo ────────────────────────────────────────────────────────────────
set /p continue=按任意键返回主菜单，或输入 'q' 退出: 
if /i "%continue%"=="q" goto exit
goto start

:exit
echo.
echo 👋 感谢使用机器人控制上位机构建工具！
echo.
timeout /t 2 >nul