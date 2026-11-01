# --- Color and Prompt Setup ---
autoload -U colors && colors
setopt prompt_subst
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[yellow]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "

# --- History ---
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE="$HOME/.local/share/zsh_history"

# --- Completion System ---
autoload -U compinit
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
compinit

# Load LS_COLORS if not already set (optional, depends on your setup)
[[ -z "$LS_COLORS" ]] && eval "$(dircolors -b)"

# --- Key Bindings ---
bindkey -e
bindkey '\er' autosuggest-accept     # Ctrl-r: Accept autosuggestion
bindkey '\eg' beginning-of-line      # Ctrl-g: Go to beginning
bindkey '\ek' end-of-line            # Ctrl-k: Go to end

# --- Environment ---
export EDITOR=vim

# --- Aliases ---
alias v="vim"
alias t="translate"
alias ls="ls -a"
alias d="cd ~/downloads/"
alias m="cd ~/mucator/v9/constituents/testing"
alias ma="cd ~/mucator/v9/"
alias .l="cd ~/.local/bin/"
alias .c="cd ~/.config/"
alias z="zathura"
alias xclip="xclip -sel clip"
alias pfetch="printf '\n' && pfetch"
alias c="clear"
alias vm="vim ~/mucator/v9/mucator"
alias r="ranger"
alias t="cd /tmp"
alias spac="pacman -Slq | fzf --preview 'pacman -Si {}' --layout=reverse"
alias feh-='feh --sort mtime'
alias x="chmod +x"

# Source custom alias file
source ~/.config/shell/aliasrc

# --- Plugins ---

# zsh-autosuggestions (colored ghost text)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=cyan'
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting
# NOTE: This should be sourced **last**
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

