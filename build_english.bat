@echo off
title Robot Control GUI - Build Tool

:start
cls
echo.
echo ===============================================================
echo                    Robot Control GUI                          
echo                   Windows Build Tool v2.0                    
echo ===============================================================
echo.
echo Current Directory: %CD%
echo.
echo Please select an option:
echo.
echo   [1] Compile Project
echo   [2] Compile and Package
echo   [3] Test Run
echo   [4] Clean Project
echo   [5] Project Information
echo   [6] Environment Check
echo   [0] Exit
echo.
echo ---------------------------------------------------------------

set /p choice=Please enter option (0-6): 

if "%choice%"=="1" goto compile
if "%choice%"=="2" goto package
if "%choice%"=="3" goto test
if "%choice%"=="4" goto clean
if "%choice%"=="5" goto info
if "%choice%"=="6" goto check_env
if "%choice%"=="0" goto exit
echo [ERROR] Invalid option, please try again
timeout /t 2 >nul
goto start

:compile
echo.
echo ===============================================================
echo Compiling Project
echo ===============================================================
call :do_compile
goto end

:package
echo.
echo ===============================================================
echo Compile and Package
echo ===============================================================
call :do_compile
if errorlevel 1 goto end
call :do_package
goto end

:test
echo.
echo ===============================================================
echo Test Run
echo ===============================================================
if exist deploy\robot_control_gui.exe (
    echo [INFO] Starting deployment version...
    cd deploy
    start robot_control_gui.exe
    cd ..
    echo [INFO] Program started, please check if interface displays correctly
) else if exist robot_control_gui.exe (
    echo [INFO] Starting development version...
    start robot_control_gui.exe
    echo [INFO] Program started, please check if interface displays correctly
) else (
    echo [ERROR] Executable not found, please compile project first
)
goto end

:clean
echo.
echo ===============================================================
echo Clean Project
echo ===============================================================
echo [INFO] Cleaning compilation files...

if exist robot_control_gui.exe del robot_control_gui.exe
if exist Makefile del Makefile*
if exist debug rmdir /s /q debug
if exist release rmdir /s /q release
if exist deploy rmdir /s /q deploy
for %%f in (*.o moc_*.cpp moc_*.h ui_*.h qrc_*.cpp) do if exist %%f del %%f

echo [SUCCESS] Cleaning completed
goto end

:info
echo.
echo ===============================================================
echo Project Information
echo ===============================================================
echo Project Name: Robot Control GUI
echo Version: v2.0
echo Description: Dual-arm robot control software with 21-joint control and 3D visualization
echo.
echo Project Files:
if exist robot_control_gui.pro echo   [OK] robot_control_gui.pro
if exist mainwindow.h echo   [OK] mainwindow.h
if exist mainwindow.cpp echo   [OK] mainwindow.cpp
if exist robotcontroller.h echo   [OK] robotcontroller.h
if exist robotcontroller.cpp echo   [OK] robotcontroller.cpp
if exist jointcontrolwidget.h echo   [OK] jointcontrolwidget.h
if exist jointcontrolwidget.cpp echo   [OK] jointcontrolwidget.cpp
if exist main.cpp echo   [OK] main.cpp

echo.
echo Build Status:
if exist robot_control_gui.exe (
    echo   [OK] Development version compiled
) else (
    echo   [NO] Development version not compiled
)

if exist deploy\robot_control_gui.exe (
    echo   [OK] Deployment version packaged
) else (
    echo   [NO] Deployment version not packaged
)
goto end

:check_env
echo.
echo ===============================================================
echo Environment Check
echo ===============================================================

echo [Check] Qt Installation...
call :find_qt
if "%QTDIR_FOUND%"=="1" (
    echo   [OK] Found Qt: %QTDIR%
) else (
    echo   [ERROR] Qt installation not found
    echo   Please install Qt development environment
    echo   Download: https://www.qt.io/download-qt-installer
    echo.
    echo   Expected Qt paths:
    echo     C:\Qt\5.15.2\mingw81_64
    echo     C:\Qt\5.15.2\msvc2019_64
    echo     C:\Qt\6.2.0\mingw_64
    echo     C:\Qt\6.2.0\msvc2019_64
    echo     C:\Qt\6.5.0\mingw_64
    echo     C:\Qt\6.5.0\msvc2019_64
    echo.
    echo   Your Qt installation path:
    set /p user_qt_path=Please enter your Qt path (or press Enter to skip): 
    if not "%user_qt_path%"=="" (
        if exist "%user_qt_path%\bin\qmake.exe" (
            echo   [OK] Found Qt at: %user_qt_path%
            set QTDIR=%user_qt_path%
            set QTDIR_FOUND=1
        ) else (
            echo   [ERROR] qmake.exe not found in %user_qt_path%\bin\
        )
    )
)

echo.
echo [Check] Build Tools...
where qmake >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] qmake available
) else (
    echo   [NO] qmake not available
)

where mingw32-make >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] MinGW make available
) else (
    echo   [NO] MinGW make not available
)

where nmake >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] MSVC nmake available
) else (
    echo   [NO] MSVC nmake not available
)

echo.
echo [Check] Git...
where git >nul 2>&1
if %errorlevel%==0 (
    echo   [OK] Git available
) else (
    echo   [NO] Git not available
)

echo.
echo [Check] System Information...
echo   Operating System: %OS%
echo   Processor Architecture: %PROCESSOR_ARCHITECTURE%
echo   User: %USERNAME%
echo   Current Directory: %CD%

goto end

:do_compile
call :find_qt
if "%QTDIR_FOUND%"=="0" (
    echo [ERROR] Qt installation not found
    echo Please install Qt development environment
    echo Download: https://www.qt.io/download-qt-installer
    exit /b 1
)

echo [INFO] Found Qt installation: %QTDIR%

REM Set environment variables
set PATH=%QTDIR%\bin;%PATH%
set QT_PLUGIN_PATH=%QTDIR%\plugins

REM Detect compiler type
if exist "%QTDIR%\bin\mingw32-make.exe" (
    set COMPILER=mingw
    set MAKE_CMD=mingw32-make
    echo [INFO] Using MinGW compiler
) else (
    set COMPILER=msvc
    set MAKE_CMD=nmake
    echo [INFO] Using MSVC compiler
)

REM Clean old files
echo [STEP] Cleaning old files...
if exist robot_control_gui.exe del robot_control_gui.exe
if exist Makefile del Makefile*
if exist *.o del *.o
if exist debug rmdir /s /q debug
if exist release rmdir /s /q release
for %%f in (moc_*.cpp moc_*.h ui_*.h qrc_*.cpp) do if exist %%f del %%f

REM Generate Makefile
echo [STEP] Generating Makefile...
qmake robot_control_gui.pro -spec win32-g++ "CONFIG+=release"
if errorlevel 1 (
    echo [ERROR] qmake failed
    exit /b 1
)

REM Compile project
echo [STEP] Compiling project...
%MAKE_CMD%
if errorlevel 1 (
    echo [ERROR] Compilation failed
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
    exit /b 1
)

exit /b 0

:do_package
echo [STEP] Creating deployment package...
if exist deploy rmdir /s /q deploy
mkdir deploy
copy robot_control_gui.exe deploy\

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

echo @echo off > start.bat
echo echo Starting Robot Control GUI... >> start.bat
echo robot_control_gui.exe >> start.bat
echo pause >> start.bat

cd ..

echo [SUCCESS] Packaging completed!
echo Deployment files location: %CD%\deploy\
echo Package contents:
dir deploy\ /b

exit /b 0

:find_qt
set QTDIR_FOUND=0
set QT_PATHS=C:\Qt\5.15.2\mingw81_64;C:\Qt\5.15.2\msvc2019_64;C:\Qt\6.2.0\mingw_64;C:\Qt\6.2.0\msvc2019_64;C:\Qt\6.5.0\mingw_64;C:\Qt\6.5.0\msvc2019_64;C:\Qt\6.6.0\mingw_64;C:\Qt\6.6.0\msvc2019_64;C:\Qt\6.7.0\mingw_64;C:\Qt\6.7.0\msvc2019_64

for %%p in (%QT_PATHS%) do (
    if exist "%%p\bin\qmake.exe" (
        set QTDIR=%%p
        set QTDIR_FOUND=1
        goto qt_search_done
    )
)

REM Also check common alternative locations
for /d %%d in (C:\Qt\*) do (
    for /d %%v in (%%d\*) do (
        if exist "%%v\bin\qmake.exe" (
            set QTDIR=%%v
            set QTDIR_FOUND=1
            goto qt_search_done
        )
    )
)

:qt_search_done
exit /b 0

:end
echo.
echo ---------------------------------------------------------------
set /p continue=Press any key to return to main menu, or 'q' to exit: 
if /i "%continue%"=="q" goto exit
goto start

:exit
echo.
echo Thank you for using Robot Control GUI Build Tool!
echo.
timeout /t 2 >nul