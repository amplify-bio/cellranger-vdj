// Cribbed from nf-core/rnaseq
// Import generic module functions

include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'
options        = initOptions(params.options)

params.options = [:]

process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:'pipeline_info', meta:[:], publish_by_meta:[]) }
	container "quay.io/biocontainers/python:3.8.3"

    input:
    path samplesheet

    output:
    path '*.csv'       , emit: csv
    path "versions.yml", emit: versions

    script: // This script is bundled with the pipeline, in klkeys/cellranger-vdj/bin/
    """
    check_samplesheet.py \\
        $samplesheet \\
        featuretype_list.txt
    cp $samplesheet samplesheet.valid.csv

    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
