"""
directRNA — results browser (Streamlit GUI)

A standalone viewer for a directRNA `--outdir` results directory. It is NOT part
of the Nextflow DAG; run it after a pipeline run to explore outputs interactively.

    streamlit run gui/app.py -- --results /path/to/results

(Everything after `--` is passed to this script.)
"""

from __future__ import annotations

import argparse
import gzip
from pathlib import Path

import pandas as pd
import streamlit as st


# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #
def get_results_dir() -> Path:
    parser = argparse.ArgumentParser()
    parser.add_argument("--results", default="results", help="pipeline --outdir")
    args, _ = parser.parse_known_args()
    return Path(args.results)


def read_table(path: Path, **kwargs) -> pd.DataFrame | None:
    """Read a (optionally gzipped) tabular file, tolerating malformed rows."""
    try:
        opener = gzip.open if path.suffix == ".gz" else open
        with opener(path, "rt") as fh:
            return pd.read_csv(fh, **kwargs)
    except Exception as exc:  # surfaced in the UI rather than crashing the app
        st.warning(f"Could not read {path.name}: {exc}")
        return None


def find(results: Path, pattern: str) -> list[Path]:
    return sorted(results.glob(pattern))


# --------------------------------------------------------------------------- #
# Page sections — each maps to a pipeline module/spec section
# --------------------------------------------------------------------------- #
def section_overview(results: Path) -> None:
    st.header("Run overview")
    summary = results / "pipeline_info" / "software_versions.yml"
    if summary.exists():
        st.success(f"Results directory: `{results.resolve()}`")
        st.subheader("Software versions (§11)")
        st.code(summary.read_text(), language="yaml")
    else:
        st.info("No `pipeline_info/software_versions.yml` found — is this a results dir?")

    report = results / "report" / "directRNA_report.html"
    mqc = results / "multiqc" / "multiqc_report.html"
    cols = st.columns(2)
    cols[0].metric("Summary report (HTML)", "present" if report.exists() else "—")
    cols[1].metric("MultiQC report", "present" if mqc.exists() else "—")


def section_quant(results: Path) -> None:
    st.header("Quantification (§5.4 / §5.7)")
    quants = find(results, "quantification/salmon/*/quant.sf") + \
        find(results, "denovo/quantification/*/quant.sf")
    if not quants:
        st.info("No Salmon `quant.sf` tables found.")
        return
    pick = st.selectbox("Sample", quants, format_func=lambda p: p.parent.name)
    df = read_table(pick, sep="\t")
    if df is not None:
        st.dataframe(df, use_container_width=True)
        # TODO(user): this is a good spot to add a TPM distribution plot.


def section_modifications(results: Path) -> None:
    st.header("RNA modifications (§5.5)")
    m6a = find(results, "modifications/m6anet/*/data.site_proba.csv.gz")
    if m6a:
        pick = st.selectbox("m6anet sample", m6a, format_func=lambda p: p.parent.name)
        df = read_table(pick)
        if df is not None:
            st.dataframe(df, use_container_width=True)
    else:
        st.info("No m6anet site tables found.")

    for label, pat in [
        ("Nanocompore", "modifications/nanocompore/*/*.tsv"),
        ("ELIGOS", "modifications/eligos/*/*.txt"),
        ("nanoRMS", "modifications/nanorms/*/*.tsv"),
    ]:
        hits = find(results, pat)
        st.caption(f"{label}: {len(hits)} result file(s)")


def section_polya(results: Path) -> None:
    st.header("Poly(A) / poly(U) tails (§5.6)")
    np_files = find(results, "polya/nanopolish/*.polya.tsv.gz")
    tf_files = find(results, "polya/tailfindr/*.tails.csv")
    st.caption(f"nanopolish: {len(np_files)} · tailfindr: {len(tf_files)}")
    # TODO(user): decide how to summarise tail-length distributions per sample
    # (histogram? per-condition violin? this is a meaningful UX choice).


def section_denovo(results: Path) -> None:
    st.header("De novo transcripts (§5.7)")
    rattle = find(results, "denovo/rattle/*/*.rattle_transcripts.fa")
    stringtie = find(results, "denovo/stringtie/*/*.stringtie.gtf")
    st.caption(f"RATTLE assemblies: {len(rattle)} · StringTie2 GTFs: {len(stringtie)}")


# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #
def main() -> None:
    st.set_page_config(page_title="directRNA results", layout="wide")
    st.title("directRNA — results browser")

    results = get_results_dir()
    if not results.exists():
        st.error(f"Results directory not found: {results.resolve()}\n\n"
                 "Pass one with:  streamlit run gui/app.py -- --results <dir>")
        st.stop()

    page = st.sidebar.radio(
        "Section",
        ["Overview", "Quantification", "Modifications", "Poly(A)", "De novo"],
    )
    {
        "Overview": section_overview,
        "Quantification": section_quant,
        "Modifications": section_modifications,
        "Poly(A)": section_polya,
        "De novo": section_denovo,
    }[page](results)


if __name__ == "__main__":
    main()
