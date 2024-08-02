#!/bin/bash

cat <<EOF > ~/.ssh/id_rsa
-----BEGIN OPENSSH PRIVATE KEY-----
$SSH_PRIVATE_KEY
-----END OPENSSH PRIVATE KEY-----
EOF
chmod 600 ~/.ssh/id_rsa
sudo service ssh start

# Zsh Installation
sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)"
printf "ZSH Installed"

# Task Installation
sh -c "$(curl --location https://taskfile.dev/install.sh)" -- -d -b .local && \
  echo "export PATH=\$PATH:~/.local" >> ~/.zshrc
printf "Task Installed"

# Coder Installation
curl -L https://coder.com/install.sh | sh
printf "Coder Installed"

# Go Installation
curl -o go.tar.gz https://dl.google.com/go/go1.22.4.linux-amd64.tar.gz && \
  sudo tar -C /usr/local -xzf go.tar.gz && \
  rm go.tar.gz && \
  echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.zshrc
printf "Go Installed"

# NVM Installation
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
printf "NVM Installed"

sudo chsh -s /usr/bin/zsh $USER

if [ -f /setup/setup-env.sh ]; then
  /setup/setup-env.sh
fi

