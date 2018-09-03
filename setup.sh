#!/bin/sh
set -ex 
# 80.5
apk update --update-cache --no-cache
# 82.5
apk add --update --update-cache --no-cache python3      && \
    if [[ ! -e /usr/bin/pip ]]; then ln -sf pip3 /usr/bin/pip; fi; \
    if [[ ! -e /usr/bin/python ]]; then ln -sf /usr/bin/python3 /usr/bin/python; fi; \
    # 150
    # rm -r /usr/lib/python*/ensurepip                    && \
    # rm -r /usr/lib/python*/lib2to3                      && \
    # rm -r /usr/lib/python*/turtledemo                   && \
    # rm -r /usr/lib/python*/idlelib                      && \
    # rm /usr/lib/python*/turtle.py                       && \
    # rm /usr/lib/python*/webbrowser.py                   && \
    # rm /usr/lib/python*/doctest.py                      && \
    # rm /usr/lib/python*/pydoc.py                        && \
    # rm -rf /var/cache /usr/share/terminfo
    # find / -type d -name __pycache__ -exec rm -r {} +;
# 107

# install go zsh neovim git ssh curl
apk add --update --update-cache --no-cache \
    cmake \
    ctags \
    curl \
    dumb-init \
    git \
    go \
    neovim \
    neovim-doc \
    openssh \
    tree \
    zsh \
    zsh-vcs
# 488

# install zsh ~ 42.2M
if [[ ! -d "${HOME}/.zgen" ]]; then
git clone https://github.com/tarjoilija/zgen.git "${HOME}/.zgen"
curl --insecure -fLo ~/.zshrc https://raw.githubusercontent.com/devcontainer/ts-dev/master/configs/_zshrc
git clone https://github.com/powerline/fonts.git --depth=1 "${HOME}/fonts"
${HOME}/fonts/install.sh && rm -rf ${HOME}/fonts
sed -i -E "s/\/(b?a)?sh/\/zsh/" /etc/passwd
/bin/zsh -c "source ~/.zshrc"
echo "zsh configured correctly"
fi;
# 530.3M

# vim setup
mkdir -p ~/.vim/autoload
cp /home/workspace/dotfiles/_vim/autoload/plug.vim ~/.vim/autoload/plug.vim
cp /home/workspace/dotfiles/_vimrc ~/.vimrc
# nvim
if type nvim>/dev/null 2>&1; then
mkdir -p ~/.config/nvim/autoload
ln -sf ~/.vimrc ~/.config/nvim/init.vim
ln -sf ~/.vim/autoload/plug.vim ~/.config/nvim/autoload/plug.vim
fi;

# pip install --upgrade pip
# python -m virtualenv ~/.config/nvim/env

# # Install
# nvim +PlugInstall +qall

# # install typescript and tools
# yarn global add \
#     typescript \
#     parcel-bundler \
#     neovim \
#     jest \
#     ts-jest \
#     gulp \
#     grunt \
#     bower


