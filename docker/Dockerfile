FROM ubuntu:jammy 

# Install baseline packages
RUN apt-get update && \
    apt-get install --no-install-recommends --yes \
    apt-transport-https \
    bash \
    bash-completion \
    build-essential \
    ca-certificates \
    cifs-utils \
    curl \
    dmidecode \
    gnupg-agent \
    gpg \
    htop \
    iputils-ping \
    jq \
    lm-sensors \
    locales \
    man \
    nano \
    openssh-server \
    p7zip-full \
    pciutils \
    python3 \
    python3-pip \
    software-properties-common \
    sudo \
    unzip \
    util-linux \
    vim \
    wget \
    rsync \
    && \
# Install latest Git using their official PPA
    add-apt-repository ppa:git-core/ppa && \
    apt-get install --yes git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN apt-key fingerprint 0EBFCD88
RUN add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) \
      stable"
RUN apt-get update && apt-get install --no-install-recommends -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# SSH server configuration
ARG SSHD_PORT=2222
RUN sed -i \
    -e "s/^#\(Port\) .*/\1 ${SSHD_PORT}/" \ 
    /etc/ssh/sshd_config && \
    mkdir /run/sshd

RUN systemctl enable ssh

EXPOSE ${SSHD_PORT}

# Ansible installation
RUN UBUNTU_CODENAME=jammy && \
  wget -O- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list && \
  apt-get update && \
  apt-get install ansible -y

# Make typing unicode characters in the terminal work.
ENV LANG=en_US.UTF-8
ARG USER=coder


# Setup the entrypoint
ARG CODER_INIT_SCRIPT="echo 'Hello from Coder!'"
ARG SETUP_ENV_SCRIPT_B64=""
RUN mkdir -p /setup 
COPY ./scripts/additional-entrypoint.sh /setup/additional-entrypoint.sh
RUN \
  echo "${CODER_INIT_SCRIPT}" > /setup/entrypoint.sh && \
  sed -i "1a sudo bash /setup/additional-entrypoint.sh" /setup/entrypoint.sh && \
  echo "${SETUP_ENV_SCRIPT_B64}" | base64 --decode >> /setup/setup-env.sh
  

# Create a non-root user
RUN useradd --groups sudo --no-create-home --shell /bin/bash ${USER} \
	&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} \
	&& chmod 0440 /etc/sudoers.d/${USER} \
  && sudo usermod -aG docker ${USER}

RUN chown -R ${USER}:${USER} /setup && \
  chmod +x /setup/*.sh

USER ${USER}
WORKDIR /home/${USER}

# Setup user home directory and SSH keys
COPY ssh .ssh
ARG WORKSPACE_FILE_B64=""
RUN echo "${WORKSPACE_FILE_B64}" | base64 --decode >> workspace.code-workspace && \
  sudo chown -R ${USER}:${USER} workspace.code-workspace && \
  sudo chown -R ${USER}:${USER} .ssh && \
  sudo chmod 700 .ssh && \
  sudo chmod 600 .ssh/*

VOLUME [ "/mnt/dev" ]

ENTRYPOINT ["/setup/entrypoint.sh"]