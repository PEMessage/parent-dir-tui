#!/bin/bash

# Global cache variable (only for current bash instance)
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
        # Split path into components (bash version)
        IFS='/' read -ra components <<< "${path_temp#/}"
        # Add 1 for root component if path starts with /
        if [[ "$current_dir" == /* ]]; then
            components=("${components[@]}")
        fi

        local param="${1:--1}"
        count=$((${#components[@]} + param))
    fi

    # Run parent_dir_tui with cached directory
    local selected_dir="$(parent_dir_tui "$cached_dir" "$count")"

    # Handle the selection
    if [[ $? -eq 0 && -n "$selected_dir" && -d "$selected_dir" ]]; then
        # In bash, we need to actually change directory
        cd "$selected_dir"
    else
        true
    fi
}

parent_dir_tui_left() {
    READLINE_LINE=""
    parent_dir_tui_func '-1'
}

parent_dir_tui_right() {
    # clear the line
    READLINE_LINE=""
    parent_dir_tui_func '+1'
}

# For bash key bindings (requires bash's bind command)
# Note: These keycodes might be different in your terminal
bind_parent_dir_functions() {
    # 1. Bind the logic to a "secret" sequence (\e\e[D is unlikely to be pressed)
    bind -x '"\e\e[D": parent_dir_tui_left'
    bind -x '"\e\e[C": parent_dir_tui_right'

    # 2. Map the Actual Keys to: Secret Sequence + Redraw (\C-l)
    # This runs the function silently and then forces the prompt to refresh
    bind '"\e[1;3D": "\e\e[D\C-m"'
    bind '"\e[1;3C": "\e\e[C\C-m"'
}

bind_parent_dir_functions
