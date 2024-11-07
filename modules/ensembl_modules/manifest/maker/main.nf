// TODO nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/modules/nf-core/
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// TODO nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// TODO nf-core: Software that can be piped together SHOULD be added to separate module files
//               unless there is a run-time, storage advantage in implementing in this way
//               e.g. it's ok to have a single module for bwa to output BAM instead of SAM:
//                 bwa mem | samtools view -B -T ref.fasta
// TODO nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process MANIFEST_MAKER {
    tag "$meta.id"
    label 'process_low'

    container "${ (workflow.containerEngine == 'docker') ?
        'ensemblorg/ensembl-genomio:v1.4.0' : '' }"

    input:
        tuple val(meta), path(file_name)

    output:
        tuple val(meta), path("*.*", includeInputs: true), emit: all_files, optional: true
        path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
        """
        manifest_generate --manifest_dir .
        schemas_json_validate --json_file manifest.json --json_schema "manifest"
        """

    stub:
    
        """
        echo "No change, don't create manifest error log"

        VERSION=\$(python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)")
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            Genomio: \$VERSION
        END_VERSIONS
        """
}
