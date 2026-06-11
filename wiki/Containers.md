# Containers

Most tools use **biocontainers** referenced directly in each module — nothing to
do (including **RATTLE**, which is on Bioconda). Three tools have no Bioconda
recipe and ship as buildable images under `containers/`: **tailfindr**,
**nanoRMS** and **uncalled4**. ELIGOS uses the author's image `piroonj/eligos2`.

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
`TAILFINDR_REF=<tag> NANORMS_REF=<sha> ./containers/build_and_push.sh`

## Apptainer (HPC)

Bioconda tools use Galaxy-depot Singularity images directly under `-profile
apptainer`/`hpc`. For the custom tools, the **`Apptainer images (HPC)`**
workflow (`.github/workflows/apptainer.yml`) builds SIFs on GitHub, smoke-tests
each under Apptainer, and publishes them to **GHCR**:

```bash
apptainer pull oras://ghcr.io/ebareke/tailfindr-apptainer:1.4   # pre-seed HPC cache
```

Or build a SIF yourself from the Docker image:

```bash
apptainer build tailfindr_1.4.sif docker://ebareke/tailfindr:1.4
```

See [[HPC]] for the full HPC/Apptainer guide.

## Production pinning

Once pushed, replace the tag with an immutable digest in the module:
`container 'docker.io/ebareke/tailfindr@sha256:<digest>'`.

Full detail: `docs/containers.md`.
