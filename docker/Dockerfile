# ============================================
# Maximus Core - Production Dockerfile
# Multi-stage build for minimal image size
# ============================================

# syntax=docker/dockerfile:1.4

# ============================================
# Stage 1: Builder
# Build maximusd from source with depends
# ============================================
FROM ubuntu:jammy AS builder

# Install build dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  build-essential \
  libtool \
  autotools-dev \
  automake \
  pkg-config \
  bsdmainutils \
  python3 \
  bison \
  curl \
  ca-certificates \
  wget \
  git \
  autoconf \
  ccache \
  libboost-dev \
  libboost-filesystem-dev \
  libboost-system-dev \
  libboost-test-dev \
  libevent-dev \
  libminiupnpc-dev \
  libnatpmp-dev \
  libsqlite3-dev \
  libzmq3-dev \
  libgmp-dev \
  libsodium-dev \
  libssl-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /home/maximus

# Copy entire repository
COPY . .

# Build depends system
ARG TARGETPLATFORM
ENV USE_BUILD_DEPENDS=1
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
  make HOST=aarch64-linux-gnu -j$(nproc) || true; \
  else \
  make HOST=x86_64-pc-linux-gnu -j$(nproc) || true; \
  fi

# Configure and build maximusd
ENV PATH="/usr/lib/ccache:$PATH"
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
  ./autogen.sh && \
  ./configure --prefix=/usr/local \
  --enable-static \
  --disable-shared \
  --with-gui=no \
  --without-miniupnpc \
  --without-natpmp \
  --disable-bench \
  --disable-tests \
  --enable-reduce-exports \
  CXXFLAGS="-static-libstdc++"; \
  else \
  ./autogen.sh && \
  ./configure --prefix=/usr/local \
  --enable-static \
  --disable-shared \
  --with-gui=no \
  --without-miniupnpc \
  --without-natpmp \
  --disable-bench \
  --disable-tests \
  --enable-reduce-exports \
  CXXFLAGS="-static-libstdc++"; \
  fi

RUN make -j$(nproc)

# Create staging directory with binaries
RUN mkdir -p /build-output && \
  cp src/maximusd src/maximus-cli src/maximus-tx /build-output/ 2>/dev/null || \
  cp src/maximusd src/maximus-cli /build-output/; \
  strip /build-output/*

# ============================================
# Stage 2: Runtime
# Minimal image with only necessary binaries
# ============================================
FROM ubuntu:jammy AS runtime

LABEL maintainer="Maximus Developers <dev@maximus.org>"
LABEL description="Maximus Core node daemon for blockchain operations"
LABEL org.opencontainers.image.source="https://github.com/Maximus-Chain/maximus"

# Security labels
USER root

# Create non-root user for running daemon
ARG USER_ID=1000
ARG GROUP_ID=1000

ENV USER_ID=${USER_ID:-1000}
ENV GROUP_ID=${GROUP_ID:-1000}
ENV HOME=/home/maximus
ENV DATA_DIR=/home/maximus/.maximuscore

RUN groupadd -g ${GROUP_ID} maximus && \
  useradd -u ${USER_ID} -g maximus -s /bin/bash -m -d /home/maximus maximus && \
  mkdir -p ${DATA_DIR} && \
  chown ${USER_ID}:${GROUP_ID} -R /home/maximus

# Install runtime dependencies only
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  netcat \
  libboost-system1.74.0 \
  libboost-filesystem1.74.0 \
  libevent-2.1-7 \
  libevent-pthreads-2.1-7 \
  libminiupnpc17 \
  libnatpmp1 \
  libsqlite3-0 \
  libzmq5 \
  libgmp10 \
  libsodium23 \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get clean \
  && rm -rf /var/cache/apt/archives/*

# Copy binaries from builder
COPY --from=builder /build-output/* /usr/local/bin/

# Copy entrypoint and healthcheck scripts
COPY docker/entrypoint.sh /docker-entrypoint.sh
COPY docker/healthcheck.sh /usr/local/bin/healthcheck.sh

# Set permissions before switching to non-root user
RUN chmod +x /docker-entrypoint.sh /usr/local/bin/healthcheck.sh

# Create required directories
RUN mkdir -p ${DATA_DIR} && \
  chown maximus:maximus ${DATA_DIR}

# Volume for persistent data
VOLUME ["${DATA_DIR}"]

# Expose P2P and RPC ports (mainnet + testnet)
# Mainnet: P2P=9939, RPC=9938
# Testnet: P2P=19939, RPC=19938
EXPOSE 9938 9939 19938 19939

# Set working directory
WORKDIR /home/maximus

# Switch to non-root user
USER maximus

# Health check - determine port based on network
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh

# Default entrypoint
ENTRYPOINT ["/docker-entrypoint.sh"]
