#!/bin/bash

function install_zsh_oh_my_zsh() {
    echo "Installing Zsh..."
    if ! command -v zsh &> /dev/null; then
        sudo pacman -Sy --noconfirm zsh
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
    install_zsh_oh_my_zsh

    echo "Installing required packages..."
    sudo pacman -Sy --noconfirm fzf fd bat git-delta eza thefuck zoxide zsh-autosuggestions zsh-syntax-highlighting

    echo 'alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"' >> $HOME/.zshrc
    echo 'eval "$(zoxide init zsh)"' >> $HOME/.zshrc
    echo 'alias cd="z"' >> $HOME/.zshrc

    echo "Installing yay for additional AUR packages..."
    if ! command -v yay &> /dev/null; then
        sudo pacman -Sy --needed --noconfirm base-devel
        git clone https://aur.archlinux.org/yay-bin.git ~/yay-bin
        cd ~/yay-bin && makepkg -si --noconfirm && cd ~ && rm -rf ~/yay-bin
    fi

    echo "Installing tlrc via yay..."
    yay -S --noconfirm tlrc

    echo "Configuring Zsh plugins..."
    echo "source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
    echo "source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc

    echo "Configuring FZF..."
    echo '
export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1"
}

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always {} | head -200; else bat -n --color=always --line-range :500 {}; fi"
export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
' >> ~/.zshrc

    echo "Configuring thefuck..."
    echo "eval \$(thefuck --alias)" >> ~/.zshrc

    echo "Cloning fzf-git.sh..."
    git clone https://github.com/junegunn/fzf-git.sh.git ~/fzf-git.sh
    echo "source ~/fzf-git.sh/fzf-git.sh" >> ~/.zshrc

    echo "Setting KEYTIMEOUT..."
    echo "KEYTIMEOUT=50" >> ~/.zshrc
}

function revert_changes() {
    echo "Reverting changes..."
    
    sudo pacman -Rns --noconfirm fzf fd bat git-delta eza thefuck zoxide tlrc zsh-autosuggestions zsh-syntax-highlighting
    yay -Rns --noconfirm tlrc
    
    sed -i '/alias ls=/d' ~/.zshrc
    sed -i '/eval "$(zoxide init zsh)"/d' ~/.zshrc
    sed -i '/alias cd="z"/d' ~/.zshrc
    sed -i '/source ~\/fzf-git.sh\/fzf-git.sh/d' ~/.zshrc
    rm -rf ~/fzf-git.sh
    echo "Revert complete."
}

if [[ $1 == "revert" ]]; then
    revert_changes
else
    install_tools
fi

