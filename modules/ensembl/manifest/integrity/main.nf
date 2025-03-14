process MANIFEST_INTEGRITY {
    tag "$meta.id"
    label 'process_low'

    container "ensemblorg/ensembl-genomio:v1.6.1"

    input:
        tuple val(meta), path(manifest_files)
    
    output:
        tuple val(meta), path("*.*", includeInputs: true), emit: all_files, optional: true
        tuple val(meta), path(integrity_file), emit: error_log, optional: true
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        integrity_file = "integrity.out"
        """
        manifest_check_integrity \
            --manifest_file ./manifest.json \
            --no_fail \
            > $integrity_file
        
        # Only keep integrity file if there are errors to report
        if [ ! -s $integrity_file ]
            then rm $integrity_file
        fi

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        manifest_check_integrity --version >> versions.yml
        """

    stub:
        integrity_file = "integrity.out"
        """
        echo "No change, don't create manifest error log"

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        manifest_check_integrity --version >> versions.yml
        """
}
