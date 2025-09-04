@echo off
chcp 65001 >nul
echo ========================================
echo 🔨 编译Windows版机器人控制上位机
echo ========================================

REM 检测Qt安装路径
set QTDIR_FOUND=0
set QT_PATHS=C:\Qt\5.15.2\mingw81_64;C:\Qt\5.15.2\msvc2019_64;C:\Qt\6.2.0\mingw_64;C:\Qt\6.2.0\msvc2019_64

for %%p in (%QT_PATHS%) do (
    if exist "%%p\bin\qmake.exe" (
        set QTDIR=%%p
        set QTDIR_FOUND=1
        echo [INFO] 找到Qt安装: %%p
        goto qt_found
    )
)

:qt_found
if %QTDIR_FOUND%==0 (
    echo [ERROR] 未找到Qt安装，请手动设置QTDIR环境变量
    echo 例如: set QTDIR=C:\Qt\5.15.2\mingw81_64
    pause
    exit /b 1
)

REM 设置环境变量
set PATH=%QTDIR%\bin;%PATH%
set QT_PLUGIN_PATH=%QTDIR%\plugins

REM 检测编译器类型
if exist "%QTDIR%\bin\mingw32-make.exe" (
    set COMPILER=mingw
    set MAKE_CMD=mingw32-make
    echo [INFO] 使用MinGW编译器
) else if exist "%QTDIR%\bin\nmake.exe" (
    set COMPILER=msvc
    set MAKE_CMD=nmake
    echo [INFO] 使用MSVC编译器
) else (
    echo [ERROR] 未找到支持的编译器
    pause
    exit /b 1
)

REM 清理旧文件
echo [STEP] 清理旧文件...
if exist robot_control_gui.exe del robot_control_gui.exe
if exist Makefile del Makefile
if exist Makefile.Debug del Makefile.Debug
if exist Makefile.Release del Makefile.Release
if exist *.o del *.o
if exist debug rmdir /s /q debug
if exist release rmdir /s /q release
if exist moc_*.cpp del moc_*.cpp
if exist ui_*.h del ui_*.h
if exist qrc_*.cpp del qrc_*.cpp

REM 生成Makefile
echo [STEP] 生成Makefile...
qmake robot_control_gui.pro -spec win32-g++ "CONFIG+=release"
if errorlevel 1 (
    echo [ERROR] qmake失败，请检查.pro文件
    pause
    exit /b 1
)

REM 编译项目
echo [STEP] 编译项目...
%MAKE_CMD%
if errorlevel 1 (
    echo [ERROR] 编译失败，请检查源代码
    pause
    exit /b 1
)

REM 检查生成的可执行文件
if exist robot_control_gui.exe (
    echo [SUCCESS] ✅ 编译成功！
) else if exist release\robot_control_gui.exe (
    copy release\robot_control_gui.exe .
    echo [SUCCESS] ✅ 编译成功！
) else if exist debug\robot_control_gui.exe (
    copy debug\robot_control_gui.exe .
    echo [SUCCESS] ✅ 编译成功！
) else (
    echo [ERROR] 未找到生成的可执行文件
    pause
    exit /b 1
)

REM 创建部署目录
echo [STEP] 创建部署包...
if exist deploy rmdir /s /q deploy
mkdir deploy
copy robot_control_gui.exe deploy\

REM 使用windeployqt自动部署依赖
cd deploy
echo [INFO] 正在复制Qt依赖库...
windeployqt --release --no-translations robot_control_gui.exe
if errorlevel 1 (
    echo [WARNING] windeployqt执行有警告，但可能仍然成功
)

REM 检查关键DLL是否存在
echo [STEP] 检查依赖库...
set MISSING_DLLS=0

if not exist Qt5Core.dll (
    echo [WARNING] 缺少 Qt5Core.dll
    copy "%QTDIR%\bin\Qt5Core.dll" .
    set MISSING_DLLS=1
)

if not exist Qt5Gui.dll (
    echo [WARNING] 缺少 Qt5Gui.dll
    copy "%QTDIR%\bin\Qt5Gui.dll" .
    set MISSING_DLLS=1
)

if not exist Qt5Widgets.dll (
    echo [WARNING] 缺少 Qt5Widgets.dll
    copy "%QTDIR%\bin\Qt5Widgets.dll" .
    set MISSING_DLLS=1
)

if not exist Qt5Network.dll (
    echo [WARNING] 缺少 Qt5Network.dll
    copy "%QTDIR%\bin\Qt5Network.dll" .
    set MISSING_DLLS=1
)

if not exist Qt5SerialPort.dll (
    echo [WARNING] 缺少 Qt5SerialPort.dll
    copy "%QTDIR%\bin\Qt5SerialPort.dll" .
    set MISSING_DLLS=1
)

if not exist Qt5OpenGL.dll (
    echo [WARNING] 缺少 Qt5OpenGL.dll
    copy "%QTDIR%\bin\Qt5OpenGL.dll" .
    set MISSING_DLLS=1
)

REM 复制MinGW运行时（如果使用MinGW）
if "%COMPILER%"=="mingw" (
    if not exist libgcc_s_seh-1.dll (
        if exist "%QTDIR%\bin\libgcc_s_seh-1.dll" copy "%QTDIR%\bin\libgcc_s_seh-1.dll" .
    )
    if not exist libstdc++-6.dll (
        if exist "%QTDIR%\bin\libstdc++-6.dll" copy "%QTDIR%\bin\libstdc++-6.dll" .
    )
    if not exist libwinpthread-1.dll (
        if exist "%QTDIR%\bin\libwinpthread-1.dll" copy "%QTDIR%\bin\libwinpthread-1.dll" .
    )
)

REM 创建启动脚本
echo @echo off > start.bat
echo echo 启动机器人控制上位机... >> start.bat
echo robot_control_gui.exe >> start.bat
echo pause >> start.bat

cd ..

echo.
echo ========================================
echo 🎉 构建完成！
echo ========================================
echo.
echo 📁 部署文件位置: %CD%\deploy\
echo 🚀 可执行文件: robot_control_gui.exe
echo.
echo 📋 部署包内容:
dir deploy\ /b
echo.
echo 🧪 测试运行:
echo    cd deploy
echo    robot_control_gui.exe
echo.
echo 💡 提示: deploy目录包含了所有必要的文件，
echo    可以复制到其他Windows机器上运行。
echo.

REM 询问是否立即测试
set /p test_run=是否立即测试运行程序? (y/n): 
if /i "%test_run%"=="y" (
    echo [INFO] 启动程序进行测试...
    cd deploy
    start robot_control_gui.exe
    cd ..
)

pause