process SUMMARY_REPORT {
    label 'process_low'

    // Quarto + a PDF engine (tinytex/typst). Pin a concrete tag on your system.
    conda "conda-forge::quarto=1.5.57 conda-forge::python=3.11 conda-forge::pyyaml"
    container 'ghcr.io/quarto-dev/quarto:1.5.57'

    input:
    // numbered subdirs avoid basename collisions (e.g. per-sample data.site_proba.csv.gz)
    path report_files, stageAs: "inputs/?/*"
    path qmd
    path versions
    path run_summary

    output:
    path "directRNA_report.html",                emit: html
    path "directRNA_report.pdf",  optional: true, emit: pdf
    path "versions.yml",                          emit: versions

    script:
    """
    # render HTML (always) and PDF (best-effort; needs a LaTeX/Typst engine)
    quarto render $qmd \\
        --to html \\
        --output directRNA_report.html \\
        -P versions:$versions \\
        -P run_summary:$run_summary \\
        -P inputs_dir:inputs

    quarto render $qmd \\
        --to pdf \\
        --output directRNA_report.pdf \\
        -P versions:$versions \\
        -P run_summary:$run_summary \\
        -P inputs_dir:inputs \\
        || echo "PDF render skipped (no LaTeX/Typst engine in container)"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quarto: \$(quarto --version 2>&1 | head -n1)
    END_VERSIONS
    """

    stub:
    """
    echo "<html><body><h1>directRNA report (stub)</h1></body></html>" > directRNA_report.html
    touch directRNA_report.pdf
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quarto: 1.5.57
    END_VERSIONS
    """
}
