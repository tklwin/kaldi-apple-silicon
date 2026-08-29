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

# Build Kaldi tools and core source with OpenBLAS
# 1. Pre-download dependencies directly with curl to bypass outdated/broken HTTP & 404 OpenSLR URLs in Kaldi Makefile
# 2. Compile tools (OpenFST, sctk, sph2pipe) and OpenBLAS
# 3. Add symlink compatibility for Kaldi's configure path lookup
# 4. Configure and compile Kaldi C++ shared libraries and binaries
# 5. Clean intermediate object files to keep image size compact
RUN cd /opt/kaldi/tools && \
    curl -fsSL -A "Mozilla/5.0" -o openfst-1.8.4.tar.gz https://www.openfst.org/twiki/pub/FST/FstDownload/openfst-1.8.4.tar.gz && \
    curl -fsSL -o sctk-20159b5.tar.gz https://github.com/usnistgov/SCTK/archive/20159b5.tar.gz && \
    curl -fsSL -o sph2pipe-2.5.tar.gz https://github.com/burrmill/sph2pipe/archive/2.5.tar.gz && \
    curl -fsSL -o cub-1.8.0.tar.gz https://github.com/NVlabs/cub/archive/1.8.0.tar.gz && \
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

# Configure Environment Variables & PATH for all Kaldi binaries
ENV KALDI_ROOT=/opt/kaldi
ENV PATH="${KALDI_ROOT}/src/bin:${KALDI_ROOT}/src/featbin:${KALDI_ROOT}/src/gmmbin:${KALDI_ROOT}/src/nnet3bin:${KALDI_ROOT}/src/lmbin:${KALDI_ROOT}/src/ivectorbin:${KALDI_ROOT}/src/kwsbin:${KALDI_ROOT}/src/online2bin:${KALDI_ROOT}/tools/openfst/bin:${KALDI_ROOT}/tools/sctk/bin:${PATH}"
ENV LC_ALL=C

# Default working directory for user projects
WORKDIR /workspace

CMD ["/bin/bash"]
