ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
ARG HTTP_PROXY
FROM node:carbon-alpine as node

ENV GIT_USER_NAME=${GIT_USER_NAME:-"Ashish Gupta"} \
    GIT_USER_EMAIL=${GIT_USER_EMAIL:-"gotoashishgupta@gmail.com"} \
    HTTP_PROXY=${HTTP_PROXY} \
    # ensure local is preferred over distribution + node modules bin
    PATH=/usr/local/bin:/node_modules/.bin:$PATH \
    # Generally a good idea to have these, extensions sometimes need them
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    COLORTERM=truecolor \
    TERM=xterm-256color \
    PYTHONIOENCODING=UTF-8

LABEL AUTHOR="${GIT_USER_NAME} <${GIT_USER_EMAIL}>"

# Set yarn proxy
RUN set -eux; \
  if [[ ! -z "${HTTP_PROXY}" ]] && which yarn >/dev/null 2>&1; then \
    echo "Setting Proxy to ${HTTP_PROXY}"; \
    yarn config set proxy ${HTTP_PROXY}; \
    yarn config set https-proxy ${HTTP_PROXY}; \
    yarn config set strict-ssl false ; \
  fi; \
  if which yarn >/dev/null 2>&1; then \
    yarn config set worspace-experimental true ;\
  fi;

FROM node as dev


# RUN set -ex; \
#   cp /etc/apk/repositories /etc/apk/repositories.bck; \
#   # add testing channel to repo
#   sed -ie '$p$s/community/testing/g;' /etc/apk/repositories; \
#   # add edge and dl-4 mirror
#   #         # this sed pattern causes all matches
#   #         # to go into match pattern space
#   sed -i -e '/cdn/{1h;1!H;$!d};xh;' \
#     -e 'p;/cdn/s/v[^\/]\+/edge/g;' \
#     -e 'p;/cdn/ s//4/g;' \
#     -e 'p;/dl-4/ s/dl-4\.alpinelinux\.org/uk.alpinelinux.org/g;' \
#     -e 'p;/uk/ s//dl-2/g;' \
#     -e 'p;/dl-2/ s//dl-5/g;' \
#    /etc/apk/repositories; \
#   # delete v3.6/testing
#   sed -i -e '/v[^\/]\+\/testing/d' /etc/apk/repositories;

RUN apk update; \
    apk add --no-cache -t .build-deps build-base fontconfig mkfontdir mkfontscale python-dev python3-dev; \
    apk add --no-cache -t .core ca-certificates python3 py-pip python git neovim openssl openssh perl stow tree zsh zsh-vcs bash dumb-init curl

# generate ssh keys
RUN set -eux; \
    ssh-keygen -q -t rsa -b 4096 -C ${GIT_USER_EMAIL} -N '' -f "${HOME}/.ssh/id_rsa"; \
    cp "${HOME}/.ssh/id_rsa.pub" "${HOME}/.ssh/authorized_keys"; \
    for key in /etc/ssh/ssh_host_*_key.pub; do \ 
      echo "localhost $(cat ${key})" >> "${HOME}/.ssh/known_hosts";\
    done; \
    eval "$(ssh-agent -s)"; \
    ssh-add "${HOME}/.ssh/id_rsa"

# Install powerline fonts
RUN set -eux; \
    git clone https://github.com/powerline/fonts.git --depth=1 "${HOME}/fonts"; \
    ${HOME}/fonts/install.sh; \
    rm -rf "${HOME}/fonts";

# Install zsh
COPY . /root/.dotfiles/devbox
RUN set -eux; \
  eval $(ssh-agent -s) \
  git clone https://github.com/tarjoilija/zgen.git "${HOME}/zgen"; \
  sed -i -e '/shasum -a 256/ s//sha256sum/g' ${HOME}/zgen/zgen.zsh; \
  mkdir -p "${HOME}/.dotfiles/zsh-quickstart-kit"; \
  git clone https://github.com/git-fork/zsh-quickstart-kit.git "${HOME}/.dotfiles/zsh-quickstart-kit"; \
  cd "${HOME}/.dotfiles/zsh-quickstart-kit"; \
  sed -i -e '/alias grep/d' ./zsh/.zsh_aliases; \
  stow --target="${HOME}" zsh; \
  cd ${HOME}; \
  sed -i -e '1i\
    if type ssh-agent> /dev/null 2>&1; then\n\
      eval $(ssh-agent -s);\n\
    fi;\n\
    [ -f ~/.bash_profile ] && source ~/.bash_profile;\n\
    [ -f ~/.bashrc ] && source ~/.bashrc;\n\
    export fpath=(/usr/local/share/zsh-completions $fpath)\n\
    # load zgen\n\
    source "${HOME}/zgen/zgen.zsh"\n\
  ' ${HOME}/.dotfiles/zsh-quickstart-kit/zsh/.zshrc; \
  # symlink your local plugins
  cd "${HOME}/.dotfiles/devbox"; \
  stow --target="${HOME}" dotfiles; \
  cd "${HOME}"; \
  # change default shell
  sed -i -E 's/\/(b?a)?sh/\/zsh/' /etc/passwd; \
  # install zsh zgen packages
  /bin/zsh -c " \
    source ~/.zshrc; \
    zgen selfupdate; \
    zgen update; \
    zgen save;" \
  echo 'Zsh installed and configured';

# Install spacevim
ENV PATH /root/.local/bin:$PATH
RUN set -eux; \
    pip install --user neovim pipenv; \
    curl -sLf https://spacevim.org/install.sh | bash; \
    nvim --headless +'call dein#install()' +qall; \
    sed -i -e 's/\x27/"/g;' -e '/statusline_\(inactive_\)\?separator/ s/"[^"]\+"/"nil"/g;' ${HOME}/.SpaceVim.d/init.toml;

FROM dev as prod
RUN apk del .build-deps
