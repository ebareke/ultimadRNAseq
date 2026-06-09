# tailfindr — poly(A)/poly(U) tail estimation from raw ONT signal
# Upstream: https://github.com/adnaniazi/tailfindr (R package, no Bioconda recipe)
#
# Build (pin TAILFINDR_REF to a release tag or commit SHA):
#   docker build -t ebareke/tailfindr:1.4 \
#       --build-arg TAILFINDR_REF=<tag-or-sha> containers/tailfindr
#   docker push ebareke/tailfindr:1.4
FROM rocker/r-ver:4.3.2

ARG TAILFINDR_REF=master

RUN apt-get update && apt-get install -y --no-install-recommends \
        libhdf5-dev libxml2-dev libcurl4-openssl-dev libssl-dev \
        libfontconfig1-dev git \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('remotes','BiocManager'), repos='https://cloud.r-project.org')" \
    && R -e "BiocManager::install('rhdf5', ask=FALSE, update=FALSE)" \
    && R -e "remotes::install_github('adnaniazi/tailfindr@${TAILFINDR_REF}', upgrade='never')"

# smoke test
RUN R -e "library(tailfindr)"
