@echo off
title Setup PowerShell for Robot Control GUI

echo ========================================
echo Setup PowerShell for Robot Control GUI
echo ========================================
echo.

echo This script will configure PowerShell to run the build tool.
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] Running as administrator - Good!
) else (
    echo [WARNING] Not running as administrator
    echo Some operations may require administrator privileges
    echo.
)

echo [STEP] Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
if errorlevel 1 (
    echo [WARNING] Failed to set execution policy automatically
    echo Please run this command manually in PowerShell as administrator:
    echo Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    echo.
) else (
    echo [SUCCESS] PowerShell execution policy set successfully
    echo.
)

echo [INFO] You can now run the PowerShell build tool with:
echo powershell -File quick_build_powershell.ps1
echo.
echo Or use the simple batch file:
echo build_simple.bat
echo.

pause