# Kaldi ASR for Apple Silicon

[![Build and Publish](https://github.com/tklwin/kaldi-apple-silicon/actions/workflows/docker-build.yml/badge.svg)](https://github.com/tklwin/kaldi-apple-silicon/actions/workflows/docker-build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/tklwin/kaldi-apple-silicon.svg?logo=docker&color=blue)](https://hub.docker.com/r/tklwin/kaldi-apple-silicon)
[![Image Size](https://img.shields.io/docker/image-size/tklwin/kaldi-apple-silicon/latest?color=success)](https://hub.docker.com/r/tklwin/kaldi-apple-silicon)
[![Platform](https://img.shields.io/badge/platform-linux%2Farm64-blue.svg)](https://hub.docker.com/r/tklwin/kaldi-apple-silicon)
[![Base](https://img.shields.io/badge/base-Debian%2012-lightgrey.svg)](https://hub.docker.com/_/debian)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A native **ARM64 (`aarch64`)** Docker container for [Kaldi ASR](https://github.com/kaldi-asr/kaldi), built for Apple Silicon Macs (M1, M2, M3, M4) running Docker Desktop or Colima.

---

## Overview

The [official Kaldi Docker repository](https://github.com/kaldi-asr/kaldi/tree/master/docker) and official [Docker Hub image (`kaldiasr/kaldi`)](https://hub.docker.com/r/kaldiasr/kaldi) are built exclusively for `linux/amd64` (x86_64). Running them on Apple Silicon relies on QEMU x86 emulation, which introduces significant CPU overhead, slower execution, and increased memory usage.

This repository provides an automated, reproducible Docker build targeting native ARM64 with OpenBLAS and ARM NEON vectorization.

### Key Highlights

* **Native ARM64**: Full NEON SIMD acceleration with OpenBLAS math libraries.
* **Compact Image**: Intermediate build files (`.o`, `.lo`, `.la`) are pruned, keeping the final image at ~1.57 GB.
* **Pre-configured PATH**: Includes all 20+ Kaldi binary directories (`featbin`, `gmmbin`, `nnet3bin`, `chainbin`, `latbin`, `fstbin`, `lmbin`, `ivectorbin`, `kwsbin`, `online2bin`) along with OpenFST, NIST SCTK (`sclite`), and `sph2pipe`.
* **Reproducible Dependencies**: Bundles verified source archives for OpenFST 1.8.4, SCTK, sph2pipe, and CUB to avoid upstream download failures and Cloudflare blocks.
* **Python Environment**: Includes Python 3.11 with NumPy and SciPy.

---

## Quick Start

Pull and run the pre-built image directly from Docker Hub or GitHub Container Registry:

### Docker Hub
```bash
docker run --rm -it -v "$(pwd)":/workspace tklwin/kaldi-apple-silicon:latest
```

### GitHub Container Registry (GHCR)
```bash
docker run --rm -it -v "$(pwd)":/workspace ghcr.io/tklwin/kaldi-apple-silicon:latest
```

The container starts in `/workspace`, which is mapped to your current working directory. Any files or models generated inside `/workspace` persist on your host machine.

---

## Comprehensive Verification

To verify that the core toolchains and libraries across all subsystems are operating properly, run the following health checks inside the container:

```bash
# 1. Feature Extraction (MFCC, Filterbank, CMVN)
compute-mfcc-feats --help
compute-fbank-feats --help
apply-cmvn --help

# 2. Acoustic Modeling & Alignment (GMM-HMM)
gmm-info --help
gmm-init-mono --help
gmm-align-compiled --help

# 3. Deep Neural Networks (nnet3 & LF-MMI Chain)
nnet3-info --help
nnet3-latgen-faster --help
chain-est-phone-lm --help

# 4. Language Modeling & Transducers (ARPA / FST)
arpa2fst --help
fstcompile --help
fstinfo --help
fstarcsort --help

# 5. NIST Scoring & Evaluation
sclite

# 6. SPHERE Audio Conversion
sph2pipe

# 7. Scientific Python Stack
python3 -c "import numpy as np, scipy; print(f'NumPy {np.__version__} & SciPy {scipy.__version__} OK')"
```

---

## Running Kaldi Recipes

1. Mount your project or dataset directory into the container:
   ```bash
   docker run --rm -it -v "$(pwd)":/workspace tklwin/kaldi-apple-silicon:latest
   ```

2. When running recipes (e.g. from `/opt/kaldi/egs/`), ensure `cmd.sh` is configured to use `run.pl` for local CPU processing:
   ```bash
   export train_cmd=run.pl
   export decode_cmd=run.pl
   ```

3. Ensure standard locale sorting is active (set by default in the container):
   ```bash
   export LC_ALL=C
   ```

---

## Building from Source

To build the Docker image locally on macOS:

### 1. Colima Setup (Recommended)

[Colima](https://github.com/abiosoft/colima) provides a lightweight container runtime on macOS with lower memory overhead than Docker Desktop.

* **For 8 GB RAM Macs:**
  ```bash
  colima start --cpu 4 --memory 4 --disk 30
  ```

* **For 16 GB+ RAM Macs:**
  ```bash
  colima start --cpu 6 --memory 10 --disk 40
  ```

### 2. Build Commands

* **Single-threaded build (safe for 8 GB RAM systems to prevent memory exhaustion):**
  ```bash
  docker build -t kaldi-apple-silicon:local .
  ```

* **Multi-threaded build (for 16 GB+ systems):**
  ```bash
  docker build --build-arg TOOLS_JOBS=4 --build-arg NUM_JOBS=8 -t kaldi-apple-silicon:local .
  ```

---

## Repository Structure

```text
kaldi-apple-silicon/
├── Dockerfile                  # Debian 12 ARM64 recipe with OpenBLAS
├── dependencies/               # Pinned OpenFST, SCTK, sph2pipe, and CUB tarballs
├── .devcontainer/              # VS Code Dev Container configuration
│   └── devcontainer.json
├── .github/
│   └── workflows/
│       └── docker-build.yml    # Docker Build Cloud CI/CD workflow
├── .dockerignore               # Build context exclusions
├── LICENSE                     # Apache 2.0 License
└── README.md                   # Documentation
```

---

## References

* Upstream Source Repository: [Kaldi ASR on GitHub](https://github.com/kaldi-asr/kaldi)
* Upstream Docker Source: [Kaldi Official Dockerfile Directory](https://github.com/kaldi-asr/kaldi/tree/master/docker)
* Upstream Docker Hub: [kaldiasr/kaldi on Docker Hub](https://hub.docker.com/r/kaldiasr/kaldi)
* Upstream Documentation: [Kaldi ASR Official Documentation](https://kaldi-asr.org/doc/)

---

## License

This project is licensed under the [Apache License 2.0](LICENSE), in alignment with the upstream [Kaldi ASR License](https://github.com/kaldi-asr/kaldi/blob/master/COPYING).
