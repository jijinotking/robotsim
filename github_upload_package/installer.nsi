; 机器人控制上位机 NSIS 安装脚本
; 版本: 2.0
; 作者: Robot Control Team

!define APPNAME "机器人控制上位机"
!define COMPANYNAME "Robot Control Solutions"
!define DESCRIPTION "轮臂机器人控制软件 - 支持21个关节控制和3D可视化"
!define VERSIONMAJOR 2
!define VERSIONMINOR 0
!define VERSIONBUILD 0
!define HELPURL "https://github.com/jijinotking/robotsim"
!define UPDATEURL "https://github.com/jijinotking/robotsim/releases"
!define ABOUTURL "https://github.com/jijinotking/robotsim"

; 安装程序属性
RequestExecutionLevel admin
InstallDir "$PROGRAMFILES64\${APPNAME}"
LicenseData "LICENSE"
Name "${APPNAME}"
Icon "robot_icon.ico"
outFile "RobotControlSetup_v${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}.exe"

; 版本信息
VIProductVersion "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}.0"
VIAddVersionKey "ProductName" "${APPNAME}"
VIAddVersionKey "CompanyName" "${COMPANYNAME}"
VIAddVersionKey "LegalCopyright" "© 2024 ${COMPANYNAME}"
VIAddVersionKey "FileDescription" "${DESCRIPTION}"
VIAddVersionKey "FileVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}.0"
VIAddVersionKey "ProductVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}.0"

; 现代UI
!include "MUI2.nsh"

; UI设置
!define MUI_ABORTWARNING
!define MUI_ICON "robot_icon.ico"
!define MUI_UNICON "robot_icon.ico"

; 安装页面
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; 卸载页面
!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; 语言
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"

; 安装类型
InstType "完整安装"
InstType "最小安装"

; 主程序组件
Section "!${APPNAME} (必需)" SecMain
    SectionIn RO 1 2
    
    SetOutPath $INSTDIR
    
    ; 检查deploy目录是否存在
    IfFileExists "deploy\robot_control_gui.exe" 0 +3
        File /r "deploy\*.*"
        Goto InstallComplete
    
    ; 如果deploy目录不存在，尝试当前目录
    IfFileExists "robot_control_gui.exe" 0 InstallError
        File "robot_control_gui.exe"
        
        ; 尝试复制Qt DLL
        IfFileExists "Qt5Core.dll" 0 +2
            File "Qt5*.dll"
        
        Goto InstallComplete
    
    InstallError:
        MessageBox MB_OK|MB_ICONSTOP "错误：未找到程序文件。请确保已编译项目并创建了deploy目录。"
        Abort
    
    InstallComplete:
    
    ; 写入卸载程序
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    ; 注册表项
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayName" "${APPNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "QuietUninstallString" "$\"$INSTDIR\uninstall.exe$\" /S"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "InstallLocation" "$\"$INSTDIR$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayIcon" "$\"$INSTDIR\robot_control_gui.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "Publisher" "${COMPANYNAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "HelpLink" "${HELPURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLUpdateInfo" "${UPDATEURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "URLInfoAbout" "${ABOUTURL}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "DisplayVersion" "${VERSIONMAJOR}.${VERSIONMINOR}.${VERSIONBUILD}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMajor" ${VERSIONMAJOR}
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "VersionMinor" ${VERSIONMINOR}
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "NoRepair" 1
    
    ; 计算安装大小
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "EstimatedSize" "$0"
SectionEnd

; 开始菜单快捷方式
Section "开始菜单快捷方式" SecStartMenu
    SectionIn 1
    
    CreateDirectory "$SMPROGRAMS\${APPNAME}"
    CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\robot_control_gui.exe" "" "$INSTDIR\robot_control_gui.exe" 0
    CreateShortCut "$SMPROGRAMS\${APPNAME}\卸载 ${APPNAME}.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
SectionEnd

; 桌面快捷方式
Section "桌面快捷方式" SecDesktop
    SectionIn 1
    
    CreateShortCut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\robot_control_gui.exe" "" "$INSTDIR\robot_control_gui.exe" 0
SectionEnd

; 文档和示例
Section "文档和示例" SecDocs
    SectionIn 1
    
    SetOutPath "$INSTDIR\docs"
    
    ; 复制文档文件（如果存在）
    IfFileExists "README.md" 0 +2
        File "README.md"
    
    IfFileExists "USAGE_GUIDE.md" 0 +2
        File "USAGE_GUIDE.md"
    
    IfFileExists "NEW_FEATURES_GUIDE.md" 0 +2
        File "NEW_FEATURES_GUIDE.md"
    
    IfFileExists "UI_LAYOUT_PREVIEW.txt" 0 +2
        File "UI_LAYOUT_PREVIEW.txt"
SectionEnd

; 组件描述
LangString DESC_SecMain ${LANG_SIMPCHINESE} "机器人控制上位机主程序和必需的运行库"
LangString DESC_SecStartMenu ${LANG_SIMPCHINESE} "在开始菜单创建程序快捷方式"
LangString DESC_SecDesktop ${LANG_SIMPCHINESE} "在桌面创建程序快捷方式"
LangString DESC_SecDocs ${LANG_SIMPCHINESE} "安装用户手册和使用指南"

LangString DESC_SecMain ${LANG_ENGLISH} "Robot Control GUI main program and required runtime libraries"
LangString DESC_SecStartMenu ${LANG_ENGLISH} "Create shortcuts in Start Menu"
LangString DESC_SecDesktop ${LANG_ENGLISH} "Create shortcut on Desktop"
LangString DESC_SecDocs ${LANG_ENGLISH} "Install user manual and usage guides"

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} $(DESC_SecMain)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} $(DESC_SecStartMenu)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} $(DESC_SecDesktop)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDocs} $(DESC_SecDocs)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; 安装前检查
Function .onInit
    ; 检查是否已安装
    ReadRegStr $R0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}" "UninstallString"
    StrCmp $R0 "" done
    
    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
        "${APPNAME} 已经安装。$\n$\n点击 '确定' 卸载之前的版本，或点击 '取消' 取消安装。" \
        IDOK uninst
    Abort
    
    uninst:
        ClearErrors
        ExecWait '$R0 _?=$INSTDIR'
        
        IfErrors no_remove_uninstaller done
        IfFileExists "$INSTDIR\uninstall.exe" 0 no_remove_uninstaller
            Delete $R0
            RMDir $INSTDIR
        
        no_remove_uninstaller:
    
    done:
FunctionEnd

; 卸载程序
Section "Uninstall"
    ; 删除程序文件
    Delete "$INSTDIR\robot_control_gui.exe"
    Delete "$INSTDIR\*.dll"
    Delete "$INSTDIR\uninstall.exe"
    
    ; 删除目录
    RMDir /r "$INSTDIR\platforms"
    RMDir /r "$INSTDIR\imageformats"
    RMDir /r "$INSTDIR\styles"
    RMDir /r "$INSTDIR\docs"
    RMDir "$INSTDIR"
    
    ; 删除快捷方式
    Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
    Delete "$SMPROGRAMS\${APPNAME}\卸载 ${APPNAME}.lnk"
    RMDir "$SMPROGRAMS\${APPNAME}"
    Delete "$DESKTOP\${APPNAME}.lnk"
    
    ; 删除注册表项
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPNAME}"
SectionEnd

; 包含GetSize函数
!include "FileFunc.nsh"