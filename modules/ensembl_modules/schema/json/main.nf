process SCHEMA_JSON {
    tag "$meta.id"
    label 'process_low'

    container "${ (workflow.containerEngine == 'docker') ?
        'lahcen86/dev_test_genomio:litev3' : '' }"

    input:
        tuple val(meta), path(json_file)

    output:
        tuple val(meta), path(json_file), emit: verified_json
        path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
        schema_name = json_file.simpleName
        """
        schemas_json_validate --json_file !{json_file} --json_schema !{schema_name}

        # Get version from genomio please
        VERSION=\$(python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)")
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: \$VERSION
        END_VERSIONS
        """

    stub:
        schema_name = json_file.simpleName
        """
        echo "No change, don't create schema error log"

        # Get version from genomio please
        VERSION=\$(python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)")
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: \$VERSION
        END_VERSIONS
        """
}
