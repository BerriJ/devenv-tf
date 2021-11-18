FROM ubuntu:focal@sha256:626ffe58f6e7566e00254b638eb7e0f3b11d4da9675088f4781a50ae288f3322

SHELL ["/bin/bash", "-c"]

ENV DISPLAY=:0 \
    TZ=Europe/Berlin

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG DEBIAN_FRONTEND=noninteractive

# Add non root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -rm -d /home/$USERNAME -s /bin/bash -g root --uid $USER_UID --gid $USER_GID $USERNAME \
    && addgroup $USERNAME staff

# Create folders to mount extensions
RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
    /home/$USERNAME/.vscode-server-insiders/extensions \
    && chown -R $USERNAME \
    /home/$USERNAME/.vscode-server \
    /home/$USERNAME/.vscode-server-insiders

# Ubuntu Setup
RUN apt-get update &&\
    apt-get -y --no-install-recommends install \
    ca-certificates \
    git \
    build-essential \
    netbase \
    zip \
    unzip \
    xclip \
    zsh \
    gnupg2 \
    nano \
    ssh-client \
    locales &&\
    locale-gen en_US.UTF-8 &&\
    locale-gen de_DE.UTF-8 &&\
    update-locale LANG=en_US.UTF-8 &&\
    git clone --depth=1 https://github.com/sindresorhus/pure.git /home/$USERNAME/.zsh/pure \
    && rm -rf /home/$USERNAME/.zsh/pure/.git \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/*

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8

# Install Python
COPY package_lists/python_packages.txt /package_lists/python_packages.txt

RUN apt-get update &&\
    apt-get -y --no-install-recommends install python3-pip && \
    # Python packages
    pip3 install -U --no-cache-dir \
    $(grep -o '^[^#]*' package_lists/python_packages.txt | tr '\n' ' ')  \
    && apt-get autoremove -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/*

# Set PATH for user installed python packages
ENV PATH="/home/vscode/.local/bin:${PATH}"

COPY --chown=$USERNAME .misc/.zshrc /home/$USERNAME/.
COPY --chown=$USERNAME .misc/.Rprofile /home/$USERNAME/.

# Switch to non-root user
USER $USERNAME

# Set the default shell to zsh rather than bash
ENTRYPOINT [ "/bin/zsh" ]