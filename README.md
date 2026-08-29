# Kaldi ASR for Apple Silicon (M1 / M2 / M3 / M4)

[![Docker Image](https://img.shields.io/badge/docker%20hub-tklwin%2Fkaldi--apple--silicon-blue.svg?logo=docker)](https://hub.docker.com/r/tklwin/kaldi-apple-silicon)
[![Platform](https://img.shields.io/badge/platform-linux%2Farm64-brightgreen.svg)](https://hub.docker.com/r/tklwin/kaldi-apple-silicon)
[![Base](https://img.shields.io/badge/base-Debian%2012%20(Bookworm)-red.svg)](https://hub.docker.com/_/debian)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

A high-performance, native **ARM64** Docker environment for running and developing with [Kaldi ASR](https://github.com/kaldi-asr/kaldi) on **Apple Silicon Macs** (M1, M2, M3, M4) with **Colima** or Docker Desktop.

---

## 💡 Why This Repository?

| Challenge with Standard Kaldi | How This Image Solves It |
| :--- | :--- |
| **Intel x86 Emulation** (`kaldiasr/kaldi:latest`) | Compiles natively for **ARM64 (`aarch64`)** with **ARM NEON SIMD vectorization** for zero emulation overhead and maximum CPU efficiency. |
| **Out-Of-Memory (OOM) Crash** | Controls OpenFST C++ template compilation concurrency to stay safely within memory limits on 8GB host Macs. |
| **OpenBLAS Path Bug** | Automatically fixes Kaldi's `./configure` path lookup bug for OpenBLAS. |
| **Manual Configuration** | Automatically exports all Kaldi binary directories (`featbin`, `gmmbin`, `nnet3bin`, `openfst`, `sctk`) directly into `PATH`. Includes Python 3, `numpy`, `scipy`, and `sox`. |

---

## ⚡ 10-Second Quick Start (Pre-built Image)

No local compilation required! You and your team can pull the pre-built image directly from Docker Hub or GitHub Container Registry:

### From Docker Hub:
```bash
docker run --rm -it \
  --name kaldi-session \
  -v "$(pwd)":/workspace \
  tklwin/kaldi-apple-silicon:latest
```

### From GitHub Container Registry (GHCR):
```bash
docker run --rm -it \
  --name kaldi-session \
  -v "$(pwd)":/workspace \
  ghcr.io/tklwin/kaldi-apple-silicon:latest
```

---

## 🛠️ Local Build Instructions

If you prefer building the Docker image locally from source on your Mac:

### 1. Start Colima

* **For 8 GB RAM Macs (e.g. M2):**
  ```bash
  colima start --cpu 4 --memory 4 --disk 30
  ```
* **For 16 GB+ RAM Macs (e.g. M4):**
  ```bash
  colima start --cpu 6 --memory 10 --disk 40
  ```

### 2. Build

* **On 8 GB RAM Mac (Safe single-threaded tools build to avoid OOM):**
  ```bash
  docker build -t kaldi-apple-silicon:local .
  ```

* **On 16 GB+ RAM Mac (Fast multi-threaded build in ~6–8 mins):**
  ```bash
  docker build --build-arg TOOLS_JOBS=4 --build-arg NUM_JOBS=6 -t kaldi-apple-silicon:local .
  ```

---

## 🧪 Verification & Sanity Check

Inside the container, test that the core Kaldi binaries and shared libraries work:

```bash
# 1. Test Feature Extraction (MFCC)
compute-mfcc-feats --help

# 2. Test OpenFST Finite State Transducer Compiler
fstcompile --help

# 3. Test Gaussian Mixture Model (GMM) Tool
gmm-info --help
```

---

## 🚀 Setting up GitHub Cloud Auto-Build (CI/CD)

This repository includes a GitHub Actions workflow (`.github/workflows/docker-build.yml`) that automatically builds and publishes the ARM64 image to Docker Hub and GHCR on every push.

### Configuration Steps:
1. Push this repository to your GitHub account:
   ```bash
   git init
   git add .
   git commit -m "feat: native kaldi for apple silicon"
   git remote add origin https://github.com/<your-username>/kaldi-apple-silicon.git
   git push -u origin main
   ```
2. Go to your repository on GitHub $\rightarrow$ **Settings** $\rightarrow$ **Secrets and variables** $\rightarrow$ **Actions** $\rightarrow$ **New repository secret**:
   * `DOCKERHUB_USERNAME`: Your Docker Hub username (e.g., `tklwin`)
   * `DOCKERHUB_TOKEN`: Your Docker Hub Personal Access Token (created at [hub.docker.com](https://hub.docker.com/settings/security))
3. Whenever you push changes or trigger the workflow manually under the **Actions** tab, GitHub will build the ARM64 container in the cloud and update your Docker Hub repository.

---

## 💻 Running Speech Recognition Recipes (e.g., `egs/`)

1. Mount your local speech project directory into `/workspace`:
   ```bash
   docker run --rm -it -v "$(pwd)":/workspace tklwin/kaldi-apple-silicon:latest
   ```
2. In any Kaldi recipe (e.g., `kaldi/egs/xbmu_amdo31/s5`):
   * Ensure `path.sh` points to `/opt/kaldi`:
     ```bash
     export KALDI_ROOT=/opt/kaldi
     . $KALDI_ROOT/tools/env.sh
     export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$KALDI_ROOT/tools/sctk/bin:$PWD:$PATH
     . $KALDI_ROOT/tools/config/common_path.sh
     export LC_ALL=C
     ```
3. Run standard Kaldi training scripts (`run.sh`).

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
