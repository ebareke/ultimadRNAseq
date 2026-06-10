#!/bin/bash
#SBATCH --job-name=directRNA-sgnex
#SBATCH --output=directRNA-sgnex_%j.log
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=48:00:00
#SBATCH --account=CHANGE_ME
## -----------------------------------
#
# Nextflow "head" job: it stays alive for the whole run and submits each
# pipeline task as its own SLURM job (executor = slurm, via -profile hpc).
# Submit with:  sbatch assets/run_sgnex.slurm
set -euo pipefail

# --- toolchain (adjust to your site: module load, or explicit paths) ----------
# module load Java/17 Nextflow Apptainer
export JAVA_HOME="${JAVA_HOME:-$HOME/.local/jdks/jdk-17.0.19+10/Contents/Home}"
export PATH="$JAVA_HOME/bin:$HOME/.local/bin:$PATH"

# --- caches on shared scratch (avoid $HOME quota; large genome download) -------
export NXF_HOME="${NXF_HOME:-$PWD/.nextflow}"
export NXF_APPTAINER_CACHEDIR="${NXF_APPTAINER_CACHEDIR:-$PWD/apptainer_cache}"
export NXF_OPTS='-Xms1g -Xmx4g'

PROJECT_DIR="${PROJECT_DIR:-$PWD}"
OUTDIR="${OUTDIR:-$PWD/results_sgnex}"

nextflow run "$PROJECT_DIR" \
    -profile sgnex,hpc \
    -resume \
    --outdir "$OUTDIR"

echo "directRNA SG-NEx run finished. Results: $OUTDIR"
