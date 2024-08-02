FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# Install the Docker apt repository
RUN apt-get update && \
    apt-get upgrade --yes && \
    apt-get install --yes ca-certificates && \
    rm -rf /var/lib/apt/lists/*
COPY docker-install/docker-archive-keyring.gpg /usr/share/keyrings/docker-archive-keyring.gpg
COPY docker-install/docker.list /etc/apt/sources.list.d/docker.list

# Install baseline packages
RUN apt-get update && \
    apt-get install --yes \
    bash \
    bash-completion \
    build-essential \
    ca-certificates \
    cifs-utils \
    containerd.io \
    curl \
    docker-ce \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin \
    dmidecode \
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
    systemd \
    systemd-sysv \
    unzip \
    util-linux \
    vim \
    wget \
    rsync \
    socat && \
# Install latest Git using their official PPA
    add-apt-repository ppa:git-core/ppa && \
    apt-get install --yes git \
    && rm -rf /var/lib/apt/lists/*

# Enables Docker starting with systemd
RUN systemctl enable docker

# Create a symlink for standalone docker-compose usage
RUN ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# SSH server configuration
ARG SSHD_PORT=2222
RUN sed -i \
    -e "s/^#\(Port\) .*/\1 ${SSHD_PORT}/" \ 
    /etc/ssh/sshd_config && \
    mkdir /run/sshd

RUN systemctl enable ssh

EXPOSE ${SSHD_PORT}

# Make typing unicode characters in the terminal work.
ENV LANG=en_US.UTF-8
ARG USER=coder


# Setup the entrypoint
ARG CODER_INIT_SCRIPT="echo 'Hello from Coder!'"
ARG SETUP_ENV_SCRIPT="echo 'Setting up environment...'" 
RUN mkdir /setup && \
  echo "${CODER_INIT_SCRIPT}" > /setup/entrypoint.sh && \
  echo "${SETUP_ENV_SCRIPT}" > /setup/setup-env.sh
  # sed -i "1a sudo socat UNIX-LISTEN:/var/run/docker.sock,fork,mode=660,user=${USER} UNIX-CONNECT:/var/run/docker-host.sock &" /setup/entrypoint.sh && \

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
ARG WORKSPACE_FILE="{}"
RUN echo "${WORKSPACE_FILE}" > workspace.code-workspace && \
  sudo chown -R ${USER}:${USER} workspace.code-workspace && \
  sudo chown -R ${USER}:${USER} .ssh && \
  sudo chmod 700 .ssh && \
  sudo chmod 600 .ssh/*

VOLUME [ "/mnt/dev" ]

ENTRYPOINT ["/setup/entrypoint.sh"]