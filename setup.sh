#!/bin/bash

function install_zsh_oh_my_zsh() {
    echo "Installing Zsh..."
    if ! command -v zsh &> /dev/null; then
        sudo apt update && sudo apt install -y zsh
    fi

    echo "Installing Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        chsh -s $(which zsh)
    fi

    echo "Setting Zsh as the default shell..."
    echo 'export SHELL=$(which zsh)' >> ~/.zshrc
    echo 'exec $(which zsh) -l' >> ~/.bashrc
}

function install_tools() {
    # Install Zsh and Oh My Zsh first
    install_zsh_oh_my_zsh

    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    echo >> $HOME/.zshrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.zshrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

    # Install required packages
    echo "Installing gcc, build-essential..."
    brew install gcc
    brew install build-essential

    echo "Installing fzf..."
    brew install fzf
    echo 'source <(fzf --zsh)' >> $HOME/.zshrc
    echo "Installing fd..."
    brew install fd
    echo "Installing bat, git-delta, eza, tlrc, thefuck, zoxide..."
    brew install bat git-delta eza tlrc thefuck zoxide
    echo 'alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"' >> $HOME/.zshrc

    echo 'eval "$(zoxide init zsh)"' >> $HOME/.zshrc
    echo 'alias cd="z"' >> $HOME/.zshrc

    echo "Installing zsh plugins..."
    brew install zsh-autosuggestions
    brew install zsh-syntax-highlighting

    echo "source $(brew --prefix zsh-autosuggestions)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
    echo "source $(brew --prefix zsh-syntax-highlighting)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

    # Add advanced FZF configuration
    echo "Configuring FZF..."
    echo '
# -- Use fd instead of fzf --

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

# Use fd (https://github.com/sharkdp/fd) for listing path candidates.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

# FZF preview customization
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"

export FZF_CTRL_T_OPTS="--preview '\''$show_file_or_dir_preview'\''"
export FZF_ALT_C_OPTS="--preview '\''eza --tree --color=always {} | head -200'\''"

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview '\''eza --tree --color=always {} | head -200'\'' "$@" ;;
    export|unset) fzf --preview "eval '\''echo ${}'\''"         "$@" ;;
    ssh)          fzf --preview '\''dig {}'\''                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}
' >> ~/.zshrc

    # Configure history settings
    echo '
# history setup
HISTFILE=$HOME/.zsh_history
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

# completion using arrow keys (based on history)
bindkey '\''^[[A'\'' history-search-backward
bindkey '\''^[[B'\'' history-search-forward
' >> ~/.zshrc

    # Configure thefuck
    echo "Configuring thefuck..."
    brew install thefuck
    echo "eval $(thefuck --alias)" >> ~/.zshrc

    # Clone fzf-git.sh and configure
    echo "Cloning fzf-git.sh..."
    cd ~
    git clone https://github.com/junegunn/fzf-git.sh.git
    echo "source ~/fzf-git.sh/fzf-git.sh" >> ~/.zshrc

    # Set KEYTIMEOUT
    echo "Setting KEYTIMEOUT..."
    echo "KEYTIMEOUT=50" >> ~/.zshrc
    echo "alias cd='z'" >> ~/.zshrc
}

function revert_changes() {
    echo "Reverting changes..."

    # Remove Homebrew
    echo "Removing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

    # Remove added configurations from ~/.zshrc
    sed -i '' '/# -- Use fd instead of fzf --/,+24d' ~/.zshrc
    sed -i '' '/# history setup/,+8d' ~/.zshrc
    sed -i '' '/eval $(thefuck --alias)/d' ~/.zshrc
    sed -i '' '/source ~\/fzf-git.sh\/fzf-git.sh/d' ~/.zshrc
    sed -i '' '/KEYTIMEOUT=50/d' ~/.zshrc
    sed -i '' '/source .*zsh-autosuggestions/d' ~/.zshrc
    sed -i '' '/source .*zsh-syntax-highlighting/d' ~/.zshrc

    # Remove fzf-git.sh directory
    rm -rf ~/fzf-git.sh

    echo "Revert complete."
}

if [[ $1 == "revert" ]]; then
    revert_changes
else
    install_tools
fi
