
PERV_DIR_FOR_TUI=""

parent_dir_tui_func() {
    local out
    out="$(parent_dir_tui "$1" "$PERV_DIR_FOR_TUI" "$PWD")"
    (( $? == 0 )) || return

    local new_dir="${out%$'\t'*}"
    PERV_DIR_FOR_TUI="${out#*$'\t'}"

    if [[ -n "$new_dir" && -d "$new_dir" ]]; then
        BUFFER="cd \"${new_dir}\""
        zle accept-line
    else
        zle reset-prompt
    fi
}

parent_dir_tui_left() {
    parent_dir_tui_func -1
}

parent_dir_tui_right() {
    parent_dir_tui_func +1
}

zle -N parent_dir_tui_left
bindkey '^[[1;3D' parent_dir_tui_left

zle -N parent_dir_tui_right
bindkey '^[[1;3C' parent_dir_tui_right
