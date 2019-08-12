#!/bin/bash

BRANCH="${1-master}"
DOTFILES_ORIGIN="https://github.com/ellisonleao/dotfiles.git"
DOTFILES_REPO_DIR="$HOME/dotfiles"

# shellcheck source=/dev/null
source ./helpers.sh

# --------------------------------------------------------------------
# | Main Functions                                                   |
# --------------------------------------------------------------------

configure_terminal() {
    print_info "Configuring terminal"
    FOLDERS="base16 bash git nvim python"
    for item in $FOLDERS; do
        execute "stow ${item}" "Creating ${item} symlink"
    done
}

clone_dotfiles() {
    if [ -d "$DOTFILES_REPO_DIR" ]; then
        print_info "Dotfiles folder already exists.. skipping"
        return
    fi
    # Cloning dotfiles on directory
    execute "git clone $DOTFILES_ORIGIN $DOTFILES_REPO_DIR --branch=$BRANCH" "Cloning dotfiles on $DOTFILES_REPO_DIR branch=$BRANCH"
}

configure_python() {
    print_info "Configuring python environment.."

    execute "curl https://pyenv.run | bash" "Installing pyenv"

    # reload terminal configs
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"

    if ! cmd_exists "pyenv"; then
        print_error "pyenv could not be installed. Moving on"
        return 1
    fi

    # virtualenvwrapper
    execute "git clone https://github.com/pyenv/pyenv-virtualenvwrapper.git $(pyenv root)/plugins/pyenv-virtualenvwrapper"

    execute "pyenv install 3.7.3" "Installing Python 3.7.3"
    execute "pyenv install 3.6.8" "Installing Python 3.6.8"
    execute "pyenv install 2.7.15" "Installing Python 2.7.15"
    execute "pyenv virtualenv 3.7.3 3" "Creating global python 3 virtualenv"
    execute "pyenv virtualenv 2.7.15 2" "Creating global python 2 virtualenv"

    # installing python specific tools on global virtualenvs
    pyenv activate 3
    execute "pip install awscli neovim howdoi httpie ipython flake8 youtube-dl speedtest-cli" "Installing python 3 packages"
    pyenv deactivate
    pyenv activate 2
    execute "pip install flake8 neovim" "Installing python 2 packages"
    pyenv deactivate

    execute "pyenv global 3.7.3 3 2.7.15 2" "Set python versions global order"
}

configure_node() {
    unset NVM_DIR
    # execute "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash" "Installing NVM"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
    if ! cmd_exists "nvm"; then
        print_error "Failed to install nvm. Moving on.."
        return 1
    fi
    execute "nvm install --lts" "Installing latest LTS node version"

    # shellcheck source=/dev/null
    source "$HOME/.bashrc"

    # install js apps
    execute "npm i -g eslint" "Install eslint"
    execute "npm i -g prettier" "Install prettier"
}

install() {
    PACKAGE="$1"
    PACKAGE_READABLE_NAME="$2"

    if ! package_is_installed "$PACKAGE" "apt"; then
        execute "yes | sudo apt-get install $PACKAGE" "$PACKAGE_READABLE_NAME"
    else
        print_success "$PACKAGE_READABLE_NAME"
    fi
}

install_snap() {
    PACKAGE="$1"
    PACKAGE_READABLE_NAME="$2"

    if ! package_is_installed "$PACKAGE" "snap"; then
        execute "sudo snap install $PACKAGE" "$PACKAGE_READABLE_NAME"
    else
        print_success "$PACKAGE_READABLE_NAME"
    fi
}

package_is_installed() {
    PACKAGE="$1"
    PROGRAM="$2"
    if [ "$PROGRAM" == "apt" ]; then
        dpkg -s "$PACKAGE" &>/dev/null
    elif [ "$PROGRAM" == "snap" ]; then
        snap list | grep "$PACKAGE" &>/dev/null
    fi
}

add_ppts_and_update() {
    yes | sudo add-apt-repository ppa:longsleep/golang-backports

    # docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

    execute "sudo apt-get update -qqy" "APT (update)"
}

install_apps() {
    print_info "Installing APT/Snap apps"
    # add_ppts_and_update

    # apt
    install stow "GNU Stow"
    install golang-go "Golang"
    install go-dep "Golang DEP"
    install snapd "Snapd"
    install hub "Github Hub"
    install neovim "NeoVim"
    install ripgrep "ripgrep"
    install pass "pass"
    install bat "bat"
    install fd-find "fd"
    install shellcheck "shellcheck"
    install docker "docker"
    install docker-compose "docker compose"
    install google-chrome-stable "Chrome"
    install firefox "Firefox"
    install tor "TOR"
    install qbittorrent "QBitTorrent"
    install vlc "VLC"
    install terminator "Terminator"
    install gnome-tweaks "GNOME Tweaks"
    install fonts-firacode "FiraCode font"

    # snaps
    install_snap spotify "Spotify"
    install_snap shfmt "shfmt"
}

# ----------------------------------------------------------------------
# | Main                                                               |
# ----------------------------------------------------------------------

main() {

    verify_os

    ask_for_sudo

    clone_dotfiles

    install_apps

    configure_terminal

    configure_python

    configure_node

    print_in_green "Success! Please restart the terminal to see the changes!"
}

main