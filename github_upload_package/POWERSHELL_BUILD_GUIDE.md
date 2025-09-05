# 🔧 PowerShell构建指南

## 问题解决

您遇到的问题是Windows PowerShell的中文编码问题。批处理文件中的中文字符在PowerShell中显示为乱码。

## 🚀 解决方案

我为您提供了3种解决方案：

### 方案1：使用PowerShell脚本（推荐）

#### 第一步：设置PowerShell执行策略
```powershell
# 以管理员身份运行PowerShell，然后执行：
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

或者直接运行：
```cmd
setup_powershell.bat
```

#### 第二步：运行PowerShell构建工具
```powershell
powershell -File quick_build_powershell.ps1
```

### 方案2：使用简化批处理文件
```cmd
build_simple.bat
```

### 方案3：在CMD中运行原始脚本
```cmd
# 不要在PowerShell中运行，改用CMD
cmd /c quick_build.bat
```

## 📋 PowerShell构建工具功能

运行 `quick_build_powershell.ps1` 后，您将看到：

```
╔══════════════════════════════════════════════════════════════╗
║                    🤖 Robot Control GUI                      ║
║                     Windows Build Tool v2.0                 ║
╚══════════════════════════════════════════════════════════════╝

Please select an option:

  [1] 🔨 Compile Project
  [2] 📦 Compile and Package  
  [3] 🧪 Test Run
  [4] 🧹 Clean Project
  [5] 📋 Project Information
  [6] 🔧 Environment Check
  [0] 🚪 Exit
```

## 🎯 推荐使用步骤

### 第一步：环境检查
```powershell
powershell -File quick_build_powershell.ps1
# 选择 [6] Environment Check
```

### 第二步：编译项目
```powershell
# 选择 [1] Compile Project
```

### 第三步：打包部署
```powershell
# 选择 [2] Compile and Package
```

### 第四步：测试运行
```powershell
# 选择 [3] Test Run
```

## 🔧 命令行参数支持

PowerShell脚本还支持命令行参数：

```powershell
# 直接编译
powershell -File quick_build_powershell.ps1 -Action compile

# 直接打包
powershell -File quick_build_powershell.ps1 -Action package

# 环境检查
powershell -File quick_build_powershell.ps1 -Action check

# 清理项目
powershell -File quick_build_powershell.ps1 -Action clean
```

## 🐛 常见问题解决

### 问题1：PowerShell执行策略限制
```
错误：无法加载文件，因为在此系统上禁止运行脚本
```

**解决方案：**
```powershell
# 以管理员身份运行PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### 问题2：中文乱码
```
显示为：'鈺愨晲鈺愨晲...'
```

**解决方案：**
- 使用 `build_simple.bat`（无中文字符）
- 或使用 `quick_build_powershell.ps1`（PowerShell脚本）
- 或在CMD中运行：`cmd /c quick_build.bat`

### 问题3：找不到Qt
```
[ERROR] Qt installation not found
```

**解决方案：**
1. 确保已安装Qt开发环境
2. 检查Qt安装路径是否在脚本的搜索路径中
3. 手动设置环境变量：
```cmd
set QTDIR=C:\Qt\5.15.2\mingw81_64
set PATH=%QTDIR%\bin;%PATH%
```

## 📁 文件说明

| 文件名 | 用途 | 推荐度 |
|--------|------|--------|
| `quick_build_powershell.ps1` | PowerShell构建工具 | ⭐⭐⭐⭐⭐ |
| `build_simple.bat` | 简化批处理文件 | ⭐⭐⭐⭐ |
| `setup_powershell.bat` | PowerShell环境设置 | ⭐⭐⭐ |
| `quick_build.bat` | 原始批处理文件 | ⭐⭐ |

## 🎉 成功标志

当您看到以下输出时，说明构建成功：

```
[SUCCESS] ✅ Compilation successful!
[SUCCESS] ✅ Packaging completed!
📁 Deployment files location: D:\thu\robotsim-main\robotsim-main\deploy\
```

## 💡 使用建议

1. **首次使用**：运行 `setup_powershell.bat` 设置环境
2. **日常构建**：使用 `quick_build_powershell.ps1`
3. **快速构建**：使用 `build_simple.bat`
4. **问题排查**：使用环境检查功能

## 📞 需要帮助？

如果仍有问题，请提供：
1. Windows版本
2. PowerShell版本（`$PSVersionTable.PSVersion`）
3. Qt安装路径
4. 完整的错误信息截图

这样我可以更好地帮助您解决问题！