# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Custom plugins/themes live outside the oh-my-zsh submodule so they're
# tracked by dotfiles' own git (a submodule can't nest inside another).
export ZSH_CUSTOM="$HOME/.oh-my-zsh-custom"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(zsh-vi-mode)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export XCURSOR_THEME=Adwaita
eval "$(zellij setup --generate-auto-start zsh)"

eval "$(zoxide init --cmd cd zsh)"

eval "$(starship init zsh)"

alias nix-shell="nix-shell --run zsh"
alias "nix-develop"="nix develop --command zsh"
# alias cat="bat"

alias ls=lsd
alias pd=pushd
alias pdd="pushd ."
alias pp=popd
alias ppp="popd && popd"
alias pppp="popd && popd && popd"
alias ppppp="popd && popd && popd && popd"

alias vi=nvim
alias vim=nvim
alias nvim="nix run /home/pierre/Projets/nix/nixvim"
alias waterfox="detache flatpak run net.waterfox.waterfox"

# From https://github.com/nix-community/nix4nvchad?tab=readme-ov-file
alias "nvchad"="nix run github:nix-community/nix4nvchad/#nvchad"

alias "python-init-3.14"="nix flake init --template github:Pierre-Thibault/my-uv2nix#python314"
alias "python-init-3.13"="nix flake init --template github:Pierre-Thibault/my-uv2nix#python313"

export PATH=$PATH:~/bin
export PATH=$PATH:~/nixos-config/bin
export PATH=$PATH:~/.local/bin

alias aider="aider-auto-theme"

kilo() {
  nix shell nixpkgs#nodejs -c npx @kilocode/cli "$@"
}

prompt_context() {
  prompt_segment black default "%n@%m %# $(which python > /dev/null && echo -n "$(python --version)" || echo -n)"
}

# alias grep='grep -n'

bindkey -v          # active vi key map

eval "$(atuin init zsh --disable-up-arrow)"
bindkey '^X' atuin-search  # Ctrl+X


# shellcheck source=/dev/null
source ~/.fzf.zsh

alias gthumb="gthumb-launch"

export GOPATH="$HOME/.local/share/go";
export PATH="$GOPATH/bin:$PATH";

grip() {
    local creds
    creds=$(sops -d --output-type dotenv ~/nixos-config/sops/grip.yaml)
    local username
    username=$(echo "$creds" | grep '^GITHUB_USERNAME=' | cut -d= -f2)
    local token
    token=$(echo "$creds" | grep '^GITHUB_TOKEN=' | cut -d= -f2)
    command grip --browser --user "$username" --pass "$token" "$@"
}

open_md() {
    local dark=0
    local gs
    gs=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)
    [[ "$gs" == *"dark"* ]] && dark=1

    if (( dark )); then
        local theme="$HOME/.config/pandoc/catppuccin-mocha.theme"
        local css="$HOME/.config/pandoc/catppuccin-mocha.css"
    else
        local theme="$HOME/.config/pandoc/catppuccin-latte.theme"
        local css="$HOME/.config/pandoc/catppuccin-latte.css"
    fi

    local tmp
    tmp=$(mktemp --suffix=.html)
    nix run nixpkgs#pandoc -- \
        --standalone \
        --embed-resources \
        --highlight-style="$theme" \
        --css="$css" \
        -f markdown -t html5 \
        "$1" -o "$tmp" || return 1

    ~/nixos-config/bin/open-new-browser-window "file://$tmp"
}

export SOPS_AGE_KEY_CMD="age -d $HOME/.config/sops/age/keys.txt.age"

# Use the global gitleaks config (stowed from ~/dotfiles/gitleaks) unless
# the current directory provides its own .gitleaks.toml
gitleaks() {
  if [[ -f .gitleaks.toml ]]; then
    command gitleaks "$@"
  else
    command gitleaks -c ~/.config/gitleaks/gitleaks.toml "$@"
  fi
}

export BORG_REPO='/run/media/pierre/Disque2/BorgBackup/backup-pierre-pierre-nixos'
export BORG_PASSCOMMAND='secret-tool lookup repo-id 1dd9e1100359cab671f26037e17ba538cdeee0b2fa47181fd4c29e51204a66ac'
export BORG_REMOTE_REPO='ssh://wsw5tfhn@wsw5tfhn.repo.borgbase.com/./repo'
export BORG_REMOTE_PASSCOMMAND='secret-tool lookup repo-id borgbase-home'
export BORG_RSH="env SSH_ASKPASS=$HOME/bin/ssh-askpass-borgbase SSH_ASKPASS_REQUIRE=force ssh -i $HOME/.ssh/borgbase-appendonly"
