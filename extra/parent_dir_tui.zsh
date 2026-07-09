
# Global cache variable (only for current zsh instance)
PERV_DIR_FOR_TUI=""

parent_dir_tui_func() {
    local current_dir="$(pwd)"
    local cached_dir="$PERV_DIR_FOR_TUI"

    # Check if we need to update the cache
    local update_cache=false
    local count=-2

    if [[ -z "$cached_dir" ]]; then
        update_cache=true
        # Condition 2: No common prefix with cache (directories are unrelated)
    elif [[ ! "$current_dir" == "$cached_dir"* ]] && \
        [[ ! "$cached_dir" == "$current_dir"* ]]; then
        update_cache=true
        # Condition 3: Has common prefix but current_dir is deeper (longer path)
    elif [[ "$current_dir" == "$cached_dir"* ]] && \
        [[ ${#current_dir} -gt ${#cached_dir} ]]; then
        update_cache=true
    fi

    # Update cache if needed
    if [[ "$update_cache" == true ]]; then
        PERV_DIR_FOR_TUI="$current_dir"
        cached_dir="$current_dir"
    else
        local path_temp="$current_dir"
        local components=(${(s:/:)path_temp})

        count=$((${#components[@]} + $1))
    fi

    # Run parent_dir_tui with cached directory
    # echo parent_dir_tui "$cached_dir" "$count"
    local selected_dir="$(parent_dir_tui "$cached_dir" "$count")"

    # Handle the selection
    if [[ $? -eq 0 && -n "$selected_dir" && -d "$selected_dir" ]]; then
        BUFFER="cd \"${selected_dir}\""
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
