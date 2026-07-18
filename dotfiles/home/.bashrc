#
#   ▄▄                ▄▄
#   ██                ██
#   ████▄  ▀▀█▄ ▄█▀▀▀ ████▄ ████▄ ▄████
#   ██ ██ ▄█▀██ ▀███▄ ██ ██ ██ ▀▀ ██
#   ████▀ ▀█▄██ ▄▄▄█▀ ██ ██ ██    ▀████
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#PS1="\[\e[36m\][\u] \[\e[34m\]\w \[\e[33m\]❯ \[\e[0m\]"
#PS1="\[\e[91;1m\][\[\e[93m\]\h\[\e[92m\]@\[\e[94m\]\u\[\e[0m\] \[\e[95;1m\]\w\[\e[91m\]]\[\e[0m\]\\$ "

PROMPT_COMMAND='PS1_CMD1=$(git branch --show-current 2>/dev/null)'
PS1='\[\e[33m\]󰝰 \[\e[38;5;220;1;27m\]\w\[\e[0;1;38;5;39;3m\] ${PS1_CMD1} \n\[\e[0;1;2m\]\A\[\e[0;1m\] \$\[\e[0m\] '

# better set this on hyprland.conf
#export DISPLAY=$(systemctl --user show-environment 2>/dev/null | grep '^DISPLAY=' | cut -d= -f2-)

export TERM="xterm-256color"                        # getting proper colors
export HISTCONTROL=ignoredups:erasedups:ignorespace # no duplicate entries

# Man Pages with Bat
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p --theme=ansi'"

#default editor
export EDITOR='nvim'
export VISUAL="$EDITOR"
export BROWSER='firefox'

if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Language-specific
if [ -d "$HOME/.cargo/bin" ]; then
  export PATH="$HOME/.cargo/bin:$PATH"
fi

if [ -d "$HOME/.go/bin" ]; then
  export PATH="$HOME/.go/bin:$PATH"
fi

if [ -d "$HOME/go/bin" ]; then
  export PATH="$HOME/go/bin:$PATH"
fi

# This finds every directory inside ~/.local/bin and adds it to PATH
for d in $HOME/.local/bin/*/; do
  export PATH="$PATH:$d"
done

# --- SHOPT CUSTOMIZATIONS ---

# Enter a directory by just typing its name (no 'cd' required)
shopt -s autocd
# Correct minor spelling errors in 'cd' directory names
shopt -s cdspell
# Append to history file instead of overwriting it (prevents losing commands)
shopt -s histappend
# Make 'ls' and wildcards ignore case (finds .jpg and .JPG)
shopt -s nocaseglob
shopt -s nocasematch

# Allow '**' to search all subdirectories recursively
shopt -s globstar
# Include hidden files (starting with '.') in wildcard results
shopt -s dotglob
# Enable advanced patterns like !(file) to mean 'everything except'
shopt -s extglob
# Update terminal window size values after every command
shopt -s checkwinsize
shopt -s direxpand

# === Better Bash Completion Settings ===

bind 'set completion-ignore-case on'
bind 'set show-all-if-ambiguous on'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
bind 'set mark-directories on'
bind 'set mark-symlinked-directories on'

# === Better History Navigation ===
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# === Quick Shortcuts ===
# Alt+u = up one directory (Alt+u works great)
bind '"\eu": "cd ..\n"'
# Alt+h = home directory
bind '"\eh": "cd\n"'
bind '"\Cl": "clear\n"' # Ctrl+l = clear (like default but more reliable)
bind '"\Cp": "cd -\n"'  # Ctrl+p = previous directory

# === Quote current line with sudo or quotes ===
bind '"\es": "\C-asudo \C-e"'    # Alt+s = add sudo
bind '"\eq": "\C-a\"\C-e\"\C-b"' # Alt+q = wrap line in quotes

# === Show line numbers in history ===
export HISTTIMEFORMAT="%F %T "
export HISTSIZE=10000
export HISTFILESIZE=20000

## Useful aliases
# Replace ls with eza
alias ls='eza -lahF --color=always --group-directories-first --icons' # preferred listing
alias la='eza -a --color=always --group-directories-first --icons'    # all files and dirs
alias ll='eza -l --color=always --group-directories-first --icons'    # long format
alias lt='eza -aT --color=always --group-directories-first --icons'   # tree listing
alias l.="eza -a | grep -e '^\.'"                                     # show only dotfiles

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias x='exit'
alias c='clear'
alias h='history'
alias which='type -a'
alias now='date +"%Y-%m-%d %T"'
alias week='date +%V'
alias pkill='pkill -f'

alias fg="rg --files | fzf --preview 'bat --color=always {}'"
alias fp="fzf --preview 'bat --color=always --style=numbers --line-range :500 {}'"

alias oc='openclaude'

alias activate='source venv/bin/activate'
alias venvx='python -m venv venv'

alias bashrc='$EDITOR ~/.bashrc'
alias reload='source ~/.bashrc || bash --login && echo "Reloaded .bashrc"'
alias rmbackup='rm -rf ~/.config/*.backup.*'
alias font='sudo fc-cache -f -v'

alias music='ncmpcpp || rmpc'

rgcd() {
  # 1. Search only in specific directories
  # 2. Get the filename
  local file
  file=$(rg -l "$1" ~/.config ~/Downloads/ ~/Project 2>/dev/null |
    fzf --preview 'bat --color=always --style=numbers {}' \
      --bind 'shift-up:preview-up,shift-down:preview-down' \
      --header "Searching: .config, .local, Project")

  # 3. If a file was selected, cd into its parent directory
  if [[ -n "$file" ]]; then
    cd "$(dirname "$file")" || return
    ls -p # Show files in the new directory (optional)
  fi
}

dmake() {

  sudo rm .config.h
  sudo make clean install

}
