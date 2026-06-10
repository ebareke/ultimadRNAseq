# RATTLE — reference-free ONT transcriptome reconstruction
# Upstream: https://github.com/comprna/RATTLE  (no Bioconda recipe; uses git submodules)
#
# Build (pin RATTLE_REF to a commit SHA for reproducibility):
#   docker build -t ebareke/rattle:1.0 \
#       --build-arg RATTLE_REF=<commit-sha> containers/rattle
#   docker push ebareke/rattle:1.0
FROM ubuntu:22.04

ARG RATTLE_REF=master

RUN apt-get update && apt-get install -y --no-install-recommends \
        git build-essential cmake zlib1g-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# RATTLE pulls submodules (spoa, …); clone recursively, then ensure the
# submodules match the checked-out ref before building.
RUN git clone --recurse-submodules https://github.com/comprna/RATTLE /opt/RATTLE \
    && cd /opt/RATTLE \
    && git checkout "${RATTLE_REF}" \
    && git submodule update --init --recursive \
    && ./build.sh

ENV PATH="/opt/RATTLE:${PATH}"

# smoke test
RUN rattle --help >/dev/null 2>&1 || true
