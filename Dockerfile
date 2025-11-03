FROM almalinux:9

WORKDIR /workspace

# Install system dependencies
RUN dnf update -y && dnf install -y \
    gcc g++ make git \
    python3 python3-devel python3-pip \
    openssl-devel \
    zlib-devel \
    unzip \
    wget \
    which \
    ca-certificates \
    ncurses-devel \
    glibc-locale-source \
    && dnf clean all && rm -rf /var/cache/dnf

# Install lazygit
RUN cd /tmp && \
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') && \
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" && \
    tar xf lazygit.tar.gz lazygit && \
    install lazygit /usr/local/bin/ && \
    rm lazygit.tar.gz lazygit

# Set up UTF-8 locale
RUN localedef -c -i en_US -f UTF-8 en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install Erlang/OTP 28
RUN dnf install -y epel-release && \
    dnf install -y erlang erlang-erl_interface && \
    dnf clean all

# Install Elixir 1.17.3 for OTP 26 (compatible with ex_mcp)
RUN cd /tmp && \
    curl -L https://github.com/elixir-lang/elixir/releases/download/v1.17.3/elixir-otp-26.zip -o elixir.zip && \
    unzip elixir.zip && \
    mkdir -p /opt/elixir && \
    mv bin lib man /opt/elixir/ && \
    rm elixir.zip

ENV PATH="/opt/elixir/bin:${PATH}"

# Note: Blender will be installed via Pythonx/uv at runtime
# This allows proper dependency management and avoids conflicts

# Create development user
RUN useradd -m -s /bin/bash -G wheel bpyuser && \
    echo "bpyuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER bpyuser

# Install Hex non-interactively as bpyuser
RUN mix local.hex --force

ENV PATH="/home/bpyuser/.local/bin:${PATH}"
