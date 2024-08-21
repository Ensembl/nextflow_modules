process MANIFEST_INTEGRITY {
    tag "$meta.id"
    label 'process_low'

    container "${ (workflow.containerEngine == 'docker') ?
        'lahcen86/dev_test_genomio:litev3' : '' }"

    input:
        tuple val(meta), path(manifest_files)
    
    output:
        tuple val(meta), path("*.*", includeInputs: true), emit: all_files, optional: true
        tuple val(meta), path(integrity_file), emit: error_log, optional: true
        path "versions.yml", emit: versions

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


        # Get version from genomio please
        # VERSION=\$(manifest_check_integrity --version)
        VERSION=1
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: \$VERSION
        END_VERSIONS
        """

    stub:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
        integrity_file = "integrity.out"
        def VERSION = 1
        """
        echo "No change, don't create manifest error log"

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: $VERSION
        END_VERSIONS
        """
}
