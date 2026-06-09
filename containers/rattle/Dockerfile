# RATTLE — reference-free ONT transcriptome reconstruction
# Upstream: https://github.com/comprehensivegenomics/RATTLE (no Bioconda recipe)
#
# Build (pin RATTLE_REF to a commit SHA for reproducibility):
#   docker build -t ebareke/rattle:1.0 \
#       --build-arg RATTLE_REF=<commit-sha> containers/rattle
#   docker push ebareke/rattle:1.0
FROM ubuntu:22.04

ARG RATTLE_REF=main

RUN apt-get update && apt-get install -y --no-install-recommends \
        git build-essential cmake zlib1g-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/comprehensivegenomics/RATTLE /opt/RATTLE \
    && cd /opt/RATTLE \
    && git checkout "${RATTLE_REF}" \
    && ./build.sh

ENV PATH="/opt/RATTLE:${PATH}"

# smoke test
RUN rattle --help >/dev/null 2>&1 || true
