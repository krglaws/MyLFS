#!/bin/env bash
# shellcheck disable=SC2059

RESET=$'\e[0m'
RED=$'\e[91m'
GREEN=$'\e[92m'
YELLOW=$'\e[93m'

_get_timestamp() {
    date '+%F %H:%M:%S'
}

_seconds_to_hms() {
    local seconds=${1:?_seconds_to_hms(): seconds required}
    date -d@"$seconds" -u +%H:%M:%S
}

_build_log() {
    local type=${1:?_build_log_template(): type required}
    local message=${2:?_build_log(): message required}
    local color
    if [[ -t 1 && $type == INFO ]]; then
        color=$GREEN
    elif [[ -t 1 && $type == WARNING ]]; then
        color=$YELLOW
    elif [[ -t 1 && $type == ERROR ]]; then
        color=$RED
    fi
    printf "%s[%s]%s: %s%s" "$color" "$(_get_timestamp)" "$type" "$message" "$RESET"
}

log_info() {
    local message=${1:?log_info(): message required}
    local log
    log=$(_build_log INFO "$message")
    printf "%s\n" "$log"
}

log_warning() {
    local message=${1:?log_warning(): message required}
    local log
    log=$(_build_log WARNING "$message")
    printf "%s\n" "$log" >&2
}

log_error() {
    local message=${1:?log_error(): message required}
    local log
    log=$(_build_log ERROR "$message")
    printf "%s\n" "$log" >&2
}

log_info_start() {
    local message=${1:?log_info_start(): message required}
    local template
    template="$(_build_log INFO "$message...")"
    if (( VERBOSE )); then
        template="$template\n"
    fi
    printf "$template"
}

log_info_done() {
    local elapsed=${1:-}
    local message=DONE
    if [[ -n $elapsed ]]; then
        message="$message ($(_seconds_to_hms "$elapsed"))"
    fi
    if [[ -t 1 ]]; then
        message="${GREEN}${message}${RESET}"
    fi
    if (( VERBOSE )); then
        message="\n$message"
    fi
    printf "$message\n"
}

with_log() {
    local msg=${1:?with_log(): message required}
    shift

    local start=$SECONDS
    log_info_start "$msg"
    if (( VERBOSE )); then
        if ! "$@"; then
            return 1
        fi
    else
        if ! "$@" > /dev/null; then
            return 1
        fi
    fi
    log_info_done $(( SECONDS - start ))
    return 0
}

prompt_warning() {
    local msg=${1:?warn_confirm(): message required}
    local confirm, log
    log=$(_build_log WARNING "$msg")
    read -rp "$log -- continue? [y/n]: " confirm >&2
    [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]] && return 1
    return 0
}
