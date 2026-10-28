export USER="rajan"
export HOME="/home/rajan"
export OMARCHY_PATH="/usr/share/omarchy"
export PATH="$HOME/.local/bin:/usr/share/omarchy/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_IGNORE_SPACE AUTO_CD INTERACTIVE_COMMENTS

autoload -Uz compinit
compinit -d "$HOME/.cache/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

export FZF_DEFAULT_OPTS="   --height=60% --layout=reverse --border=rounded --info=inline   --color=bg+:#24283b,bg:#1a1b26,spinner:#7dcfff,hl:#7aa2f7   --color=fg:#c0caf5,header:#bb9af7,info:#e0af68,pointer:#7aa2f7   --color=marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#7dcfff"

if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
fi

[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -la --icons --group-directories-first --git'
    alias la='eza -a --icons --group-directories-first'
    alias lt='eza --tree --level=2 --icons --group-directories-first'
else
    alias ll='ls -lah --color=auto'
    alias la='ls -A --color=auto'
fi

if command -v bat >/dev/null 2>&1; then
    export BAT_THEME="TwoDark"
    alias cat='bat --style=plain --paging=never'
    alias less='bat --paging=always'
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
    alias cd='z'
    alias cdi='zi'
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
else
    PROMPT='%F{blue}%n@void%f:%F{cyan}%~%f %F{magenta}❯%f '
fi

# Void Linux XBPS Power Aliases
alias xi='sudo xbps-install -S'
alias xu='sudo xbps-install -Su'
alias xr='sudo xbps-remove -R'
alias xq='xbps-query -Rs'
alias xclean='sudo xbps-remove -Oo'
alias svstatus='sudo sv status /var/service/*'

# Daily TUI & Quickshell IPC Shortcuts
alias v='nvim'
alias lg='lazygit'
alias top='btop'
alias ff='fastfetch'
alias qs='~/.local/bin/qshell-ctl'
alias wifi='~/.local/bin/tui-wifi'
alias bt='~/.local/bin/tui-bluetooth'
alias audio='~/.local/bin/tui-audio'

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

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

[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
