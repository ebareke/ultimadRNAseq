# Containers

Most tools use **biocontainers** referenced directly in each module — nothing to
do. Three tools have no Bioconda recipe and ship as buildable images under
`containers/`: **RATTLE**, **tailfindr**, **nanoRMS**. ELIGOS uses the author's
image `piroonj/eligos2`.

## Build & push (automated — recommended)

A GitHub Actions workflow builds and pushes all three to Docker Hub. Add two
repository secrets (Settings ▸ Secrets and variables ▸ Actions):

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USERNAME` | your Docker Hub user |
| `DOCKERHUB_TOKEN` | a Docker Hub access token — **never commit it** |

Then run **Actions ▸ Build & push containers ▸ Run workflow**
(`.github/workflows/containers.yml`).

## Build & push (local)

```bash
export DOCKERHUB_USERNAME=ebareke
export DOCKERHUB_TOKEN=<your-token>      # export; never paste into a file
./containers/build_and_push.sh           # PUSH=false to build only
```

Pin upstream refs for reproducibility:
`RATTLE_REF=<sha> TAILFINDR_REF=<tag> NANORMS_REF=<sha> ./containers/build_and_push.sh`

## Apptainer (HPC)

Nextflow pulls these Docker images automatically under `-profile apptainer`.
Pre-build SIFs if you prefer:

```bash
apptainer build rattle_1.0.sif docker://ebareke/rattle:1.0
```

## Production pinning

Once pushed, replace the tag with an immutable digest in the module:
`container 'docker.io/ebareke/rattle@sha256:<digest>'`.

Full detail: `docs/containers.md`.
