ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
ARG HTTP_PROXY
FROM node:carbon-alpine as node

ENV GIT_USER_NAME=${GIT_USER_NAME:-"Ashish Gupta"}
ENV GIT_USER_EMAIL=${GIT_USER_EMAIL:-"gotoashishgupta@gmail.com"}
ENV HTTP_PROXY=${HTTP_PROXY}

LABEL AUTHOR="${GIT_USER_NAME} <${GIT_USER_EMAIL}>"

# ensure local is preferred over distribution + node modules bin
ENV PATH /usr/local/bin:/node_modules/.bin:$PATH
# Generally a good idea to have these, extensions sometimes need them
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TERM screen-256color
ENV PYTHONIOENCODING UTF-8

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


RUN set -ex; \
  cp /etc/apk/repositories /etc/apk/repositories.bck; \
  # add testing channel to repo
  sed -ie '$p$s/community/testing/g;' /etc/apk/repositories; \
  # add edge and dl-4 mirror
  sed -i -e '/cdn/{1h;1!H;$!d};xh;' \
    -e 'p;/cdn/s/v[^\/]\+/edge/g;' \
    -e 'p;/cdn/ s//4/g;' \
    -e 'p;/dl-4/ s/dl-4\.alpinelinux\.org/uk.alpinelinux.org/g;' \
    -e 'p;/uk/ s//dl-2/g;' \
    -e 'p;/dl-2/ s//dl-5/g;' \
    /etc/apk/repositories; \
  # delete v3.6/testing
  sed -i -e '/v3.6\/testing/d' /etc/apk/repositories;

RUN apk add --no-cache ca-certificates
# RUN apk add --no-cache cmake
# RUN apk add --no-cache ctags
RUN apk add --no-cache curl
RUN apk add --no-cache dumb-init
RUN apk add --no-cache expat
RUN apk add --no-cache git
# RUN apk add --no-cache go
RUN apk add --no-cache neovim
RUN apk add --no-cache openssl
RUN apk add --no-cache openssh
RUN apk add --no-cache perl
RUN apk add --no-cache python
RUN apk add --no-cache python3
RUN apk add --no-cache py-pip
RUN apk add --no-cache stow
RUN apk add --no-cache tree
RUN apk add --no-cache zsh
RUN apk add --no-cache zsh-vcs
RUN apk add --no-cache bash

# generate ssh keys
RUN set -eux; \
    ssh-keygen -q -t rsa -b 4096 -C ${GIT_USER_EMAIL} -N '' -f /root/.ssh/id_rsa; \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys; \
    for key in /etc/ssh/ssh_host_*_key.pub; do \ 
      echo "localhost $(cat ${key})" >> /root/.ssh/known_hosts;\
    done; \
    eval "$(ssh-agent -s)"; \
    ssh-add "${HOME}/.ssh/id_rsa"

# Install powerline fonts
RUN set -eux; \
    git clone https://github.com/powerline/fonts.git --depth=1 "${HOME}/fonts"; \
    ${HOME}/fonts/install.sh; \
    rm -rf ${HOME}/fonts;
# Install zsh
COPY dotfiles /root/.dotfiles
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
  sed -ie '1a \
    if type ssh-agent> /dev/null 2>&1; then\n\
      eval $(ssh-agent -s);\n\
    fi;\n\
    [ -f ~/.bash_profile ] && source ~/.bash_profile;\n\
    [ -f ~/.bashrc ] && source ~/.bashrc;\n\
    # load zgen\n\
    source "${HOME}/zgen/zgen.zsh"\n\
    ' ${HOME}/.dotfiles/zsh-quickstart-kit/zsh/.zshrc; \
  cp "${HOME}/.dotfiles/.zgen-local-plugins" "${HOME}/.zgen-local-plugins"; \
  cp -R "${HOME}/.dotfiles/.zshrc.d" "${HOME}/.zshrc.d"; \
  sed -i -E 's/\/(b?a)?sh/\/zsh/' /etc/passwd; \
  /bin/zsh -c " \
    source ~/.zshrc; \
    zgen selfupdate; \
    zgen update; \
    zgen save;"

# Install spacevim
RUN apk add --no-cache -t .build-deps build-base 
RUN apk add --no-cache -t .build-deps fontconfig 
RUN apk add --no-cache -t .build-deps mkfontdir 
RUN apk add --no-cache -t .build-deps mkfontscale
RUN apk add --no-cache -t .build-deps python-dev
RUN apk add --no-cache -t .build-deps python3-dev
RUN pip install --user neovim pipenv
ENV PATH /root/.local/bin:$PATH
RUN curl -sLf https://spacevim.org/install.sh | bash
RUN nvim --headless +'call dein#install()' +qall
RUN apk del .build-deps