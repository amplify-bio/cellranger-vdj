process SAMPLESHEET_CHECK {
    tag "$samplesheet"
    label 'process_low'
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
    ${task.process}:
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
