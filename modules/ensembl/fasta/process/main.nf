// See the NOTICE file distributed with this work for additional information
// regarding copyright ownership.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
