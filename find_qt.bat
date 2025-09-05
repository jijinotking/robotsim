@echo off
title Qt Installation Finder

echo ===============================================================
echo                    Qt Installation Finder                     
echo ===============================================================
echo.

echo Searching for Qt installations...
echo.

set FOUND_COUNT=0

REM Search in common Qt installation paths
echo [Search] Common Qt installation paths:
for %%p in (C:\Qt\5.15.2\mingw81_64 C:\Qt\5.15.2\msvc2019_64 C:\Qt\6.2.0\mingw_64 C:\Qt\6.2.0\msvc2019_64 C:\Qt\6.5.0\mingw_64 C:\Qt\6.5.0\msvc2019_64 C:\Qt\6.6.0\mingw_64 C:\Qt\6.6.0\msvc2019_64 C:\Qt\6.7.0\mingw_64 C:\Qt\6.7.0\msvc2019_64) do (
    if exist "%%p\bin\qmake.exe" (
        echo   [FOUND] %%p
        set /a FOUND_COUNT+=1
        set QTDIR=%%p
    )
)

echo.
echo [Search] All Qt directories in C:\Qt\:
if exist C:\Qt\ (
    for /d %%d in (C:\Qt\*) do (
        for /d %%v in (%%d\*) do (
            if exist "%%v\bin\qmake.exe" (
                echo   [FOUND] %%v
                set /a FOUND_COUNT+=1
                set QTDIR=%%v
            )
        )
    )
) else (
    echo   [INFO] C:\Qt\ directory does not exist
)

echo.
echo [Search] Qt in Program Files:
for /d %%d in ("C:\Program Files\Qt\*") do (
    for /d %%v in ("%%d\*") do (
        if exist "%%v\bin\qmake.exe" (
            echo   [FOUND] %%v
            set /a FOUND_COUNT+=1
            set QTDIR=%%v
        )
    )
)

for /d %%d in ("C:\Program Files (x86)\Qt\*") do (
    for /d %%v in ("%%d\*") do (
        if exist "%%v\bin\qmake.exe" (
            echo   [FOUND] %%v
            set /a FOUND_COUNT+=1
            set QTDIR=%%v
        )
    )
)

echo.
echo [Search] Qt in PATH environment:
where qmake >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=*" %%i in ('where qmake') do (
        echo   [FOUND] qmake at: %%i
        set /a FOUND_COUNT+=1
    )
)

echo.
echo ===============================================================
echo Search Results
echo ===============================================================

if %FOUND_COUNT%==0 (
    echo [ERROR] No Qt installation found!
    echo.
    echo Please check:
    echo   1. Qt is properly installed
    echo   2. Installation path contains \bin\qmake.exe
    echo   3. Try installing Qt from: https://www.qt.io/download-qt-installer
    echo.
    echo Common installation paths should be:
    echo   C:\Qt\[version]\[compiler]\bin\qmake.exe
    echo   Example: C:\Qt\5.15.2\mingw81_64\bin\qmake.exe
) else (
    echo [SUCCESS] Found %FOUND_COUNT% Qt installation(s)
    echo.
    if defined QTDIR (
        echo Recommended Qt path: %QTDIR%
        echo.
        echo To use this Qt installation, run:
        echo   set QTDIR=%QTDIR%
        echo   set PATH=%QTDIR%\bin;%%PATH%%
        echo.
        echo Or use the build tool with this path.
    )
)

echo.
echo ===============================================================
echo Manual Qt Path Entry
echo ===============================================================
echo.
echo If you know your Qt installation path, please enter it below:
set /p USER_QT_PATH=Enter Qt path (e.g., C:\Qt\5.15.2\mingw81_64): 

if not "%USER_QT_PATH%"=="" (
    if exist "%USER_QT_PATH%\bin\qmake.exe" (
        echo [SUCCESS] Valid Qt installation found at: %USER_QT_PATH%
        echo.
        echo To use this installation:
        echo   set QTDIR=%USER_QT_PATH%
        echo   set PATH=%USER_QT_PATH%\bin;%%PATH%%
        echo.
        
        REM Create a batch file to set environment
        echo @echo off > set_qt_env.bat
        echo echo Setting Qt environment... >> set_qt_env.bat
        echo set QTDIR=%USER_QT_PATH% >> set_qt_env.bat
        echo set PATH=%USER_QT_PATH%\bin;%%PATH%% >> set_qt_env.bat
        echo echo Qt environment set successfully! >> set_qt_env.bat
        echo echo QTDIR=%%QTDIR%% >> set_qt_env.bat
        
        echo [INFO] Created set_qt_env.bat to set environment variables
        echo Run 'set_qt_env.bat' before building the project
        
    ) else (
        echo [ERROR] qmake.exe not found in %USER_QT_PATH%\bin\
        echo Please check the path and try again
    )
)

echo.
pause