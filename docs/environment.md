# Environment & toolchain

`directRNA` is a Nextflow DSL2 pipeline. It needs a modern Java and Nextflow;
everything else (bioinformatics tools) is provided per-process via containers
or conda and does **not** need to be installed globally.

## Requirements

| Component | Version           | Notes                                            |
|-----------|-------------------|--------------------------------------------------|
| Java      | 17–21 (LTS)       | Nextflow ≥24 refuses Java 8/11.                   |
| Nextflow  | ≥24.04            | We use the native `resourceLimits` directive.    |
| Container | Docker / Apptainer | One of them, unless running `-profile standard` (conda). |

## Bootstrapping on a machine without a modern JDK

This was the situation on the original dev machine (macOS 12, only Java 7/8
present, and Homebrew unable to build `openjdk` without newer Command Line
Tools). The no-sudo, no-system-change path:

```bash
# 1. User-local Temurin 17 JDK (x64 macOS shown; pick aarch64 on Apple Silicon)
mkdir -p ~/.local/jdks && cd ~/.local/jdks
curl -sSL -o temurin17.tar.gz \
  "https://api.adoptium.net/v3/binary/latest/17/ga/mac/x64/jdk/hotspot/normal/eclipse?project=jdk"
tar xzf temurin17.tar.gz && rm temurin17.tar.gz

# 2. A current Nextflow launcher (the OS-packaged one may be ancient and
#    hard-reject Java >8). This self-bootstraps the right distribution.
mkdir -p ~/.local/bin && cd ~/.local/bin
curl -s https://get.nextflow.io | bash

# 3. Point at the JDK and run
export JAVA_HOME=~/.local/jdks/jdk-17.0.19+10/Contents/Home   # adjust version
export PATH="$JAVA_HOME/bin:$HOME/.local/bin:$PATH"
nextflow -version
```

Make the env exports permanent by adding them to `~/.zshrc` / `~/.bash_profile`.

## Smoke test

```bash
nextflow run . -profile test,standard --outdir results
```

Expected: exits 0, prints a banner, and lists the 4 samples parsed from
`assets/samplesheet_test.csv`. Provenance HTML/TXT lands in
`results/pipeline_info/`.
