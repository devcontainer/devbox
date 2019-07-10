FROM amazonlinux as build
ARG GIT_USER_NAME
ARG GIT_USER_EMAIL
ARG HTTP_PROXY
ARG GOPATH
ARG JAVA_HOME
ARG MAVEN_HOME
ARG MAVEN_CONFIG
# Generally a good idea to have these, extensions sometimes need them
ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8 \
  COLORTERM=truecolor \
  TERM=xterm-256color \
  PYTHONIOENCODING=UTF-8 \
  GIT_USER_NAME=${GIT_USER_NAME:-"Ashish Gupta"} \
  GIT_USER_EMAIL=${GIT_USER_EMAIL:-"gotoashishgupta@gmail.com"} \
  PATH=/root/.local/bin:/usr/local/bin:/node_modules/.bin:$PATH \
  EDITOR=nvim \
  VISUAL=nvim

LABEL AUTHOR="${GIT_USER_NAME} <${GIT_USER_EMAIL}>"

# Amazon default repo.list pacakges
RUN yum update -y; \
  # Install build packages
  yum install -y fontconfig mkfontdir; \
  # Install required packages
  yum install -y python-pip python3-pip wget git openssl tree zsh nc ca-certificates perl make automake gcc gmp-devel libffi zlib xz tar gnupg; \
  update-ca-trust force-enable; \
  amazon-linux-extras install -y docker; \
  # Install dumb-init
  wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64; \
  chmod +x /usr/local/bin/dumb-init; \
  # clean yum packages
  yum clean all; \
  rm -rf /var/cache/yum;

# Packages from epel registry
RUN set -eux; \
  yum groupinstall -y "Development Tools"; \
  # stow and neovim are epel pacakges
  wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm; \
  yum install -y ./epel-release-latest-7.noarch.rpm neovim jq file; \
  rm ./epel-release-latest-7.noarch.rpm; \
  # clean yum packages
  yum clean all; \
  rm -rf /var/cache/yum;

# So that all process that we start are child of dumb-init
ENTRYPOINT [ "dumb-init", "--" ]
CMD ["zsh", "--"]
  
# generate ssh keys
RUN set -eux; \
  ssh-keygen -q -t rsa -b 4096 -C ${GIT_USER_EMAIL} -N '' -f "${HOME}/.ssh/id_rsa"; \
  cp "${HOME}/.ssh/id_rsa.pub" "${HOME}/.ssh/authorized_keys"; \
  for key in /etc/ssh/ssh_host_*key.pub; do \ 
  echo "localhost $(cat ${key})" >> "${HOME}/.ssh/known_hosts";\
  done; \
  eval "$(ssh-agent -s)"; \
  ssh-add "${HOME}/.ssh/id_rsa"

#============ Install SAWS for awscli ============#
# Install saws for awscli
RUN set -eux; \
  pip3 install --upgrade --ignore-installed saws awsebcli awscli boto3 six==1.11.0; \
  curl https://raw.githubusercontent.com/wallix/awless/master/getawless.sh | bash; \
  mv awless /usr/local/bin/; \
  echo 'source <(awless completion zsh)' >> ~/.bash_profile; \
  curl -o /usr/local/bin/ecs-cli https://s3.amazonaws.com/amazon-ecs-cli/ecs-cli-linux-amd64-latest; \
  chmod +x /usr/local/bin/ecs-cli;
#============ ./Install SAWS for awscli ==========#


#============ Install Java, Maven, SpringBoot ============#
ENV JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java} \
  MAVEN_HOME=${MAVEN_HOME:-/usr/share/maven} \
  MAVEN_CONFIG=${MAVEN_CONFIG:-/root/.m2} \
  APP_TARGET=${APP_TARGET:-target} \
  JAVA_OPTS=${JAVA_OPTS:-}
RUN set -eux; \
  yum install -y maven; \
  yum clean all; \
  rm -rf /var/cache/yum;
#============ ./Install Java, Maven, SpringBoot ==========#


#============ Install Golang ============#
ENV GOPATH=${GOPATH:-/root/go}
ENV PATH=${GOPATH}/bin:$PATH
RUN set -eux; \
  mkdir -p ${GOPATH}; \
  chmod -R 777 ${GOPATH}; \
  yum -y install golang; \
  yum clean all; \
  rm -rf /var/cache/yum;
#============ ./Install Golang ==========#


#============ Install Javascript, Typescript ============#
# Install node and yarn
RUN set -eux; \
  curl --silent --location https://rpm.nodesource.com/setup_10.x | bash -; \
  yum install -y nodejs; \
  curl -sL https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo; \
  yum install -y yarn; \
  yum clean all; \
  rm -rf /var/cache/yum;

RUN set -eux; \
  # Install yarn packages
  yarn global add typescript parcel-bundler gulp bower neovim ts-node jest ts-jest tern;
#============ ./Install Javascript, Typescript ==========#


#============ ZSH Config ============#
# Install powerline fonts
RUN set -eux; \
  git clone https://github.com/powerline/fonts.git --depth=1 "${HOME}/fonts"; \
  ${HOME}/fonts/install.sh; \
  rm -rf "${HOME}/fonts";

# Install zsh
COPY . /root/.dotfiles/devbox
RUN set -eux; \
  yum install -y stow; \
  git clone https://github.com/tarjoilija/zgen.git "${HOME}/zgen"; \
  sed -i -e '/shasum -a 256/ s//sha256sum/g' ${HOME}/zgen/zgen.zsh; \
  mkdir -p "${HOME}/.dotfiles/zsh-quickstart-kit"; \
  git clone https://github.com/git-fork/zsh-quickstart-kit.git "${HOME}/.dotfiles/zsh-quickstart-kit"; \
  cd "${HOME}/.dotfiles/zsh-quickstart-kit"; \
  sed -i -e '/alias grep/d' ./zsh/.zsh_aliases; \
  stow --target="${HOME}" zsh; \
  cd ${HOME}; \
  git clone --depth 1 https://github.com/junegunn/fzf.git ${HOME}/.fzf; \
  ${HOME}/.fzf/install --all; \
  sed -i -e '1i\
  if type ssh-agent> /dev/null 2>&1; then\n\
  eval $(ssh-agent -s);\n\
  fi;\n\
  [ -f ~/.bash_profile ] && source ~/.bash_profile;\n\
  [ -f ~/.bash_extras ] && source ~/.bash_extras;\n\
  # bashrc may include bash specific commands which zsh may not support, hence not included\n\
  # [ -f ~/.bashrc ] && source ~/.bashrc;\n\
  DISABLE_UPDATE_PROMPT=true\n\
  export fpath=(/usr/local/share/zsh-completions $fpath)\n\
  # load zgen\n\
  source "${HOME}/zgen/zgen.zsh"\n\
  ' \
  -e "\$a\export PATH=$PATH:\$PATH;\n\
  unset QUICKSTART_KIT_REFRESH_IN_DAYS;\n\
  export HOMEBREW_NO_ANALYTICS=1;\n\
  export HOMEBREW_NO_AUTO_UPDATE=1;" ${HOME}/.dotfiles/zsh-quickstart-kit/zsh/.zshrc; \
  # symlink your local plugins
  cd "${HOME}/.dotfiles/devbox"; \
  stow --target="${HOME}" dotfiles; \
  cd "${HOME}"; \
  # change default shell
  sed -i -E 's/\/(b?a)?sh/\/zsh/' /etc/passwd; \
  # install zsh zgen packages
  /bin/zsh -c " \
  source ~/.zshrc; \
  zgen save;" \
  echo 'Zsh installed and configured'; \
  # Remove package Stow not required anymore
  yum erase -y stow; \
  yum clean all; \
  rm -rf /var/cache/yum;
#============ ./ZSH Config ==========#


#============ Install Spacevim ============#
# Install spacevim
RUN set -eux; \
  yum install -y neovim; \
  pip install --user neovim pipenv; \
  pip3 install --user neovim pipenv; \
  curl -sLf https://spacevim.org/install.sh | bash; \
  nvim --headless +'call dein#install()' +qall; \
  # ${HOME}/.SpaceVim.d/init.toml is coming from above zsh stow after "COPY . /root/.dotfiles/devbox" statement
  sed -i -e 's/\x27/"/g;' -e '/statusline_\(inactive_\)\?separator/ s/"[^"]\+"/"nil"/g;' ${HOME}/.SpaceVim.d/init.toml; \
  yum clean all; \
  rm -rf /var/cache/yum;
#============ ./Install Spacevim ==========#

#============ Install yq ============#
RUN set -eux; \
  go get gopkg.in/mikefarah/yq.v2; \
  ln -s ${GOPATH}/bin/yq.v2 ${GOPATH}/bin/yq; \
  echo "";
#============ ./Install yq ============#

#============ Install Haskell ============#
RUN set -eux; \
  curl -sSL https://get.haskellstack.org/ | sh -s - -f; \
  echo "";
#============ ./Install Haskell ============#

# #============ Install Linuxbrew ============#
# # Install Homebrew
# RUN groupadd --gid 1000 developer; \
#   useradd --uid 1000 --gid developer --shell /bin/zsh --create-home developer; \
#   echo 'developer ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers;
# 
# USER developer
# WORKDIR /home/developer
# ENV PATH=/home/developer/.linuxbrew/bin:/home/developer/.linuxbrew/sbin:/home/developer/.local/bin:$PATH \
#   SHELL=/bin/zsh \
#   USER=developer
# 
# RUN set -eux; \
#   git clone https://github.com/Homebrew/brew /home/developer/.linuxbrew/Homebrew; \
#   cd /home/developer/.linuxbrew; \
#   mkdir -p bin etc include lib opt sbin share var/homebrew/linked Cellar; \
#   ln -s ../Homebrew/bin/brew /home/developer/.linuxbrew/bin/; \
#   # chown -R developer: /home/developer/.linuxbrew; \
#   # chown -R developer: /usr/local; \
#   # chown -R developer: /var; \
#   echo "";
# 
# 
# # Install portable-ruby and tap homebrew/core.
# RUN HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_AUTO_UPDATE=1 brew tap homebrew/core \
# && rm -rf ~/.cache
# #============ ./Install Linuxbrew ============#
# 
