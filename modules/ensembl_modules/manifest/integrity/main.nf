process MANIFEST_INTEGRITY {
    tag "$meta.id"
    label 'process_low'

    // TODO nf-core: List required Conda package(s).
    //               Software MUST be pinned to channel (i.e. "bioconda"), version (i.e. "1.10").
    //               For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation on different operating systems.
    // TODO nf-core: See section in main README for further information regarding finding and adding container addresses to the section below.
    // conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
    //     'biocontainers/YOUR-TOOL-HERE' }"

    input:
        tuple val(meta), path(manifest_files)
    
    output:
        tuple val(meta), path("*.*", includeInputs: true), emit: all_files, optional: true
        tuple val(meta), path(integrity_file), emit: error_log, optional: true
        // path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
        integrity_file = "integrity.out"
        """
        manifest_check_integrity \
            --manifest_file ./manifest.json \
            --no_fail \
            $brc_mode \
            > $integrity_file
        
        # Only keep integrity file if there are errors to report
        if [ ! -s $integrity_file ]
            then rm $integrity_file
        fi
        """

    stub:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
        integrity_file = "integrity.out"
        """
        echo "No change, don't create manifest error log"
        """
}
