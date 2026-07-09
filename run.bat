@echo off
:: Windows build & run script (MinGW / MSYS2)
:: Requires: gcc, wget

if not exist fzy mkdir fzy

set VERSION=34b88869d022e861da4846c4463aea3ddfb3ff30

if not exist "config.h" (
    wget "https://raw.githubusercontent.com/jhawthorn/fzy/%VERSION%/src/config.def.h" -O config.h
)

gcc ^
    -static -Os ^
    -flto ^
    -ffunction-sections -fdata-sections ^
    -Wl,--strip-all,--gc-sections ^
    main.c fzy/tty_win32.c -Ifzy -o parent_dir_tui.exe

parent_dir_tui.exe %*
