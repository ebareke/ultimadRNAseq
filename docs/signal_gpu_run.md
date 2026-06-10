# Signal + GPU run — POD5/FAST5 → Dorado → modifications & poly(A)

The full raw-signal run: basecalling with **Dorado on GPU**, signal-to-reference
event alignment with **f5c**, then **RNA modification** detection (m6anet,
Nanocompore, ELIGOS, nanoRMS) and **poly(A)** tail analysis (nanopolish,
tailfindr). Use this once you have raw signal and want the epitranscriptomic /
tail outputs that FASTQ entry cannot produce.

## Prerequisites

- HPC with SLURM, a **GPU partition**, and **Apptainer** (Dorado needs CUDA;
  Apptainer runs with `--nv` — set in `conf/signal.config`)
- **Java 17**, **Nextflow ≥24.04**
- Custom containers built & pushed (RATTLE/tailfindr/nanoRMS — see
  [containers.md](containers.md)); Dorado image (`ontresearch/dorado`)
- Raw signal as **POD5** (preferred) or **FAST5** (auto-converted to POD5)

## 1. Build the sample sheet

Copy `assets/samplesheet_signal.csv` and point each row at a sample's signal
directory (absolute paths). Columns that matter here:

| Column | Meaning |
|--------|---------|
| `pod5_dir` / `fast5_dir` | directory of raw signal for the sample |
| `kit` | `RNA004` or `RNA002` — drives the Dorado model |
| `condition` | grouping label |
| `control` | `true` marks the background/reference sample (IVT/untreated/KO); the comparative modification tools contrast each `control=false` (test) sample against the `control=true` sample(s) |

## 2. Pick the basecalling model

Set `--dorado_model` (or edit `conf/signal.config`) to match your chemistry,
e.g. `rna004_130bps_sup@v5.1.0` (RNA004) or an RNA002 model for older runs.

## 3. Configure the GPU resource

Edit `conf/signal.config` ▸ `withLabel: process_gpu`:

```groovy
clusterOptions = '--gres=gpu:1'   // your scheduler's GPU request
queue          = 'gpu'            // your GPU partition name
```

## 4. Launch

Edit the `#SBATCH --account`/`--partition` lines in
`assets/run_signal_gpu.slurm`, then:

```bash
sbatch assets/run_signal_gpu.slurm
```

Only the Dorado tasks land on the GPU partition; everything else uses CPU
partitions per the `process_*` labels.

## 5. Outputs (in addition to the reference-guided outputs)

```
results_signal/
├── signal/dorado/<sample>/         # uBAM + sequencing_summary.txt
├── signal/fastq/<sample>.fastq.gz  # basecalled reads (feed QC/align/quant)
├── signal/f5c/<sample>/
│   ├── transcriptome/              # eventalign → m6anet / Nanocompore
│   └── genome/                     # eventalign (generic)
├── modifications/{m6anet,nanocompore,eligos,nanorms}/
└── polya/{nanopolish,tailfindr}/
```

## Notes

- **Transcriptome eventalign** feeds m6anet/Nanocompore (transcript-coordinate
  calls); genome eventalign is also produced. ELIGOS and nanoRMS use the genome
  BAM (basecalling-error / per-read signal).
- nanopolish & tailfindr target **FAST5/SLOW5**; with POD5 input, retain FAST5
  or convert POD5→slow5 (or use f5c `poly-a`, the POD5-native alternative).
- Wiring can be checked without GPU/data first:
  `nextflow run . -profile test_signal -stub-run --outdir results`.
