@echo off
:: Windows build & run script (MSVC)
:: Usage: run.bat [offset] [ctx] [pwd]

where cl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: MSVC compiler (cl.exe) not found in PATH.
    echo Run this script from a Visual Studio Developer Command Prompt
    echo or call "vcvarsall.bat x64" first.
    exit /b 1
)

cl /nologo /O2 /MT ^
   /Fe:parent_dir_tui.exe ^
   main.c fzy/tty_win32.c ^
   /I fzy

if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

parent_dir_tui.exe %*
