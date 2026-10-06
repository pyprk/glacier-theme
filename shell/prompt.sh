# Glacier prompt for bash. Sourced from ~/.bashrc.
#
#   ~/glacier-theme  main +2 ~1                         ✗ 1  ·  3.2s
#   ❯
#
# Line one: directory, git branch and state, then (right side) the last
# exit code if it failed and the duration if the command took > 2 s.

[[ $- == *i* ]] || return 0

# ---- palette (24-bit) --------------------------------------------------------
_gl_c() { printf '\[\e[38;2;%sm\]' "$1"; }
_GL_TEXT=$(_gl_c '216;225;238')
_GL_DIM=$(_gl_c '124;139;163')
_GL_ACCENT=$(_gl_c '86;164;245')
_GL_ICE=$(_gl_c '111;205;245')
_GL_GREEN=$(_gl_c '127;207;154')
_GL_RED=$(_gl_c '232;105;122')
_GL_AMBER=$(_gl_c '230;182;115')
_GL_VIOLET=$(_gl_c '155;140;240')
_GL_RESET='\[\e[0m\]'
_GL_BOLD='\[\e[1m\]'

# ---- command timing ----------------------------------------------------------
_gl_start=
_gl_timer_start() { [[ -n $_gl_start ]] || _gl_start=$EPOCHREALTIME; }
trap '_gl_timer_start' DEBUG

_gl_duration() {
    [[ -n $_gl_start ]] || return
    local ms=$(( (${EPOCHREALTIME/./} - ${_gl_start/./}) / 1000 ))
    _gl_start=
    (( ms >= 2000 )) || return
    if (( ms >= 60000 )); then
        printf '%dm %ds' $((ms / 60000)) $((ms % 60000 / 1000))
    else
        printf '%d.%ds' $((ms / 1000)) $((ms % 1000 / 100))
    fi
}

# ---- git -----------------------------------------------------------------------
_gl_git() {
    local out branch ahead=0 behind=0 staged=0 changed=0 untracked=0 line
    git rev-parse --is-inside-work-tree &>/dev/null || return
    out=$(git status --porcelain=v2 --branch 2>/dev/null) || return
    while IFS= read -r line; do
        case $line in
            '# branch.head '*) branch=${line#\# branch.head } ;;
            '# branch.ab '*) read -r _ _ ahead behind <<< "$line"; ahead=${ahead#+}; behind=${behind#-} ;;
            1\ *|2\ *)
                [[ ${line:2:1} != . ]] && ((staged++))
                [[ ${line:3:1} != . ]] && ((changed++)) ;;
            u\ *) ((changed++)) ;;
            \?\ *) ((untracked++)) ;;
        esac
    done <<< "$out"
    [[ $branch == '(detached)' ]] && branch=$(git rev-parse --short HEAD 2>/dev/null)

    local s="  ${_GL_VIOLET}${branch}"
    (( ahead ))     && s+="${_GL_DIM} ↑${ahead}"
    (( behind ))    && s+="${_GL_DIM} ↓${behind}"
    (( staged ))    && s+="${_GL_GREEN} +${staged}"
    (( changed ))   && s+="${_GL_AMBER} ~${changed}"
    (( untracked )) && s+="${_GL_DIM} ?${untracked}"
    printf '%s' "$s"
}

# ---- assemble ------------------------------------------------------------------
_gl_prompt() {
    local status=$?
    local left right="" where

    # host only when it matters: ssh sessions or root
    if [[ -n $SSH_CONNECTION || $EUID -eq 0 ]]; then
        where="${_GL_ICE}\u@\h${_GL_DIM} in "
    fi
    left="${where}${_GL_ACCENT}${_GL_BOLD}\w${_GL_RESET}$(_gl_git)"
    [[ -n $VIRTUAL_ENV ]] && left+="${_GL_DIM}  (${VIRTUAL_ENV##*/})"

    local dur
    dur=$(_gl_duration)
    (( status != 0 )) && right+="${_GL_RED}✗ ${status}"
    [[ -n $dur ]] && right+="${right:+${_GL_DIM}  ·  }${_GL_DIM}${dur}"

    local arrow=${_GL_ACCENT}
    (( status != 0 )) && arrow=${_GL_RED}

    PS1="\n${left}${right:+   ${right}}${_GL_RESET}\n${arrow}❯ ${_GL_RESET}"
    # window title
    PS1="\[\e]0;\w\a\]${PS1}"
}
PROMPT_COMMAND=_gl_prompt
PS2="${_GL_DIM}… ${_GL_RESET}"

# ---- banner ----------------------------------------------------------------------
if [[ -z $GLACIER_BANNER_SHOWN && $TERM != dumb && -z $CLAUDECODE ]] && command -v fastfetch >/dev/null; then
    export GLACIER_BANNER_SHOWN=1
    fastfetch
fi
