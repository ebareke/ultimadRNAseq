# nanoRMS — RNA modification stoichiometry from ONT data
# Upstream: https://github.com/novoalab/nanoRMS (scripts; no Bioconda recipe)
#
# Build (pin NANORMS_REF to a commit SHA):
#   docker build -t ebareke/nanorms:2.0 \
#       --build-arg NANORMS_REF=<commit-sha> containers/nanorms
#   docker push ebareke/nanorms:2.0
#
# NOTE: nanoRMS mixes Python and R tooling and expects specific input features.
# Adjust the entrypoint/wrapper to match the chosen nanoRMS workflow version.
FROM python:3.10-slim

ARG NANORMS_REF=master

RUN apt-get update && apt-get install -y --no-install-recommends \
        git r-base build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/novoalab/nanoRMS /opt/nanoRMS \
    && cd /opt/nanoRMS \
    && git checkout "${NANORMS_REF}" \
    && pip install --no-cache-dir numpy pandas scikit-learn scipy

# Provide a `nanoRMS` entrypoint on PATH (wrapper around the repo's scripts).
RUN printf '#!/usr/bin/env bash\nexec python /opt/nanoRMS/per_read/nanoRMS.py "$@"\n' \
        > /usr/local/bin/nanoRMS \
    && chmod +x /usr/local/bin/nanoRMS

ENV PATH="/opt/nanoRMS:${PATH}"
