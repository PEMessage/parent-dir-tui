#include <windows.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>

#include "tty.h"

struct tty_t {
	HANDLE hin;
	HANDLE hout;
	FILE  *fout;
	DWORD  original_console_mode_in;
	DWORD  original_console_mode_out;
	int    fgcolor;
	size_t maxwidth;
	size_t maxheight;
};

tty_t *tty_create(void) {
	tty_t *tty = malloc(sizeof(tty_t));
	if (!tty) exit(EXIT_FAILURE);
	memset(tty, 0, sizeof(*tty));
	return tty;
}

void tty_destroy(tty_t *tty) {
	SetConsoleMode(tty->hin, tty->original_console_mode_in);
	SetConsoleMode(tty->hout, tty->original_console_mode_out);
	if (tty->fout)
		fclose(tty->fout);
	free(tty);
}

void tty_init(tty_t *tty) {
	tty->hin = GetStdHandle(STD_INPUT_HANDLE);
	tty->hout = GetStdHandle(STD_OUTPUT_HANDLE);

	if (tty->hin == INVALID_HANDLE_VALUE || tty->hout == INVALID_HANDLE_VALUE)
		exit(EXIT_FAILURE);

	if (!GetConsoleMode(tty->hin, &tty->original_console_mode_in))
		exit(EXIT_FAILURE);
	if (!GetConsoleMode(tty->hout, &tty->original_console_mode_out))
		exit(EXIT_FAILURE);

	DWORD mode_in = tty->original_console_mode_in;
	mode_in &= ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT);
	mode_in |= ENABLE_VIRTUAL_TERMINAL_INPUT | ENABLE_WINDOW_INPUT;
	SetConsoleMode(tty->hin, mode_in);

	DWORD mode_out = tty->original_console_mode_out;
	mode_out |= ENABLE_VIRTUAL_TERMINAL_PROCESSING | ENABLE_PROCESSED_OUTPUT;
	mode_out &= ~ENABLE_WRAP_AT_EOL_OUTPUT;
	SetConsoleMode(tty->hout, mode_out);

	HANDLE hout_copy;
	if (!DuplicateHandle(GetCurrentProcess(), tty->hout,
	                     GetCurrentProcess(), &hout_copy,
	                     0, FALSE, DUPLICATE_SAME_ACCESS))
		exit(EXIT_FAILURE);
	int out_fd = _open_osfhandle((intptr_t)hout_copy, 0);
	if (out_fd == -1) exit(EXIT_FAILURE);
	tty->fout = _fdopen(out_fd, "w");
	if (!tty->fout) exit(EXIT_FAILURE);
	setvbuf(tty->fout, NULL, _IOFBF, 16384);

	tty_getwinsz(tty);
	tty_setnormal(tty);
}

void tty_getwinsz(tty_t *tty) {
	CONSOLE_SCREEN_BUFFER_INFO csbi;
	if (GetConsoleScreenBufferInfo(tty->hout, &csbi)) {
		tty->maxwidth = csbi.srWindow.Right - csbi.srWindow.Left + 1;
		tty->maxheight = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
	} else {
		tty->maxwidth = 80;
		tty->maxheight = 25;
	}
}

char tty_getchar(tty_t *tty) {
	char ch;
	DWORD nread;
	if (!ReadFile(tty->hin, &ch, 1, &nread, NULL) || nread != 1)
		exit(EXIT_FAILURE);
	return ch;
}

int tty_input_ready(tty_t *tty, long int timeout, int return_on_signal) {
	(void)return_on_signal;

	DWORD ms = (timeout < 0) ? INFINITE : (DWORD)timeout;

	for (;;) {
		DWORD result = WaitForSingleObject(tty->hin, ms);
		if (result != WAIT_OBJECT_0)
			return 0;

		DWORD n;
		INPUT_RECORD rec;
		if (PeekConsoleInputA(tty->hin, &rec, 1, &n) && n > 0) {
			if (rec.EventType == KEY_EVENT && rec.Event.KeyEvent.bKeyDown)
				return 1;
			if (rec.EventType == WINDOW_BUFFER_SIZE_EVENT) {
				ReadConsoleInputA(tty->hin, &rec, 1, &n);
				tty_getwinsz(tty);
				return 0;
			}
			ReadConsoleInputA(tty->hin, &rec, 1, &n);
			if (ms != INFINITE) ms = 0;
			continue;
		}
		return 0;
	}
}

void tty_hide_cursor(tty_t *tty) {
	tty_printf(tty, "\x1b[?25l");
}

void tty_show_cursor(tty_t *tty) {
	tty_printf(tty, "\x1b[?25h");
}

static void tty_sgr(tty_t *tty, int code) {
	tty_printf(tty, "\x1b[%im", code);
}

void tty_setfg(tty_t *tty, int fg) {
	if (tty->fgcolor != fg) {
		tty_sgr(tty, 30 + fg);
		tty->fgcolor = fg;
	}
}

void tty_setinvert(tty_t *tty) {
	tty_sgr(tty, 7);
}

void tty_setunderline(tty_t *tty) {
	tty_sgr(tty, 4);
}

void tty_setnormal(tty_t *tty) {
	tty_sgr(tty, 0);
	tty->fgcolor = 9;
}

void tty_setnowrap(tty_t *tty) {
	tty_printf(tty, "\x1b[?7l");
}

void tty_setwrap(tty_t *tty) {
	tty_printf(tty, "\x1b[?7h");
}

void tty_newline(tty_t *tty) {
	tty_printf(tty, "\x1b[K\n");
}

void tty_clearline(tty_t *tty) {
	tty_printf(tty, "\x1b[K");
}

void tty_setcol(tty_t *tty, int col) {
	tty_printf(tty, "\x1b[%iG", col + 1);
}

void tty_moveup(tty_t *tty, int i) {
	tty_printf(tty, "\x1b[%iA", i);
}

void tty_printf(tty_t *tty, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	vfprintf(tty->fout, fmt, args);
	va_end(args);
}

void tty_putc(tty_t *tty, char c) {
	fputc(c, tty->fout);
}

void tty_flush(tty_t *tty) {
	fflush(tty->fout);
}

size_t tty_getwidth(tty_t *tty) {
	return tty->maxwidth;
}

size_t tty_getheight(tty_t *tty) {
	return tty->maxheight;
}
