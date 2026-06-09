/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SIGNAL — raw-signal ingest & basecalling (spec §5.2)

      FAST5 ──POD5_CONVERT──┐
                            ├── POD5 ──[run_dorado]── DORADO_BASECALLER ──┬─ uBAM
      POD5 ─────────────────┘                                            ├─ DORADO_SUMMARY → sequencing_summary.txt (→ pycoQC)
                                                                         └─ SAMTOOLS_FASTQ → reads.fastq.gz (→ QC/ALIGN/QUANT)

    Decisions (2026-06-09): auto-convert FAST5→POD5; Dorado GPU-primary, opt-in
    via --run_dorado (process_gpu label); CPU path not advertised.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { POD5_CONVERT      } from '../../modules/local/pod5_convert.nf'
include { DORADO_BASECALLER } from '../../modules/local/dorado_basecaller.nf'
include { DORADO_SUMMARY    } from '../../modules/local/dorado_summary.nf'
include { SAMTOOLS_FASTQ    } from '../../modules/local/samtools_fastq.nf'

workflow SIGNAL {
    take:
    ch_samples   // channel: [ meta, entry_map ]

    main:
    ch_versions = Channel.empty()

    // --- 1. unify on POD5 ---------------------------------------------------
    ch_fast5 = ch_samples
        .filter { meta, entry -> entry.containsKey('fast5_dir') }
        .map    { meta, entry -> [ meta, entry.fast5_dir ] }

    POD5_CONVERT ( ch_fast5 )
    ch_versions = ch_versions.mix(POD5_CONVERT.out.versions.first())

    ch_pod5_native = ch_samples
        .filter { meta, entry -> entry.containsKey('pod5_dir') }
        .map    { meta, entry -> [ meta, entry.pod5_dir ] }

    ch_pod5 = ch_pod5_native.mix(POD5_CONVERT.out.pod5)

    // --- 2. basecalling (opt-in) -------------------------------------------
    ch_basecalled_fastq = Channel.empty()
    ch_summary          = Channel.empty()
    ch_ubam             = Channel.empty()

    if (params.run_dorado) {
        DORADO_BASECALLER ( ch_pod5 )
        ch_ubam = DORADO_BASECALLER.out.bam

        DORADO_SUMMARY ( ch_ubam )
        SAMTOOLS_FASTQ ( ch_ubam )

        ch_summary          = DORADO_SUMMARY.out.summary
        ch_basecalled_fastq = SAMTOOLS_FASTQ.out.fastq

        ch_versions = ch_versions.mix(
            DORADO_BASECALLER.out.versions.first(),
            DORADO_SUMMARY.out.versions.first(),
            SAMTOOLS_FASTQ.out.versions.first()
        )
    }

    emit:
    pod5     = ch_pod5               // [ meta, pod5_dir ]  (for f5c, Phase 2.2)
    ubam     = ch_ubam               // [ meta, uBAM ]      (move tables)
    fastq    = ch_basecalled_fastq   // [ meta, fastq.gz ]  (feeds QC/ALIGN/QUANT)
    summary  = ch_summary            // [ meta, summary ]   (feeds pycoQC)
    versions = ch_versions
}
