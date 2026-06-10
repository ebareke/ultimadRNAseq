# nanoRMS — RNA modification stoichiometry from ONT data
# Upstream: https://github.com/novoalab/nanoRMS (scripts; no Bioconda recipe,
# no single CLI — the per-read workflow is get_features.py → get_freq.py).
#
# Build (pin NANORMS_REF to a commit SHA):
#   docker build -t ebareke/nanorms:2.0 \
#       --build-arg NANORMS_REF=<commit-sha> containers/nanorms
#   docker push ebareke/nanorms:2.0
#
# NOTE: nanoRMS is a collection of scripts, not a unified tool. The `nanoRMS`
# shim below dispatches to per_read/get_features.py; adapt it (and the NANORMS
# Nextflow module) to the exact nanoRMS workflow you run.
FROM python:3.10-slim

ARG NANORMS_REF=master

RUN apt-get update && apt-get install -y --no-install-recommends \
        git r-base build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/novoalab/nanoRMS /opt/nanoRMS \
    && cd /opt/nanoRMS \
    && git checkout "${NANORMS_REF}" \
    && pip install --no-cache-dir numpy pandas scikit-learn scipy h5py pysam

# `nanoRMS` shim → a real script in the repo (per-read feature extraction)
RUN printf '#!/usr/bin/env bash\nexec python /opt/nanoRMS/per_read/get_features.py "$@"\n' \
        > /usr/local/bin/nanoRMS \
    && chmod +x /usr/local/bin/nanoRMS

ENV PATH="/opt/nanoRMS/per_read:/opt/nanoRMS:${PATH}"

# smoke test
RUN test -f /opt/nanoRMS/per_read/get_features.py
