process CHECK_JSON_SCHEMA {
    tag "$meta.id"
    label 'process_low'

    input:
        tuple val(meta), path(json_file)

    output:
        tuple val(meta), path(json_file), emit: verified_json
        path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    shell:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
        schema_name = json_file.simpleName
        def VERSION = 1
        '''
        schemas_json_validate --json_file !{json_file} --json_schema !{schema_name}
        '''
}


    when:
    task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
        integrity_file = "integrity.out"
        def VERSION = 1
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
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: $VERSION
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
