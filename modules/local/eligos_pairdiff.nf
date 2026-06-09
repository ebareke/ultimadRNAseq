process ELIGOS_PAIRDIFF {
    tag   "$meta.id"
    label 'process_medium'

    // ELIGOS2 has no Bioconda recipe — use the author's image (pin a digest on
    // your target system). No conda fallback available.
    container 'docker.io/piroonj/eligos2:latest'

    input:
    // meta.id = "<test>_vs_<control>"
    tuple val(meta), path(test_bam), path(test_bai), path(control_bam), path(control_bai)
    path  fasta

    output:
    tuple val(meta), path("${meta.id}/*.txt"), optional: true, emit: results
    tuple val(meta), path("${meta.id}"),                       emit: outdir
    path  "versions.yml",                                      emit: versions

    script:
    def args   = task.ext.args   ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # whole-contig region BED straight from the FASTA (no samtools needed)
    awk '/^>/{if(name)print name"\\t0\\t"len; name=substr(\$1,2); len=0; next}
             {len+=length(\$0)} END{if(name)print name"\\t0\\t"len}' $fasta > regions.bed

    mkdir -p ${prefix}
    eligos2 pair_diff_mod \\
        -tbam $test_bam \\
        -cbam $control_bam \\
        -reg regions.bed \\
        -ref $fasta \\
        -t $task.cpus \\
        -o ${prefix} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eligos2: \$(eligos2 version 2>&1 | head -n1 || echo 'unknown')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}
    echo -e "chrom\\tstart\\tend\\tstrand\\tpval\\toddR\\tESB" > ${prefix}/${prefix}_baseExt0_pair_diff_mod.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        eligos2: 2.1.0
    END_VERSIONS
    """
}
