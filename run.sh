#!/bin/bash
# POSIX build & run script

gcc \
    -static -Os \
    -flto \
    -ffunction-sections -fdata-sections \
    -Wl,--strip-all,--gc-sections \
    main.c fzy/tty_posix.c -Ifzy -o parent_dir_tui

./parent_dir_tui "$@"
