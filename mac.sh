#!/bin/bash
function setup() {
  if ! type brew >/dev/null 2>&1; then
    install_homebrew;
  else
    echo -e "Homebrew is already installed";
  fi;
  brew_clean_and_update;
  install_necessary_packages;
}
function set_zsh() {
  brew install zsh zsh-completions
  export fpath=(/usr/local/share/zsh-completions $fpath)
  chmod go-w '/usr/local/share'
  /bin/zsh -c "echo 'Echo from Zsh'";
  # Docker install and configure zsh
}
function setup_neovim() {
  brew install python
  brew install neovim

}
function cf_login() {
  cf login -a https://api.system.aws-usw02-pr.ice.predix.io --sso
}
function install_homebrew() {
  echo -e "Installing Homebrew";
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}
function uninstall_homebrew() {
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
}
function install_cf_packages() {
  brew install 
}
function install_brew_rm_packages() {
  brew tap beeftornado/rmtree
}
function install_necessary_packages() {
  # cloudfoundry/tap/{cf-cli,bosh-init,bosh-cli,credhub-cli,bbl} caskroom/cask/iterm2
  # git go neovim node openssl python terraform wget yarn zsh zsh-completions
  brew install gnu-sed --with-default-names
  brew install stow
  brew install zsh zsh-completions 
  brew install wget git caskroom/cask/{iterm2,virtualbox} gettext kubectl
  brew install node@8
  brew install yarn --without-node
  install_brew_rm_packages;
  install_cf_packages;
}
function brew_clean_and_update() {
  brew update;
  brew upgrade --all;
  brew cleanup;
  brew prune;
  brew doctor;
}
function brew_installed_packages() {

  local  __resultvar=$1
  local  returnVal=( $(brew ls -l | rev | cut -d' ' -f1 | rev | tr '\n' ' ') )
  if [[ "$__resultvar" ]]; then
    eval $__resultvar="'$returnVal'"
  else
    echo "$returnVal"
  fi
}
setup;

