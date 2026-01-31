@echo off
title MS Family Blocker - GUI
cd /d "%~dp0"

if not exist "%~dp0MS-Family-Blocker-GUI.ps1" (
    echo ERROR: MS-Family-Blocker-GUI.ps1 not found.
    pause
    exit /b 1
)

net session 1>nul 2>nul
if %errorLevel% neq 0 (
    (
        echo @echo off
        echo cd /d "%~dp0"
        echo powershell -ExecutionPolicy Bypass -File "%~dp0MS-Family-Blocker-GUI.ps1"
    ) > "%TEMP%\MSFamilyBlocker_GUI_launch.bat"
    powershell -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%TEMP%\MSFamilyBlocker_GUI_launch.bat' -Verb RunAs -WorkingDirectory '%~dp0'"
    timeout /t 2 /nobreak 1>nul 2>nul
    del "%TEMP%\MSFamilyBlocker_GUI_launch.bat" 1>nul 2>nul
    exit /b 1
)

del "%TEMP%\MSFamilyBlocker_GUI_launch.bat" 1>nul 2>nul
powershell -ExecutionPolicy Bypass -File "%~dp0MS-Family-Blocker-GUI.ps1"
