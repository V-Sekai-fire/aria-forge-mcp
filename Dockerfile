# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Build stage
FROM almalinux:9 AS builder

WORKDIR /app

# Install build dependencies
# Use --allowerasing to replace curl-minimal with curl if needed
RUN dnf update -y && dnf install -y --allowerasing \
    gcc g++ make git \
    python3 python3-devel python3-pip \
    openssl-devel \
    zlib-devel \
    unzip \
    wget \
    curl \
    which \
    ca-certificates \
    ncurses-devel \
    autoconf \
    automake \
    libtool \
    flex \
    m4

# Install Erlang/OTP 28 from source (required for :zstd support)
# OTP 28+ includes the built-in :zstd module
RUN cd /tmp && \
    curl -Lf https://github.com/erlang/otp/releases/download/OTP-28.0/otp_src_28.0.tar.gz -o otp.tar.gz && \
    tar -xzf otp.tar.gz && \
    cd otp_src_28.0 && \
    ./otp_build autoconf && \
    ./configure --prefix=/usr/local/erlang --without-javac && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf /tmp/otp* && \
    /usr/local/erlang/bin/erl -version && \
    /usr/local/erlang/bin/erl -eval 'io:format("OTP Release: ~s~n", [erlang:system_info(otp_release)]), halt().' -noshell

ENV PATH="/usr/local/erlang/bin:${PATH}"

# Install Elixir 1.19 from precompiled binaries (compatible with OTP 28)
RUN cd /tmp && \
    curl -Lf https://github.com/elixir-lang/elixir/releases/download/v1.19.2/elixir-otp-28.zip -o elixir.zip && \
    unzip -q elixir.zip && \
    mkdir -p /opt/elixir && \
    mv bin lib man /opt/elixir/ && \
    rm -rf elixir.zip && \
    /opt/elixir/bin/elixir --version

ENV PATH="/opt/elixir/bin:/usr/local/bin:${PATH}"
ENV ELIXIR_ERL_OPTIONS="+fnu"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy dependency files
COPY mix.exs mix.lock ./
COPY config ./config

# Install dependencies
RUN mix deps.get --only prod && \
    mix deps.compile

# Copy source code
COPY lib ./lib

# Compile the application
RUN MIX_ENV=prod mix compile

# Build the release
RUN MIX_ENV=prod mix release

# Runtime stage
FROM almalinux:9

WORKDIR /app

# Install runtime dependencies
# Note: Mix releases include ERTS, but we install Erlang from repos for compatibility
# Note: pythonx manages its own Python environment, so we don't need to install
#       Python packages here - they're bundled with the release
# Install Erlang/OTP 28 runtime libraries (same as builder, required for :zstd)
# Note: Mix releases include ERTS, so we only need runtime libraries for compatibility
RUN dnf update -y && \
    dnf install -y \
    openssl \
    ncurses-libs \
    libstdc++ \
    wget \
    ca-certificates \
    glibc-langpack-en && \
    localedef -c -i en_US -f UTF-8 en_US.UTF-8 || true && \
    dnf clean all

# Copy Erlang and Elixir installations from builder
COPY --from=builder /usr/local/erlang /usr/local/erlang
COPY --from=builder /opt/elixir /opt/elixir

ENV PATH="/opt/elixir/bin:/usr/local/erlang/bin:${PATH}"

# Note: Blender and Python dependencies are installed by pythonx during compilation
# No need to install them here as pythonx manages its own Python environment

# Copy the release from builder
COPY --from=builder /app/_build/prod/rel/aria_forge ./aria_forge

# Set environment variables
ENV MIX_ENV=prod
ENV MCP_TRANSPORT=http
ENV PORT=4000
ENV ELIXIR_ERL_OPTIONS="+fnu"
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Expose the port
EXPOSE 4000

# Start the server
CMD ["./aria_forge/bin/aria_forge", "start"]

