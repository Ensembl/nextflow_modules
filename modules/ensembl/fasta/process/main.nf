process FASTA_PROCESS {
    tag "$meta.accession"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:v1.6.1"

    input:
        tuple val(meta), path(compressed_gff), path(fasta_file), path(gbff_file)

    output:
        tuple val(meta), path ("*.fa")      , emit: processed_fasta
        path "versions.yml"                 , emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def prefix = task.ext.prefix ?: "${meta.accession}"
        def args = task.ext.args ?: ''
        // --peptide_mode is treated as a optional extra parameter.
        // By default it's set to false
        def pep_mode = task.ext.args.contains("--peptide_mode")
        def output_fasta = pep_mode ? "${prefix}_pep.fa" : "${prefix}_dna.fa"
        """
        fasta_process --fasta_infile ${fasta_file} \
            --genbank_infile ${gbff_file} \
            --fasta_outfile ${output_fasta}" \
            ${args}

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fasta_process: $(fasta_process --version)
        END_VERSIONS
        """

    stub:
        def pep_mode = task.ext.args.contains("--pep-mode")
        def output_fasta = pep_mode? "fasta_pep.fa" : "fasta_dna.fa"
        """
        touch ${output_fasta}
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fasta_process: $(fasta_process --version)
        END_VERSIONS
        """
}
