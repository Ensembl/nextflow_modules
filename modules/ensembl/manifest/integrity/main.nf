process MANIFEST_INTEGRITY {
    tag "$meta.id"
    label 'process_low'
    container "ensemblorg/ensembl-genomio:v1.6.0"

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


        # Get version from genomio please
        VERSION=\$(python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)")
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: \$VERSION
        END_VERSIONS
        """

    stub:
        integrity_file = "integrity.out"
        """
        echo "No change, don't create manifest error log"

        VERSION=\$(python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)")
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: \$VERSION
        END_VERSIONS
        """
}
