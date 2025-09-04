@echo off
chcp 65001 >nul
title 机器人控制上位机 - Windows部署包创建工具

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                    🤖 机器人控制上位机                        ║
echo ║                  Windows部署包创建工具                        ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

REM 检查是否已编译
if not exist deploy\robot_control_gui.exe (
    echo [ERROR] ❌ 未找到部署版本，请先运行编译
    echo.
    echo 请执行以下步骤：
    echo   1. 运行 build_windows.bat 编译项目
    echo   2. 确保 deploy\robot_control_gui.exe 存在
    echo   3. 重新运行此脚本
    echo.
    pause
    exit /b 1
)

echo [INFO] ✅ 找到部署版本，开始创建部署包...
echo.

REM 创建发布目录
set RELEASE_DIR=RobotControl_v2.0_Windows
if exist %RELEASE_DIR% rmdir /s /q %RELEASE_DIR%
mkdir %RELEASE_DIR%

echo [STEP] 📁 复制程序文件...
xcopy deploy\*.* %RELEASE_DIR%\ /E /I /H /Y
if errorlevel 1 (
    echo [ERROR] ❌ 复制程序文件失败
    pause
    exit /b 1
)

echo [STEP] 📄 复制文档文件...
if exist README.md copy README.md %RELEASE_DIR%\
if exist USAGE_GUIDE.md copy USAGE_GUIDE.md %RELEASE_DIR%\
if exist NEW_FEATURES_GUIDE.md copy NEW_FEATURES_GUIDE.md %RELEASE_DIR%\
if exist UI_LAYOUT_PREVIEW.txt copy UI_LAYOUT_PREVIEW.txt %RELEASE_DIR%\
if exist LOCAL_TEST_GUIDE.md copy LOCAL_TEST_GUIDE.md %RELEASE_DIR%\
if exist WINDOWS_BUILD_GUIDE.md copy WINDOWS_BUILD_GUIDE.md %RELEASE_DIR%\

echo [STEP] 📝 创建说明文件...

REM 创建运行说明
echo 机器人控制上位机 v2.0 > %RELEASE_DIR%\运行说明.txt
echo ================================ >> %RELEASE_DIR%\运行说明.txt
echo. >> %RELEASE_DIR%\运行说明.txt
echo 🚀 快速开始： >> %RELEASE_DIR%\运行说明.txt
echo   双击 robot_control_gui.exe 启动程序 >> %RELEASE_DIR%\运行说明.txt
echo. >> %RELEASE_DIR%\运行说明.txt
echo 🎯 主要功能： >> %RELEASE_DIR%\运行说明.txt
echo   • 21个关节控制 (左臂8+右臂8+腰部2+底盘2+升降1) >> %RELEASE_DIR%\运行说明.txt
echo   • 3D机器人可视化渲染窗口 >> %RELEASE_DIR%\运行说明.txt
echo   • 仿真模式支持 >> %RELEASE_DIR%\运行说明.txt
echo   • 实时运动状态监控 >> %RELEASE_DIR%\运行说明.txt
echo   • 位置保存和加载 >> %RELEASE_DIR%\运行说明.txt
echo. >> %RELEASE_DIR%\运行说明.txt
echo 🔧 系统要求： >> %RELEASE_DIR%\运行说明.txt
echo   • Windows 7/8/10/11 (64位) >> %RELEASE_DIR%\运行说明.txt
echo   • 2GB RAM >> %RELEASE_DIR%\运行说明.txt
echo   • 支持OpenGL的显卡 >> %RELEASE_DIR%\运行说明.txt
echo. >> %RELEASE_DIR%\运行说明.txt
echo 📞 技术支持： >> %RELEASE_DIR%\运行说明.txt
echo   项目地址: https://github.com/jijinotking/robotsim >> %RELEASE_DIR%\运行说明.txt
echo   问题反馈: https://github.com/jijinotking/robotsim/issues >> %RELEASE_DIR%\运行说明.txt

REM 创建启动脚本
echo @echo off > %RELEASE_DIR%\启动程序.bat
echo title 机器人控制上位机 >> %RELEASE_DIR%\启动程序.bat
echo echo 正在启动机器人控制上位机... >> %RELEASE_DIR%\启动程序.bat
echo echo. >> %RELEASE_DIR%\启动程序.bat
echo robot_control_gui.exe >> %RELEASE_DIR%\启动程序.bat
echo if errorlevel 1 ( >> %RELEASE_DIR%\启动程序.bat
echo     echo 程序启动失败，请检查系统环境 >> %RELEASE_DIR%\启动程序.bat
echo     pause >> %RELEASE_DIR%\启动程序.bat
echo ) >> %RELEASE_DIR%\启动程序.bat

REM 创建版本信息文件
echo 机器人控制上位机 v2.0 > %RELEASE_DIR%\版本信息.txt
echo ================================ >> %RELEASE_DIR%\版本信息.txt
echo. >> %RELEASE_DIR%\版本信息.txt
echo 版本: 2.0.0 >> %RELEASE_DIR%\版本信息.txt
echo 构建日期: %date% %time% >> %RELEASE_DIR%\版本信息.txt
echo 构建平台: Windows >> %RELEASE_DIR%\版本信息.txt
echo. >> %RELEASE_DIR%\版本信息.txt
echo 🆕 新增功能: >> %RELEASE_DIR%\版本信息.txt
echo   • 3D机器人渲染窗口 >> %RELEASE_DIR%\版本信息.txt
echo   • 仿真模式支持 >> %RELEASE_DIR%\版本信息.txt
echo   • 增强的运动状态监控 >> %RELEASE_DIR%\版本信息.txt
echo   • 改进的用户界面布局 >> %RELEASE_DIR%\版本信息.txt
echo. >> %RELEASE_DIR%\版本信息.txt
echo 🔧 技术改进: >> %RELEASE_DIR%\版本信息.txt
echo   • 修复了界面初始化问题 >> %RELEASE_DIR%\版本信息.txt
echo   • 优化了关节控制响应速度 >> %RELEASE_DIR%\版本信息.txt
echo   • 增强了错误处理机制 >> %RELEASE_DIR%\版本信息.txt
echo   • 改进了内存管理 >> %RELEASE_DIR%\版本信息.txt

echo [STEP] 📊 检查部署包内容...
echo.
echo 📁 部署包内容 (%RELEASE_DIR%):
dir %RELEASE_DIR% /b
echo.
echo 📊 部署包大小:
for /f "tokens=3" %%a in ('dir %RELEASE_DIR% /s /-c ^| find "个文件"') do echo   总大小: %%a 字节

echo.
echo [STEP] 🗜️ 创建ZIP压缩包...
if exist %RELEASE_DIR%.zip del %RELEASE_DIR%.zip

REM 尝试使用PowerShell创建ZIP
powershell -command "Compress-Archive -Path '%RELEASE_DIR%\*' -DestinationPath '%RELEASE_DIR%.zip' -Force" 2>nul
if exist %RELEASE_DIR%.zip (
    echo [SUCCESS] ✅ ZIP压缩包创建成功: %RELEASE_DIR%.zip
) else (
    echo [WARNING] ⚠️  ZIP压缩包创建失败，请手动压缩 %RELEASE_DIR% 目录
)

echo.
echo [STEP] 🧪 测试部署包...
echo [INFO] 启动程序进行测试...
cd %RELEASE_DIR%
start robot_control_gui.exe
cd ..

echo.
echo ════════════════════════════════════════════════════════════════
echo 🎉 Windows部署包创建完成！
echo ════════════════════════════════════════════════════════════════
echo.
echo 📁 部署包目录: %RELEASE_DIR%\
echo 📦 压缩包文件: %RELEASE_DIR%.zip
echo.
echo 📋 包含内容:
echo   ✅ robot_control_gui.exe (主程序)
echo   ✅ Qt运行时库 (Qt5*.dll)
echo   ✅ 平台插件 (platforms\)
echo   ✅ 图像格式插件 (imageformats\)
echo   ✅ 用户文档和说明
echo   ✅ 启动脚本和版本信息
echo.
echo 🚀 分发说明:
echo   1. 将 %RELEASE_DIR%.zip 发送给用户
echo   2. 用户解压到任意目录
echo   3. 双击 robot_control_gui.exe 或 启动程序.bat 运行
echo.
echo 💡 提示: 
echo   • 此部署包可在任何Windows 7+系统上运行
echo   • 无需安装Qt开发环境
echo   • 包含所有必要的运行时依赖
echo.

REM 询问是否创建安装包
set /p create_installer=是否创建NSIS安装包? (需要安装NSIS) (y/n): 
if /i "%create_installer%"=="y" (
    echo.
    echo [STEP] 📦 创建NSIS安装包...
    
    REM 检查NSIS是否安装
    if exist "C:\Program Files (x86)\NSIS\makensis.exe" (
        "C:\Program Files (x86)\NSIS\makensis.exe" installer.nsi
        if exist RobotControlSetup_v2.0.0.exe (
            echo [SUCCESS] ✅ 安装包创建成功: RobotControlSetup_v2.0.0.exe
        ) else (
            echo [ERROR] ❌ 安装包创建失败
        )
    ) else (
        echo [ERROR] ❌ 未找到NSIS，请先安装NSIS
        echo 下载地址: https://nsis.sourceforge.io/Download
    )
)

echo.
pause