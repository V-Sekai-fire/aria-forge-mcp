FROM almalinux:9 AS base

# Set environment variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install system dependencies
RUN dnf update -y && dnf install -y --allowerasing \
    gcc g++ make git \
    python3 python3-devel python3-pip \
    openssl-devel \
    zlib-devel \
    ncurses-devel \
    wget \
    curl \
    ca-certificates \
    unzip \
    && dnf clean all && rm -rf /var/cache/dnf

# Install Erlang from AlmaLinux repositories and Elixir manually
RUN dnf install -y epel-release && \
    dnf install -y erlang && \
    dnf clean all

# Install Elixir 1.19.2 from precompiled binaries (latest version)
RUN cd /tmp && \
    curl -L https://github.com/elixir-lang/elixir/releases/download/v1.19.2/elixir-otp-27.zip -o elixir.zip && \
    unzip elixir.zip && \
    mkdir -p /opt/elixir && \
    mv bin lib man /opt/elixir/ && \
    rm elixir.zip

ENV PATH="/opt/elixir/bin:${PATH}"

# Install Blender
RUN dnf install -y blender && dnf clean all

# Verify installations
RUN elixir --version && \
    erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell && \
    blender --version

# Builder stage - builds the release (sidecar that gets discarded)
FROM base AS builder

# Create build user
RUN groupadd -r bpybuilder && useradd -r -g bpybuilder bpybuilder

# Set working directory
WORKDIR /build

# Copy mix files first for better caching
COPY mix.exs mix.lock ./

# Change ownership
RUN chown -R bpybuilder:bpybuilder /build
USER bpybuilder

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Get dependencies
RUN mix deps.get --only prod

# Copy source code
COPY --chown=bpybuilder:bpybuilder . .

# Build the application
RUN mix compile --warnings-as-errors

# Create production release
RUN mix release --overwrite

# Runtime stage - minimal image for running the release
FROM almalinux:9 AS runtime

# Set environment variables
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV MIX_ENV=prod

# Create non-root user for security
RUN groupadd -r bpyuser && useradd -r -g bpyuser bpyuser

# Install only runtime dependencies (minimal) - no Erlang/Elixir needed for release
RUN dnf update -y && dnf install -y \
    python3 \
    ca-certificates \
    && dnf clean all && rm -rf /var/cache/dnf

# Set working directory
WORKDIR /app

# Copy the built release from builder stage (sidecar artifacts)
COPY --from=builder --chown=bpyuser:bpyuser /build/_build/prod/rel/bpy_mcp /app

# Switch to non-root user
USER bpyuser

# Expose port if HTTP server is used
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

# Default command - run the release
CMD ["bin/bpy_mcp", "start"]