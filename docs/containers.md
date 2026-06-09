# Containers

Most tools run from **biocontainers** (Bioconda) images referenced directly in
each module, with a Singularity/Apptainer URL and a Docker fallback. Those need
no action.

A few tools have **no Bioconda recipe or official image** and ship as custom,
buildable containers under [`containers/`](../containers). Build and push these
once (to a registry your HPC can reach), then the pinned tags in the modules
resolve.

## Custom images

| Tool | Module | Dockerfile | Module tag |
|------|--------|-----------|------------|
| RATTLE (de novo) | `modules/local/rattle.nf` | `containers/rattle/` | `ebareke/rattle:1.0` |
| tailfindr (poly-A) | `modules/local/tailfindr.nf` | `containers/tailfindr/` | `ebareke/tailfindr:1.4` |
| nanoRMS (modifications) | `modules/local/nanorms.nf` | `containers/nanorms/` | `ebareke/nanorms:2.0` |

ELIGOS uses the author's image `piroonj/eligos2:v2.1.0` (no Bioconda); pin it to
an immutable digest on your system.

## Build & push

Pin each upstream `*_REF` build-arg to a commit SHA / release tag for
reproducibility, then build and push (replace `ebareke` with your registry):

```bash
docker build -t ebareke/rattle:1.0    --build-arg RATTLE_REF=<sha>    containers/rattle
docker build -t ebareke/tailfindr:1.4 --build-arg TAILFINDR_REF=<tag> containers/tailfindr
docker build -t ebareke/nanorms:2.0   --build-arg NANORMS_REF=<sha>   containers/nanorms
docker push ebareke/rattle:1.0
docker push ebareke/tailfindr:1.4
docker push ebareke/nanorms:2.0
```

### Apptainer / Singularity (HPC)

Nextflow pulls these Docker images automatically under `-profile apptainer`/
`singularity`. To pre-build SIF files:

```bash
apptainer build rattle_1.0.sif    docker://ebareke/rattle:1.0
apptainer build tailfindr_1.4.sif docker://ebareke/tailfindr:1.4
apptainer build nanorms_2.0.sif   docker://ebareke/nanorms:2.0
```

### Pinning to digests (recommended for production)

Once pushed, replace the tag with the immutable digest in the module, e.g.:

```groovy
container 'docker.io/ebareke/rattle@sha256:<digest>'
```

## Notes

- These three tools are **container-only** — they have no Bioconda package, so
  the `standard` (conda) profile cannot run them. Use `-profile docker`,
  `apptainer`, or `singularity`.
- Dorado is ONT-distributed (`ontresearch/dorado`, pinned by SHA in the module);
  it is not on Bioconda.
- The Quarto report image (`ghcr.io/quarto-dev/quarto`) renders HTML always and
  PDF only if a LaTeX/Typst engine is present.
