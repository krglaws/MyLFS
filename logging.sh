#!/usr/bin/env bash

RESET=$'\e[0m'
RED=$'\e[91m'
GREEN=$'\e[92m'
YELLOW=$'\e[93m'

LOG_DEPTH=0
LOG_LINE_OPEN=0
VERBOSITY=${VERBOSITY:-1}

_get_timestamp() {
    date '+%F %H:%M:%S'
}

_ns_to_hms() {
    local ns=${1:?nanoseconds required}

    local total_secs=$(( ns / 1000000000 ))
    local ms=$(( (ns / 1000000) % 1000 ))

    local h=$(( total_secs / 3600 ))
    local m=$(( (total_secs % 3600) / 60 ))
    local s=$(( total_secs % 60 ))

    if (( h > 0 )); then
        printf '%dh %dm %d.%03ds' "$h" "$m" "$s" "$ms"
    elif (( m > 0 )); then
        printf '%dm %d.%03ds' "$m" "$s" "$ms"
    else
        printf '%d.%03ds' "$s" "$ms"
    fi
}

_build_log() {
    local type=${1:?}
    local msg=${2:?}
    local color=

    case $type in
        INFO)    color=$GREEN ;;
        WARNING) color=$YELLOW ;;
        ERROR)   color=$RED ;;
    esac

    printf '%b[%s] %s: %s%b' \
        "$color" "$(_get_timestamp)" "$type" "$msg" "$RESET"
}

_ensure_newline() {
    local always_print=$1
    if (( LOG_LINE_OPEN && \
        ( always_print || ( VERBOSITY > LOG_DEPTH )))); then
        printf '\n'
        LOG_LINE_OPEN=0
    fi
}

log_info() {
    _ensure_newline 0
    printf '%s\n' "$(_build_log INFO "$1")"
}

log_warning() {
    _ensure_newline 1 >&2
    printf '%s\n' "$(_build_log WARNING "$1")" >&2
}

log_error() {
    _ensure_newline 1 >&2
    printf '%s\n' "$(_build_log ERROR "$1")" >&2
}

_finish_with_log() {
    local type=${1:?_finish_with_log(): type required}
    local msg=${2:?_finish_with_log(): message required}
    local elapsed=${3:?_finish_with_log(): elapsed required}
    local done="done"
    local color=$GREEN
    case $type in
        ERROR)
        done="failed"
        color=$RED
        ;;
        WARNING)
        color=$YELLOW
        ;;
    esac

    done+=" ($(_ns_to_hms "$elapsed"))"

    if (( LOG_LINE_OPEN )); then
        # uninterrupted inline progress
        printf '%s\n' " ${color}${done}${RESET}"
    else
        # interrupted or verbose → own the line
        printf '%s\n' "$(_build_log "$type" "$msg: $done")"
    fi
}

with_log() {
    local msg=$1
    shift

    LOG_DEPTH=$(( LOG_DEPTH + 1 ))

    if (( VERBOSITY < LOG_DEPTH )); then
        "$@" >/dev/null || return 1
        LOG_DEPTH=$(( LOG_DEPTH - 1 ))
        return 0
    fi

    if (( LOG_LINE_OPEN )); then
        printf '\n'
        LOG_LINE_OPEN=0
    fi

    local prev_open=$LOG_LINE_OPEN
    LOG_LINE_OPEN=1

    printf '%s' "$(_build_log INFO "$msg...")"

    get_ts() { date +%s%N; }

    local start
    local end
    start=$(get_ts)
    if (( VERBOSITY > LOG_DEPTH )); then
        if ! "$@"; then
            end=$(get_ts)
            _finish_with_log ERROR "$msg" "$(( end - start ))"
            LOG_DEPTH=$(( LOG_DEPTH - 1 ))
            LOG_LINE_OPEN=$(( prev_open && LOG_LINE_OPEN ))
            return 1
        fi
    else
        if ! "$@" >/dev/null; then
            end=$(get_ts)
            _finish_with_log ERROR "$msg" "$(( end - start ))"
            LOG_DEPTH=$(( LOG_DEPTH - 1 ))
            LOG_LINE_OPEN=$(( prev_open && LOG_LINE_OPEN ))
            return 1
        fi
    fi

    end=$(get_ts)
    _finish_with_log INFO "$msg" $(( end - start ))

    LOG_LINE_OPEN=$(( prev_open && LOG_LINE_OPEN ))
    LOG_DEPTH=$(( LOG_DEPTH - 1 ))
}

prompt_warning() {
    _ensure_newline 1 >&2
    read -rp "$(_build_log WARNING "$1") -- continue? [y/N]: " confirm >&2
    [[ $confirm =~ ^([yY]|[yY][eE][sS])$ ]]
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    VERBOSITY=3
    do_logs2(){
        log_error "this should only show up with VERBOSITY>3"
    }
    do_logs() {
        with_log "doing some nested stuff" do_logs2
    }
    with_log "start logging test" do_logs
fi
