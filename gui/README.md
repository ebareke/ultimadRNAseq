# directRNA GUI (results browser)

A standalone [Streamlit](https://streamlit.io) app for interactively browsing a
directRNA results directory (spec §7B). It is **not** part of the Nextflow
pipeline — run it after a pipeline run to explore outputs.

## Run

```bash
pip install -r gui/requirements.txt
streamlit run gui/app.py -- --results /path/to/results
```

Everything after `--` is passed to the app; `--results` points at the
pipeline's `--outdir`.

Or with a container:

```bash
docker run --rm -p 8501:8501 -v "$PWD/results:/results" \
    python:3.11-slim bash -c \
    "pip install -q streamlit pandas && streamlit run /app/app.py -- --results /results"
```

## Sections

| Tab | Reads from | Spec |
|-----|-----------|------|
| Overview | `pipeline_info/`, `report/`, `multiqc/` | §8, §11 |
| Quantification | `quantification/salmon/*/quant.sf`, `denovo/quantification/*` | §5.4, §5.7 |
| Modifications | `modifications/{m6anet,nanocompore,eligos,nanorms}/` | §5.5 |
| Poly(A) | `polya/{nanopolish,tailfindr}/` | §5.6 |
| De novo | `denovo/{rattle,stringtie}/` | §5.7 |

## Status

Scaffold — sections list and tabulate outputs. Marked `TODO(user)` in
`app.py` are the spots where interactive plots/visualisations are the natural
next step (TPM distributions, tail-length histograms, modification volcano
plots).
