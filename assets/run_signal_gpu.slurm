#!/bin/bash
#SBATCH --job-name=directRNA-signal
#SBATCH --output=directRNA-signal_%j.log
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=72:00:00
## --- EDIT for your cluster ---
#SBATCH --account=CHANGE_ME
#SBATCH --partition=CHANGE_ME
## -----------------------------
#
# Nextflow "head" job for the full signal run (POD5/FAST5 → Dorado → f5c →
# modifications + poly(A)). The head job itself needs NO GPU; the Dorado
# (process_gpu) tasks request a GPU via `--gres=gpu:1` set in conf/signal.config
# (edit the GPU `queue`/partition there to match your cluster).
#
# Submit with:  sbatch assets/run_signal_gpu.slurm
set -euo pipefail

# module load Java/17 Nextflow Apptainer        # or use explicit paths:
export JAVA_HOME="${JAVA_HOME:-$HOME/.local/jdks/jdk-17.0.19+10/Contents/Home}"
export PATH="$JAVA_HOME/bin:$HOME/.local/bin:$PATH"

export NXF_HOME="${NXF_HOME:-$PWD/.nextflow}"
export NXF_APPTAINER_CACHEDIR="${NXF_APPTAINER_CACHEDIR:-$PWD/apptainer_cache}"
export NXF_OPTS='-Xms1g -Xmx4g'

PROJECT_DIR="${PROJECT_DIR:-$PWD}"
OUTDIR="${OUTDIR:-$PWD/results_signal}"

# Apptainer must run Dorado with --nv to expose the GPU inside the container.
nextflow run "$PROJECT_DIR" \
    -profile signal,hpc \
    -with-apptainer \
    -resume \
    --outdir "$OUTDIR"

echo "directRNA signal run finished. Results: $OUTDIR"
