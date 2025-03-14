//
// Index BAM file, run idxstats, sort the idxstats output, run samrools depth and stats
//

include { SAMTOOLS_INDEX    } from '../../modules/nf-core/samtools/index/main'
include { SAMTOOLS_IDXSTATS } from '../../modules/nf-core/samtools/idxstats/main'
include { SORT_IDXSTATS     } from '../../modules/local/idxstats_sort.nf'
include { SAMTOOLS_DEPTH    } from '../../modules/nf-core/samtools/depth/main'
include { SAMTOOLS_STATS    } from '../../modules/nf-core/samtools/stats/main'

workflow GET_MAPPING_STATS {
    take:
    ch_aligned // channel: [ val(meta), [ bam ] ]
    fasta      // channel: [ val(meta), path(fasta) ]

    main:

    ch_versions = Channel.empty()

    //
    // MODULE: Index BAM file
    //
    SAMTOOLS_INDEX (
        ch_aligned
    )
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

    //
    // MODULE: Run idxstats
    //
    SAMTOOLS_IDXSTATS (
        ch_aligned.join(SAMTOOLS_INDEX.out.bai) // Channel: val(meta), path(bam), path(bai)
    )
    ch_versions = ch_versions.mix(SAMTOOLS_IDXSTATS.out.versions)

    //
    // MODULE: Sort the idxstats output
    //
    SORT_IDXSTATS (
        SAMTOOLS_IDXSTATS.out.idxstats
    )
    ch_versions = ch_versions.mix(SORT_IDXSTATS.out.versions)

    //
    // MODULE: Run samtools depth
    //
    SAMTOOLS_DEPTH (
        ch_aligned,
        [ [], []] // Passing empty channels instead of an interval file
    )
    ch_versions = ch_versions.mix(SAMTOOLS_DEPTH.out.versions)

    //
    // MODULE: Run samtools stats
    //
    SAMTOOLS_STATS (
        ch_aligned.join(SAMTOOLS_INDEX.out.bai), // Channel: val(meta), path(bam), path(bai)
        fasta
    )
    ch_versions = ch_versions.mix(SAMTOOLS_STATS.out.versions)

    emit:
    idxstats = SAMTOOLS_IDXSTATS.out.idxstats // channel: [ val(meta), [ idxstats ] ]
    tsv      = SAMTOOLS_DEPTH.out.tsv         // channel: [ val(meta), [ tsv ] ]

    versions = ch_versions                    // channel: [ versions.yml ]

}