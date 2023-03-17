//
// Check input samplesheet and get read channels
// Cribbed from nf-core/rnaseq, adapted to CellRanger
//

params.options = [:]

include { SAMPLESHEET_CHECK } from '../../modules/local/samplesheet_check' addParams( options: params.options )

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    SAMPLESHEET_CHECK( samplesheet ).csv.splitCsv( header:true, sep:',' )
        .map { create_fastq_channels(it) }
        .set { reads }

    emit:
    reads // channel: [ val(meta), [ reads ] ]
    versions = SAMPLESHEET_CHECK.out.versions // channel: [ versions.yml ]
}

// Function to get list of [ meta, [ fastqs ] ]
def create_fastq_channels(LinkedHashMap col) {
    def meta = [:]
    meta.id             = col.fastq_id
    meta.dir            = col.fastqs
    meta.gem            = col.gem
    meta.fastq_id       = col.fastq_id
    meta.fastqs         = col.fastqs
    meta.feature_types  = col.feature_types

    def array = []
    if (!file(col.fastqs).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Fastq file folder does not exist!\n${col.fastqs}"
    }
    array = [ meta, [ file(col.fastqs) ] ]
    return array
}
