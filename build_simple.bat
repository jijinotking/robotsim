@echo off
title Robot Control GUI - Build Tool

echo ========================================
echo Robot Control GUI - Build Tool
echo ========================================

REM Auto-detect Qt installation
set QTDIR_FOUND=0
set QT_PATHS=C:\Qt\5.15.2\mingw81_64;C:\Qt\5.15.2\msvc2019_64;C:\Qt\6.2.0\mingw_64;C:\Qt\6.2.0\msvc2019_64;C:\Qt\6.5.0\mingw_64;C:\Qt\6.5.0\msvc2019_64

for %%p in (%QT_PATHS%) do (
    if exist "%%p\bin\qmake.exe" (
        set QTDIR=%%p
        set QTDIR_FOUND=1
        echo [INFO] Found Qt installation: %%p
        goto qt_found
    )
)

:qt_found
if %QTDIR_FOUND%==0 (
    echo [ERROR] Qt installation not found
    echo Please install Qt development environment
    echo Download: https://www.qt.io/download-qt-installer
    pause
    exit /b 1
)

REM Set environment variables
set PATH=%QTDIR%\bin;%PATH%
set QT_PLUGIN_PATH=%QTDIR%\plugins

REM Detect compiler type
if exist "%QTDIR%\bin\mingw32-make.exe" (
    set COMPILER=mingw
    set MAKE_CMD=mingw32-make
    echo [INFO] Using MinGW compiler
) else if exist "%QTDIR%\bin\nmake.exe" (
    set COMPILER=msvc
    set MAKE_CMD=nmake
    echo [INFO] Using MSVC compiler
) else (
    echo [ERROR] No supported compiler found
    pause
    exit /b 1
)

REM Clean old files
echo [STEP] Cleaning old files...
if exist robot_control_gui.exe del robot_control_gui.exe
if exist Makefile del Makefile*
if exist *.o del *.o
if exist debug rmdir /s /q debug
if exist release rmdir /s /q release
if exist moc_*.cpp del moc_*.*
if exist ui_*.h del ui_*.h

REM Generate Makefile
echo [STEP] Generating Makefile...
qmake robot_control_gui.pro -spec win32-g++ "CONFIG+=release"
if errorlevel 1 (
    echo [ERROR] qmake failed
    pause
    exit /b 1
)

REM Compile project
echo [STEP] Compiling project...
%MAKE_CMD%
if errorlevel 1 (
    echo [ERROR] Compilation failed
    pause
    exit /b 1
)

REM Check for executable
if exist robot_control_gui.exe (
    echo [SUCCESS] Compilation successful!
) else if exist release\robot_control_gui.exe (
    copy release\robot_control_gui.exe .
    echo [SUCCESS] Compilation successful!
) else if exist debug\robot_control_gui.exe (
    copy debug\robot_control_gui.exe .
    echo [SUCCESS] Compilation successful!
) else (
    echo [ERROR] Executable not found
    pause
    exit /b 1
)

REM Create deployment directory
echo [STEP] Creating deployment package...
if exist deploy rmdir /s /q deploy
mkdir deploy
copy robot_control_gui.exe deploy\

REM Use windeployqt
cd deploy
echo [INFO] Copying Qt dependencies...
windeployqt --release --no-translations robot_control_gui.exe

REM Check for missing DLLs
if not exist Qt5Core.dll copy "%QTDIR%\bin\Qt5Core.dll" .
if not exist Qt5Gui.dll copy "%QTDIR%\bin\Qt5Gui.dll" .
if not exist Qt5Widgets.dll copy "%QTDIR%\bin\Qt5Widgets.dll" .
if not exist Qt5Network.dll copy "%QTDIR%\bin\Qt5Network.dll" .
if not exist Qt5SerialPort.dll copy "%QTDIR%\bin\Qt5SerialPort.dll" .
if not exist Qt5OpenGL.dll copy "%QTDIR%\bin\Qt5OpenGL.dll" .

REM Copy MinGW runtime if needed
if "%COMPILER%"=="mingw" (
    if exist "%QTDIR%\bin\libgcc_s_seh-1.dll" copy "%QTDIR%\bin\libgcc_s_seh-1.dll" .
    if exist "%QTDIR%\bin\libstdc++-6.dll" copy "%QTDIR%\bin\libstdc++-6.dll" .
    if exist "%QTDIR%\bin\libwinpthread-1.dll" copy "%QTDIR%\bin\libwinpthread-1.dll" .
)

REM Create startup script
echo @echo off > start.bat
echo echo Starting Robot Control GUI... >> start.bat
echo robot_control_gui.exe >> start.bat
echo pause >> start.bat

cd ..

echo.
echo ========================================
echo Build completed successfully!
echo ========================================
echo.
echo Deployment files location: %CD%\deploy\
echo Executable: robot_control_gui.exe
echo.
echo To test: cd deploy ^&^& robot_control_gui.exe
echo.

set /p test_run=Test run the program now? (y/n): 
if /i "%test_run%"=="y" (
    echo Starting program...
    cd deploy
    start robot_control_gui.exe
    cd ..
)

pause