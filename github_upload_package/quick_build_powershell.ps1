# Robot Control GUI - PowerShell Build Tool
# 机器人控制上位机 - PowerShell构建工具

param(
    [string]$Action = ""
)

# 设置控制台编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Robot Control GUI - Build Tool"

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    🤖 Robot Control GUI                      ║" -ForegroundColor Cyan
    Write-Host "║                     Windows Build Tool v2.0                 ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Current Directory: $PWD" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Please select an option:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] 🔨 Compile Project" -ForegroundColor Green
    Write-Host "  [2] 📦 Compile and Package" -ForegroundColor Green
    Write-Host "  [3] 🧪 Test Run" -ForegroundColor Yellow
    Write-Host "  [4] 🧹 Clean Project" -ForegroundColor Red
    Write-Host "  [5] 📋 Project Information" -ForegroundColor Blue
    Write-Host "  [6] 🔧 Environment Check" -ForegroundColor Magenta
    Write-Host "  [0] 🚪 Exit" -ForegroundColor Gray
    Write-Host ""
    Write-Host "────────────────────────────────────────────────────────────────" -ForegroundColor Gray
}

function Test-QtInstallation {
    $qtPaths = @(
        "C:\Qt\5.15.2\mingw81_64",
        "C:\Qt\5.15.2\msvc2019_64",
        "C:\Qt\6.2.0\mingw_64",
        "C:\Qt\6.2.0\msvc2019_64",
        "C:\Qt\6.5.0\mingw_64",
        "C:\Qt\6.5.0\msvc2019_64"
    )
    
    foreach ($path in $qtPaths) {
        if (Test-Path "$path\bin\qmake.exe") {
            return $path
        }
    }
    return $null
}

function Invoke-Compile {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🔨 Compiling Project" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # Check Qt installation
    $qtDir = Test-QtInstallation
    if (-not $qtDir) {
        Write-Host "[ERROR] ❌ Qt installation not found" -ForegroundColor Red
        Write-Host "Please install Qt development environment" -ForegroundColor Yellow
        Write-Host "Download: https://www.qt.io/download-qt-installer" -ForegroundColor Blue
        return $false
    }
    
    Write-Host "[INFO] ✅ Found Qt installation: $qtDir" -ForegroundColor Green
    
    # Set environment variables
    $env:QTDIR = $qtDir
    $env:PATH = "$qtDir\bin;$env:PATH"
    
    # Detect compiler
    $compiler = ""
    $makeCmd = ""
    
    if (Test-Path "$qtDir\bin\mingw32-make.exe") {
        $compiler = "mingw"
        $makeCmd = "mingw32-make"
        Write-Host "[INFO] Using MinGW compiler" -ForegroundColor Green
    } elseif (Get-Command "nmake" -ErrorAction SilentlyContinue) {
        $compiler = "msvc"
        $makeCmd = "nmake"
        Write-Host "[INFO] Using MSVC compiler" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] ❌ No supported compiler found" -ForegroundColor Red
        return $false
    }
    
    # Clean old files
    Write-Host "[STEP] Cleaning old files..." -ForegroundColor Yellow
    $filesToClean = @("robot_control_gui.exe", "Makefile*", "*.o", "moc_*.cpp", "ui_*.h", "qrc_*.cpp")
    foreach ($pattern in $filesToClean) {
        Get-ChildItem -Path . -Name $pattern -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    
    if (Test-Path "debug") { Remove-Item -Recurse -Force "debug" -ErrorAction SilentlyContinue }
    if (Test-Path "release") { Remove-Item -Recurse -Force "release" -ErrorAction SilentlyContinue }
    
    # Generate Makefile
    Write-Host "[STEP] Generating Makefile..." -ForegroundColor Yellow
    $qmakeResult = & "$qtDir\bin\qmake.exe" "robot_control_gui.pro" "-spec" "win32-g++" "CONFIG+=release"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] ❌ qmake failed" -ForegroundColor Red
        return $false
    }
    
    # Compile project
    Write-Host "[STEP] Compiling project..." -ForegroundColor Yellow
    if ($compiler -eq "mingw") {
        & "$qtDir\bin\mingw32-make.exe"
    } else {
        & nmake
    }
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] ❌ Compilation failed" -ForegroundColor Red
        return $false
    }
    
    # Check for executable
    $exePath = ""
    if (Test-Path "robot_control_gui.exe") {
        $exePath = "robot_control_gui.exe"
    } elseif (Test-Path "release\robot_control_gui.exe") {
        Copy-Item "release\robot_control_gui.exe" "."
        $exePath = "robot_control_gui.exe"
    } elseif (Test-Path "debug\robot_control_gui.exe") {
        Copy-Item "debug\robot_control_gui.exe" "."
        $exePath = "robot_control_gui.exe"
    }
    
    if ($exePath) {
        Write-Host "[SUCCESS] ✅ Compilation successful!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "[ERROR] ❌ Executable not found" -ForegroundColor Red
        return $false
    }
}

function Invoke-Package {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "📦 Compile and Package" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    # First compile
    if (-not (Invoke-Compile)) {
        return $false
    }
    
    # Create deployment directory
    Write-Host "[STEP] Creating deployment package..." -ForegroundColor Yellow
    if (Test-Path "deploy") { Remove-Item -Recurse -Force "deploy" }
    New-Item -ItemType Directory -Name "deploy" | Out-Null
    Copy-Item "robot_control_gui.exe" "deploy\"
    
    # Use windeployqt
    Set-Location "deploy"
    $qtDir = Test-QtInstallation
    Write-Host "[INFO] Copying Qt dependencies..." -ForegroundColor Blue
    & "$qtDir\bin\windeployqt.exe" "--release" "--no-translations" "robot_control_gui.exe"
    
    # Check for missing DLLs
    $requiredDlls = @("Qt5Core.dll", "Qt5Gui.dll", "Qt5Widgets.dll", "Qt5Network.dll", "Qt5SerialPort.dll", "Qt5OpenGL.dll")
    foreach ($dll in $requiredDlls) {
        if (-not (Test-Path $dll)) {
            Write-Host "[WARNING] Missing $dll, copying..." -ForegroundColor Yellow
            if (Test-Path "$qtDir\bin\$dll") {
                Copy-Item "$qtDir\bin\$dll" "."
            }
        }
    }
    
    # Copy MinGW runtime if needed
    if ($qtDir -like "*mingw*") {
        $mingwDlls = @("libgcc_s_seh-1.dll", "libstdc++-6.dll", "libwinpthread-1.dll")
        foreach ($dll in $mingwDlls) {
            if (-not (Test-Path $dll) -and (Test-Path "$qtDir\bin\$dll")) {
                Copy-Item "$qtDir\bin\$dll" "."
            }
        }
    }
    
    # Create startup script
    @"
@echo off
echo Starting Robot Control GUI...
echo.
robot_control_gui.exe
if errorlevel 1 (
    echo Program failed to start, please check system environment
    pause
)
"@ | Out-File -FilePath "start.bat" -Encoding ASCII
    
    Set-Location ".."
    
    Write-Host ""
    Write-Host "[SUCCESS] ✅ Packaging completed!" -ForegroundColor Green
    Write-Host "📁 Deployment files location: $PWD\deploy\" -ForegroundColor Blue
    Write-Host "📋 Package contents:" -ForegroundColor Blue
    Get-ChildItem "deploy" | Where-Object { -not $_.PSIsContainer } | ForEach-Object { Write-Host "    $($_.Name)" -ForegroundColor Gray }
    
    return $true
}

function Invoke-TestRun {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🧪 Test Run" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    if (Test-Path "deploy\robot_control_gui.exe") {
        Write-Host "[INFO] Starting deployment version..." -ForegroundColor Blue
        Set-Location "deploy"
        Start-Process "robot_control_gui.exe"
        Set-Location ".."
        Write-Host "[INFO] Program started, please check if the interface displays correctly" -ForegroundColor Green
    } elseif (Test-Path "robot_control_gui.exe") {
        Write-Host "[INFO] Starting development version..." -ForegroundColor Blue
        Start-Process "robot_control_gui.exe"
        Write-Host "[INFO] Program started, please check if the interface displays correctly" -ForegroundColor Green
    } else {
        Write-Host "[ERROR] ❌ Executable not found, please compile the project first" -ForegroundColor Red
    }
}

function Invoke-Clean {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🧹 Clean Project" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    Write-Host "[INFO] Cleaning compilation files..." -ForegroundColor Yellow
    
    $filesToClean = @(
        "robot_control_gui.exe",
        "Makefile*",
        "*.o",
        "moc_*.cpp",
        "moc_*.h",
        "ui_*.h",
        "qrc_*.cpp"
    )
    
    foreach ($pattern in $filesToClean) {
        $files = Get-ChildItem -Path . -Name $pattern -ErrorAction SilentlyContinue
        foreach ($file in $files) {
            Remove-Item $file -Force -ErrorAction SilentlyContinue
            Write-Host "[CLEAN] $file" -ForegroundColor Gray
        }
    }
    
    $dirsToClean = @("debug", "release", "deploy")
    foreach ($dir in $dirsToClean) {
        if (Test-Path $dir) {
            Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
            Write-Host "[CLEAN] $dir\" -ForegroundColor Gray
        }
    }
    
    Write-Host "[SUCCESS] ✅ Cleaning completed" -ForegroundColor Green
}

function Show-ProjectInfo {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "📋 Project Information" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    Write-Host "Project Name: Robot Control GUI" -ForegroundColor White
    Write-Host "Version: v2.0" -ForegroundColor White
    Write-Host "Description: Dual-arm robot control software with 21-joint control and 3D visualization" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📁 Project Files:" -ForegroundColor Blue
    $projectFiles = @(
        "robot_control_gui.pro",
        "mainwindow.h",
        "mainwindow.cpp",
        "robotcontroller.h",
        "robotcontroller.cpp",
        "jointcontrolwidget.h",
        "jointcontrolwidget.cpp",
        "main.cpp"
    )
    
    foreach ($file in $projectFiles) {
        if (Test-Path $file) {
            Write-Host "  ✅ $file" -ForegroundColor Green
        } else {
            Write-Host "  ❌ $file" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "🎯 Features:" -ForegroundColor Blue
    Write-Host "  • 21 joint controls (Left arm 8 + Right arm 8 + Waist 2 + Chassis 2 + Lift 1)" -ForegroundColor White
    Write-Host "  • 3D robot visualization rendering window" -ForegroundColor White
    Write-Host "  • Simulation mode support" -ForegroundColor White
    Write-Host "  • Real-time motion status monitoring" -ForegroundColor White
    Write-Host "  • Position save and load" -ForegroundColor White
    Write-Host "  • Serial communication support" -ForegroundColor White
    
    Write-Host ""
    Write-Host "📊 Build Status:" -ForegroundColor Blue
    if (Test-Path "robot_control_gui.exe") {
        Write-Host "  ✅ Development version compiled" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Development version not compiled" -ForegroundColor Red
    }
    
    if (Test-Path "deploy\robot_control_gui.exe") {
        Write-Host "  ✅ Deployment version packaged" -ForegroundColor Green
        $deploySize = (Get-ChildItem "deploy" -Recurse | Measure-Object -Property Length -Sum).Sum
        Write-Host "  📁 Deployment directory size: $([math]::Round($deploySize/1MB, 2)) MB" -ForegroundColor Blue
    } else {
        Write-Host "  ❌ Deployment version not packaged" -ForegroundColor Red
    }
}

function Test-Environment {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "🔧 Environment Check" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    Write-Host "[Check] Qt Installation..." -ForegroundColor Yellow
    $qtDir = Test-QtInstallation
    if ($qtDir) {
        Write-Host "  ✅ Found Qt: $qtDir" -ForegroundColor Green
        $qmakeVersion = & "$qtDir\bin\qmake.exe" "-v" 2>$null
        Write-Host "  $qmakeVersion" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Qt installation not found" -ForegroundColor Red
        Write-Host "  💡 Please install Qt development environment" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "[Check] Build Tools..." -ForegroundColor Yellow
    
    if (Get-Command "qmake" -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ qmake available" -ForegroundColor Green
    } else {
        Write-Host "  ❌ qmake not available" -ForegroundColor Red
    }
    
    if (Get-Command "mingw32-make" -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ MinGW make available" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  MinGW make not available" -ForegroundColor Yellow
    }
    
    if (Get-Command "nmake" -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ MSVC nmake available" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  MSVC nmake not available" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "[Check] Git..." -ForegroundColor Yellow
    if (Get-Command "git" -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ Git available" -ForegroundColor Green
        $gitVersion = git --version
        Write-Host "  $gitVersion" -ForegroundColor Gray
    } else {
        Write-Host "  ❌ Git not available" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "[Check] System Information..." -ForegroundColor Yellow
    Write-Host "  💻 Operating System: $($env:OS)" -ForegroundColor White
    Write-Host "  🏗️  Processor Architecture: $($env:PROCESSOR_ARCHITECTURE)" -ForegroundColor White
    Write-Host "  👤 User: $($env:USERNAME)" -ForegroundColor White
    Write-Host "  📁 Current Directory: $PWD" -ForegroundColor White
    Write-Host "  🐚 PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
}

# Main execution
if ($Action) {
    switch ($Action) {
        "compile" { Invoke-Compile }
        "package" { Invoke-Package }
        "test" { Invoke-TestRun }
        "clean" { Invoke-Clean }
        "info" { Show-ProjectInfo }
        "check" { Test-Environment }
        default { Show-Menu }
    }
    return
}

# Interactive menu
do {
    Show-Menu
    $choice = Read-Host "Please enter option (0-6)"
    
    switch ($choice) {
        "1" { Invoke-Compile; Read-Host "Press Enter to continue" }
        "2" { Invoke-Package; Read-Host "Press Enter to continue" }
        "3" { Invoke-TestRun; Read-Host "Press Enter to continue" }
        "4" { Invoke-Clean; Read-Host "Press Enter to continue" }
        "5" { Show-ProjectInfo; Read-Host "Press Enter to continue" }
        "6" { Test-Environment; Read-Host "Press Enter to continue" }
        "0" { 
            Write-Host ""
            Write-Host "👋 Thank you for using Robot Control GUI Build Tool!" -ForegroundColor Green
            Write-Host ""
            Start-Sleep -Seconds 1
            break
        }
        default { 
            Write-Host "[ERROR] Invalid option, please try again" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)