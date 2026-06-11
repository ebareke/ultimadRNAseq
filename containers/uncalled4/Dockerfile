# uncalled4 — signal-to-reference alignment for ONT (spec §5.2)
# Upstream: https://github.com/skovaka/uncalled4 (PyPI: uncalled4; no Bioconda recipe)
#
# Build:
#   docker build -t ebareke/uncalled4:4.1.0 \
#       --build-arg UNCALLED4_VERSION=4.1.0 containers/uncalled4
#   docker push ebareke/uncalled4:4.1.0
FROM python:3.11-slim

ARG UNCALLED4_VERSION=4.1.0

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential zlib1g-dev libbz2-dev liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir "uncalled4==${UNCALLED4_VERSION}"

# smoke test
RUN uncalled4 --version
