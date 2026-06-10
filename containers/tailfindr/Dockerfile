# tailfindr — poly(A)/poly(U) tail estimation from raw ONT signal
# Upstream: https://github.com/adnaniazi/tailfindr (R package, no Bioconda recipe)
#
# Build (pin TAILFINDR_REF to a release tag or commit SHA):
#   docker build -t ebareke/tailfindr:1.4 \
#       --build-arg TAILFINDR_REF=<tag-or-sha> containers/tailfindr
#   docker push ebareke/tailfindr:1.4
FROM rocker/r-ver:4.3.2

ARG TAILFINDR_REF=master

# System libs:
#   libhdf5-dev + patch        -> hdf5r (CRAN) builds
#   libbz2-dev liblzma-dev     -> Rhtslib/Rsamtools (htslib) builds
#   libpng/jpeg/fontconfig     -> rbokeh / graphics
#   libxml2/curl/ssl/zlib      -> general
RUN apt-get update && apt-get install -y --no-install-recommends \
        libhdf5-dev patch \
        libbz2-dev liblzma-dev \
        libxml2-dev libcurl4-openssl-dev libssl-dev zlib1g-dev \
        libfontconfig1-dev libpng-dev libjpeg-dev \
        git \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('remotes','BiocManager'), repos='https://cloud.r-project.org')"

# hdf5r is a CRAN package (NOT rhdf5); needs libhdf5-dev + patch. Fail fast.
RUN R -e "install.packages('hdf5r', repos='https://cloud.r-project.org'); \
          if (!requireNamespace('hdf5r', quietly=TRUE)) quit(status=1)"

# Bioconductor deps (Rsamtools pulls Rhtslib → htslib). Fail fast.
RUN R -e "BiocManager::install(c('Biostrings','Rsamtools'), ask=FALSE, update=FALSE); \
          ok <- all(c('Biostrings','Rsamtools') %in% rownames(installed.packages())); \
          if (!ok) quit(status=1)"

# rbokeh was ARCHIVED from CRAN — install from GitHub so tailfindr can load
RUN R -e "remotes::install_github('bokeh/rbokeh', upgrade='never'); \
          if (!requireNamespace('rbokeh', quietly=TRUE)) quit(status=1)"

# tailfindr + remaining CRAN dependencies
RUN R -e "remotes::install_github('adnaniazi/tailfindr@${TAILFINDR_REF}', upgrade='never', dependencies=TRUE)"

# smoke test — must load cleanly
RUN R -e "library(tailfindr)"
