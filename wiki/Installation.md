# Installation

## Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| Java | 17–21 (LTS) | Nextflow ≥24 rejects Java 8/11 |
| Nextflow | ≥24.04 | strict parser + `resourceLimits` |
| Container engine | Docker **or** Apptainer/Singularity | required for real tool runs |

Everything else (the bioinformatics tools) is provided per-process via
containers or conda — nothing to install globally.

## No-sudo bootstrap (e.g. older macOS / HPC without a modern JDK)

```bash
# 1. user-local Temurin 17 (pick aarch64 on Apple Silicon)
mkdir -p ~/.local/jdks && cd ~/.local/jdks
curl -sSL -o jdk.tar.gz \
  "https://api.adoptium.net/v3/binary/latest/17/ga/mac/x64/jdk/hotspot/normal/eclipse?project=jdk"
tar xzf jdk.tar.gz && rm jdk.tar.gz

# 2. current Nextflow launcher
mkdir -p ~/.local/bin && cd ~/.local/bin
curl -s https://get.nextflow.io | bash

# 3. point at the JDK
export JAVA_HOME=~/.local/jdks/jdk-17.0.19+10/Contents/Home   # adjust version
export PATH="$JAVA_HOME/bin:$HOME/.local/bin:$PATH"
nextflow -version
```

Add the two `export` lines to your shell profile to make them permanent.

## Get the pipeline

```bash
git clone https://github.com/ebareke/ultimadRNAseq.git
cd ultimadRNAseq
nextflow run . -profile test -stub-run --outdir results   # smoke test
```

## Custom containers

A few tools (RATTLE, tailfindr, nanoRMS) have no Bioconda recipe and ship as
buildable images under `containers/`. Build & push them once — see
[[Containers]].
