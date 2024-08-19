process SCHEMA_JSON {
    tag "$meta.id"
    label 'process_low'

    input:
        tuple val(meta), path(json_file)

    output:
        tuple val(meta), path(json_file), emit: verified_json
        path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
        schema_name = json_file.simpleName
        def VERSION = 1
        """
        schemas_json_validate --json_file !{json_file} --json_schema !{schema_name}

        # Get version from genomio please
        VERSION=\$(python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)")
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: $VERSION
        END_VERSIONS
        """

    stub:
        schema_name = json_file.simpleName
        def VERSION = 1
        """
        echo "No change, don't create schema error log"

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: $VERSION
        END_VERSIONS
        """
}
