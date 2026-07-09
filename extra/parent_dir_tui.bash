#!/bin/bash

PERV_DIR_FOR_TUI=""

parent_dir_tui_func() {
    local out
    out="$(parent_dir_tui "$1" "$PERV_DIR_FOR_TUI" "$PWD")"
    (( $? == 0 )) || return

    local new_dir="${out%$'\t'*}"
    PERV_DIR_FOR_TUI="${out#*$'\t'}"

    if [[ -n "$new_dir" && -d "$new_dir" ]]; then
        cd "$new_dir"
    fi
}

parent_dir_tui_left() {
    READLINE_LINE=""
    parent_dir_tui_func '-1'
}

parent_dir_tui_right() {
    READLINE_LINE=""
    parent_dir_tui_func '+1'
}

bind_parent_dir_functions() {
    bind -x '"\e\e[D": parent_dir_tui_left'
    bind -x '"\e\e[C": parent_dir_tui_right'
    bind '"\e[1;3D": "\e\e[D\C-m"'
    bind '"\e[1;3C": "\e\e[C\C-m"'
}

bind_parent_dir_functions
