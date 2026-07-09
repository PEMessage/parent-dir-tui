# AGENTS.md

## Build & Run

Single-file C project, no Makefile. Build and execute via:

```bash
./run.sh [path]
```

This fetches vendored fzy sources (pinned commit `34b88869…`) into `fzy/`, compiles with gcc, and runs the binary. The compile command (for reference):

```bash
gcc -static -Os -flto -ffunction-sections -fdata-sections -Wl,--strip-all,--gc-sections \
    main.c fzy/tty.c -Ifzy -o fzy_parent_dir
```

- Binary output is `fzy_parent_dir`.
- No tests, no CI, no lint config.

## Binary Name Mismatch

The shell integration wrappers in `extra/` invoke `parent_dir_tui`, **not** `fzy_parent_dir`. If using the wrappers, symlink or rename the binary.

## Architecture

- **`main.c`** — entire application (TUI loop, key handling, rendering, path splitting, dynamic arrays).
- **`fzy/tty.c` / `fzy/tty.h`** — vendored from fzy; terminal I/O only.
- **`config.h`** — scoring constants and TTY defaults from fzy.
- **`extra/parent_dir_tui.{bash,zsh}`** — shell integration with caching logic.

No external libraries beyond libc. Binary is statically linked.

## Key Quirks

- **`tty_hide_cursor` / `tty_show_cursor`** are defined locally at the top of `main.c`, not in `tty.h`. The original fzy `tty.c` has these as static; they are re-declared here.
- **Dynamic arrays** use `nob_da_*` macros defined inline in `main.c` with custom allocator hooks (`NOB_REALLOC`, `NOB_FREE`, `NOB_ASSERT`).
- **Key buffer** is a fixed `keys[8]` byte array — escape sequences longer than 7 bytes will fail.
- **`KEYTIMEOUT`** is 25ms (in `config.h`). If no bytes arrive within 25ms after a partial escape sequence, the partial match is discarded.
- **`POS_MOD`** macro (line 248) handles negative modulo for index wrapping.
- **Comment `// q-gcc: fzy/tty.c -Ifzy --`** on line 1 of `main.c` is an editor quick-compile directive. Leave it alone; it is not a comment to be cleaned up.
