# Kaldi ASR for Apple Silicon (M1 / M2 / M3 / M4)

[![Build and Publish](https://github.com/tklwin/kaldi-apple-silicon/actions/workflows/docker-build.yml/badge.svg)](https://github.com/tklwin/kaldi-apple-silicon/actions/workflows/docker-build.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/tklwin/kaldi-apple-silicon.svg?logo=docker&color=blue)](https://hub.docker.com/r/tklwin/kaldi-apple-silicon)
[![Image Size](https://img.shields.io/docker/image-size/tklwin/kaldi-apple-silicon/latest?color=success)](https://hub.docker.com/r/tklwin/kaldi-apple-silicon)
[![Platform](https://img.shields.io/badge/platform-linux%2Farm64-brightgreen.svg)](https://hub.docker.com/r/tklwin/kaldi-apple-silicon)
[![Base](https://img.shields.io/badge/base-Debian%2012%20(Bookworm)-red.svg)](https://hub.docker.com/_/debian)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A high-performance, native **ARM64 (`aarch64`)** Docker environment for running and developing with [Kaldi ASR](https://github.com/kaldi-asr/kaldi) on **Apple Silicon Macs** (M1, M2, M3, M4) with **Colima** or Docker Desktop.

---

## 💡 Why This Repository?

The official Kaldi Docker images on Docker Hub (`kaldiasr/kaldi`) are strictly compiled for **Intel/AMD x86_64 architecture only**. 

When running standard Kaldi on Apple Silicon Macs, Docker is forced to run via **QEMU x86 emulation**, leading to:
* **3x–5x Slower Execution** and high CPU throttling.
* **Massive Memory Bloat**: Emulation requires significantly more host RAM.
* **Out-Of-Memory (OOM) Crashes**: OpenFST C++ template compilation easily crashes 8GB host Macs.
* **Missing Tool Paths**: Upstream images leave binary directories unexported.

### How This Image Solves It:

| Feature | Standard Kaldi (`kaldiasr/kaldi`) | `tklwin/kaldi-apple-silicon` |
| :--- | :--- | :--- |
| **Architecture** | `linux/amd64` (Emulated on Mac) | **`linux/arm64` (Native Apple Silicon)** |
| **Vector Acceleration** | Generic x86 SSE | **ARM NEON SIMD Vectorization with OpenBLAS** |
| **Download Size** | ~10 GB bloated | **~1.7 GB (Cleaned & Compact)** |
| **PATH Environment** | ❌ Manual setup required | ✅ **All 20+ Kaldi binary directories pre-configured** |
| **Audio & Python Stack** | Basic | ✅ Includes `Python 3.11`, `numpy`, `scipy`, `sox`, `sph2pipe`, `sclite` |
| **Build Stability** | ❌ Fails on upstream 404/403 URLs | ✅ **100% Hermetic & Reproducible with bundled tools** |

---

## ⚡ 10-Second Quick Start (Pre-built Image)

No local compilation required! You and your team can pull the pre-built image directly from Docker Hub or GitHub Container Registry:

### Pull & Run from Docker Hub:
```bash
docker run --rm -it \
  --name kaldi-session \
  -v "$(pwd)":/workspace \
  tklwin/kaldi-apple-silicon:latest
```

### Pull & Run from GitHub Container Registry (GHCR):
```bash
docker run --rm -it \
  --name kaldi-session \
  -v "$(pwd)":/workspace \
  ghcr.io/tklwin/kaldi-apple-silicon:latest
```

---

## 🧪 Verification & Health Check

Inside the container, test that the core Kaldi toolchains and libraries work:

```bash
# 1. Feature Extraction (MFCC & Filterbank)
compute-mfcc-feats --help
compute-fbank-feats --help

# 2. Acoustic Modeling & Alignment
gmm-info --help
gmm-init-mono --help

# 3. Deep Neural Networks (nnet3 & Chain)
nnet3-info --help
nnet3-latgen-faster --help

# 4. OpenFST Weighted Transducer Engine
fstcompile --help
fstinfo --help

# 5. NIST Scoring & Evaluation
sclite

# 6. SPHERE Audio Conversion
sph2pipe

# 7. Scientific Python Environment
python3 -c "import numpy, scipy; print('NumPy & SciPy OK!')"
```

---

## 💻 Running Speech Recognition Recipes (e.g. `egs/`)

1. Mount your speech project directory or dataset into `/workspace`:
   ```bash
   docker run --rm -it -v "$(pwd)":/workspace tklwin/kaldi-apple-silicon:latest
   ```
2. In any Kaldi recipe (e.g. `kaldi/egs/wsj/s5` or custom datasets), make sure `path.sh` points to `/opt/kaldi`:
   ```bash
   export KALDI_ROOT=/opt/kaldi
   export PATH=$PWD/utils/:$KALDI_ROOT/src/bin:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sctk/bin:$PATH
   export LC_ALL=C
   ```
3. Run standard Kaldi training and decoding scripts (`run.sh`).

---

## 🛠️ Building From Source Locally

If you prefer building the Docker image locally from source on your Mac:

### 1. Recommended Colima Configurations

[Colima](https://github.com/abiosoft/colima) is a fast, minimal, and open-source container runtime for macOS that provides significantly lower memory overhead on Apple Silicon compared to Docker Desktop. Install it via Homebrew: `brew install colima docker`.

* **For 8 GB RAM Macs (e.g. M1/M2/M3 Base):**
  ```bash
  colima start --cpu 4 --memory 4 --disk 30
  ```
* **For 16 GB+ RAM Macs (e.g. Pro/Max/M4):**
  ```bash
  colima start --cpu 6 --memory 10 --disk 40
  ```

### 2. Build Commands

* **On 8 GB RAM Mac (Safe single-threaded tools build to prevent OOM):**
  ```bash
  docker build -t kaldi-apple-silicon:local .
  ```
* **On 16 GB+ RAM Mac (Fast multi-threaded build in ~6–8 mins):**
  ```bash
  docker build --build-arg TOOLS_JOBS=4 --build-arg NUM_JOBS=8 -t kaldi-apple-silicon:local .
  ```

---

## 🚀 Cloud Auto-Build Architecture (CI/CD)

This repository is powered by **Docker Build Cloud** and **GitHub Actions** (`.github/workflows/docker-build.yml`).

* **Native ARM64 AWS Graviton Cluster**: Builds natively on 16-core cloud servers without slow QEMU emulation.
* **Hermetic Tool Bundles (`dependencies/`)**: Pre-packages exact versions of OpenFST 1.8.4, NIST SCTK 20159b5, sph2pipe 2.5, and CUB 1.8.0 to eliminate Cloudflare 403 blocks and outdated 404 URLs.
* **Auto-Cached Layers**: Cloud-shared BuildKit cache ensures incremental updates finish in under 1 minute.

---

## 📁 Repository Structure

```text
kaldi-apple-silicon/
├── Dockerfile                  # Production Debian 12 ARM64 recipe with OpenBLAS
├── dependencies/               # Pinned OpenFST, SCTK, sph2pipe, and CUB tarballs
├── .devcontainer/              # VS Code Dev Container & Codespaces config
│   └── devcontainer.json
├── .github/
│   └── workflows/
│       └── docker-build.yml    # High-speed Docker Build Cloud CI/CD workflow
├── .dockerignore               # Optimized Docker build context exclusions
├── LICENSE                     # Apache 2.0 Open Source License
└── README.md                   # Documentation and quickstart guide
```

---

## 📄 License

This project is licensed under the [Apache License 2.0](LICENSE) - aligned with the official [Kaldi ASR License](https://github.com/kaldi-asr/kaldi/blob/master/COPYING).
