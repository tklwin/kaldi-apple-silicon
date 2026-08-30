# ==============================================================================
# Native Kaldi ASR Dockerfile for Apple Silicon (ARM64)
# Supports: M1, M2, M3, M4 Macs (8GB, 16GB, 24GB, 32GB+ RAM)
# Base: Debian 12 (Bookworm) with OpenBLAS and ARM NEON SIMD Vectorization
# ==============================================================================

FROM debian:12-slim

LABEL maintainer="tklwin"
LABEL org.opencontainers.image.title="Kaldi ASR for Apple Silicon"
LABEL org.opencontainers.image.description="Native ARM64 Kaldi ASR container for macOS Apple Silicon with OpenBLAS and Python support"
LABEL org.opencontainers.image.source="https://github.com/tklwin/kaldi-apple-silicon"

# Prevent interactive prompts during apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Install essential compilation tools, libraries, audio utilities, and Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        g++ \
        gfortran \
        make \
        automake \
        autoconf \
        bzip2 \
        unzip \
        wget \
        curl \
        sox \
        libtool \
        git \
        python3 \
        python3-pip \
        python3-numpy \
        python3-scipy \
        zlib1g-dev \
        libopenblas-dev \
        ca-certificates \
        patch \
        python-is-python3 \
        procps \
        tree && \
    rm -rf /var/lib/apt/lists/*

# Number of parallel compilation jobs
# Default is 2 (safe for CI and 8GB machines). Can be overridden via --build-arg
ARG TOOLS_JOBS=2
ARG NUM_JOBS=4

# Clone Kaldi official repository
RUN git clone --depth 1 https://github.com/kaldi-asr/kaldi.git /opt/kaldi

# Copy pre-verified tool dependencies directly (bypasses all external network/firewall issues)
COPY dependencies/* /opt/kaldi/tools/

# Build Kaldi tools and core source with OpenBLAS
# 1. Compile tools (OpenFST, sctk, sph2pipe) and OpenBLAS
# 2. Add symlink compatibility for Kaldi's configure path lookup
# 3. Configure and compile Kaldi C++ shared libraries and binaries
# 4. Clean intermediate object files to keep image size compact
RUN cd /opt/kaldi/tools && \
    ./extras/install_openblas.sh && \
    make -j ${TOOLS_JOBS} && \
    mkdir -p /opt/kaldi/tools/extras && \
    ln -sf /opt/kaldi/tools/OpenBLAS /opt/kaldi/tools/extras/OpenBLAS && \
    cd /opt/kaldi/src && \
    ./configure --shared --mathlib=OPENBLAS --openblas-root=/opt/kaldi/tools/OpenBLAS/install && \
    make depend -j ${TOOLS_JOBS} && \
    make -j ${NUM_JOBS} && \
    find /opt/kaldi/src -type f -name "*.o" -delete && \
    rm -rf /opt/kaldi/.git

# Configure Comprehensive Environment Variables & PATH for all Kaldi binary toolchains
ENV KALDI_ROOT=/opt/kaldi
ENV PATH="${KALDI_ROOT}/src/bin:${KALDI_ROOT}/src/featbin:${KALDI_ROOT}/src/gmmbin:${KALDI_ROOT}/src/fgmmbin:${KALDI_ROOT}/src/sgmm2bin:${KALDI_ROOT}/src/latbin:${KALDI_ROOT}/src/nnetbin:${KALDI_ROOT}/src/nnet2bin:${KALDI_ROOT}/src/nnet3bin:${KALDI_ROOT}/src/chainbin:${KALDI_ROOT}/src/rnnlmbin:${KALDI_ROOT}/src/lmbin:${KALDI_ROOT}/src/fstbin:${KALDI_ROOT}/src/ivectorbin:${KALDI_ROOT}/src/kwsbin:${KALDI_ROOT}/src/onlinebin:${KALDI_ROOT}/src/online2bin:${KALDI_ROOT}/tools/openfst/bin:${KALDI_ROOT}/tools/sctk/bin:${KALDI_ROOT}/tools/sph2pipe_v2.5:${PATH}"
ENV LC_ALL=C

# Default working directory for user projects
WORKDIR /workspace

CMD ["/bin/bash"]
