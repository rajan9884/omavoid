# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r $VOID_PATH/default/bash/env-bootstrap ]] && source $VOID_PATH/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)

# custom packages
alias vsv='sudo vsv'
alias vp-sync='XBPS_DISTDIR="$HOME/.local/share/pkg/void-packages" "$HOME/.local/share/pkg/void-packages/vp-sync"'
export XBPS_DISTDIR="$HOME/.local/share/pkg/void-packages"

# --- History control (zsh equivalent) ---
HISTCONTROL=ignoreboth
HISTSIZE=32768
HISTFILESIZE="${HISTSIZE}"
HISTFILE=~/.zsh_history
setopt appendhistory inc_append_history share_history

# --- Environment ---
source "$OMARCHY_PATH/default/bash/envs"

# --- Aliases ---
source "$OMARCHY_PATH/default/bash/aliases"

# --- Functions ---
for f in $OMARCHY_PATH/default/bash/fns/*; do source "$f"; done

# ── Prompt (starship, themed via ~/.config/starship.toml) ──
if command -v starship >/dev/null 2>&1; then eval "$(starship init zsh)"; fi

# Hyprland launches GUI apps with cwd=/ — never start an interactive shell at /.
[[ "$PWD" == "/" ]] && cd "$HOME" >/dev/null 2>&1 || true

# ── Extra aliases (from Arch, non-conflicting with void) ──
unalias ff ffd 2>/dev/null
ff() {
  local files=(${(f)"$(fzf -m --preview='bat --color=always {}')"})
  (( $#files )) && nvim $files
}

ffd() {
  local files=(${(f)"$(fzf -m --preview='bat --color=always {}')"})
  (( $#files )) && { echo "Delete: $files"; read -q "?Confirm? "; echo; rm -rf $files }
}
alias zed='zed-editor'
alias v='nvim'
alias qs='~/.local/bin/qshell-ctl'
alias wifi='~/.local/bin/tui-wifi'
alias bt='~/.local/bin/tui-bluetooth'
alias audio='~/.local/bin/tui-audio'
osd='bash ~/hyprQT/config/hypr/scripts/delete-opencode-sessions.sh'
alias pi-session-del='bash ~/hyprQT/config/hypr/scripts/delete-pi-sessions.sh'
alias ll='eza -lah --icons=auto --git'
alias la='eza -a --icons=auto'
alias ls='eza --icons=auto'

# Monochrome eza
export EZA_COLORS="uu=bright-black:gu=bright-black:da=bright-black:ur=white:uw=bright-black:ux=white:ue=bright-black:gr=bright-black:gw=bright-black:gx=white:tr=bright-black:fi=white:di=bright-white:ln=bright-black:pi=bright-black:so=bright-black:bd=bright-black:cd=bright-black:or=bright-black:mi=bright-black:ex=white"

# Dual-GitHub helpers: git-work / git-personal / git-whoami
[ -f "$HOME/.config/shell/git-accounts.sh" ] && source "$HOME/.config/shell/git-accounts.sh"

# ── Editor ──
export EDITOR="nvim" VISUAL="nvim"

# ── Speed tools (zoxide/fzf/atuin/direnv) ──
if command -v zoxide >/dev/null 2>&1; then eval "$(zoxide init zsh --cmd z)"; fi
# FZF Environment & Key Bindings
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi

if [ -f /usr/share/fzf/key-bindings.zsh ]; then source /usr/share/fzf/key-bindings.zsh; fi
if [ -f /usr/share/fzf/completion.zsh ]; then source /usr/share/fzf/completion.zsh; fi
if [ -f "$HOME/.local/state/void/current/theme/fzf.sh" ]; then source "$HOME/.local/state/void/current/theme/fzf.sh"; fi
# Atuin owns Ctrl-R; fzf keeps Ctrl-T + Alt-C.
if command -v atuin >/dev/null 2>&1; then eval "$(atuin init zsh --disable-up-arrow)"; fi
if command -v direnv >/dev/null 2>&1; then eval "$(direnv hook zsh)"; fi

# yazi: `y` cds into the directory you exit in
y() {
  local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  command yazi "$@" --cwd-file="$tmp"
  local cwd="$(cat -- "$tmp" 2>/dev/null)"
  rm -f -- "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
}

# ~/.local/bin carries the repo helpers.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac

# Desktop info on login
command -v fastfetch >/dev/null 2>&1 && fastfetch

# --------------------------------------------------
# Completion
# --------------------------------------------------

autoload -Uz compinit
compinit

# Better completion menu
zstyle ':completion:*' menu select

# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Completion colors — grayscale
zstyle ':completion:*' list-colors \
  '=(#b)*(=0)=38;5;250' \
  '=(#b)*(=1)=38;5;255' \
  '=(#b)*(=2)=38;5;245' \
  '=(#b)*(=3)=38;5;240'

# Autosuggestions — dark gray
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# --------------------------------------------------
# History
# --------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting (MUST be LAST plugin)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Grayscale
ZSH_HIGHLIGHT_STYLES[command]='fg=white'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=white'
ZSH_HIGHLIGHT_STYLES[function]='fg=white'
ZSH_HIGHLIGHT_STYLES[alias]='fg=white'
ZSH_HIGHLIGHT_STYLES[path]='fg=245'
ZSH_HIGHLIGHT_STYLES[comment]='fg=240'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=245'

export PATH="$HOME/.local/bin:$PATH"
# theme controller
theme() { python3 "$HOME/.config/theme/bin/theme.py" "$@"; }

function fe() {
    local file
    if command -v bat >/dev/null 2>&1; then
        file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:300 {}')
    else
        file=$(fzf)
    fi
    [ -n "$file" ] && "${EDITOR:-nvim}" "$file"
}

function fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --header="Select process to kill" | awk '{print $2}')
    [ -n "$pid" ] && echo "$pid" | xargs kill -"${1:-9}"
}

function fxbps() {
    ~/.local/bin/tui-xbps
}

# kilo
export PATH="$HOME/.kilo/bin:$PATH"


