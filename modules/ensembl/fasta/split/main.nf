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

process FASTA_SPLIT {

    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:v1.6.1"

    input:
        tuple val(meta), path(fasta)

    output:
        tuple val(meta), path("splits/**/*.fa"), emit: fasta
        tuple val(meta), path("splits/*.agp"), emit: agp, optional: true

    script:
        def args = []

        if (params.max_seqs_per_file) {
            args << "--max-seqs-per-file ${params.max_seqs_per_file}"
        }

        if (params.max_seq_length_per_file) {
            args << "--max-seq-length-per-file ${params.max_seq_length_per_file}"
        }

        if (params.min_chunk_length) {
            args << "--min-chunk-length ${params.min_chunk_length}"
        }

        if (params.max_files_per_directory) {
            args << "--max-files-per-directory ${params.max_files_per_directory}"
        }

        if (params.max_dirs_per_directory) {
            args << "--max-dirs-per-directory ${params.max_dirs_per_directory}"
        }

        if (params.force_max_seq_length) {
            args << "--force-max-seq-length"
        }

        if (params.write_agp) {
            args << "--write-agp"
        }

        if (params.unique_file_names) {
            args << "--unique-file-names"
        }

        if (params.delete_existing_files) {
            args << "--delete-existing-files"
        }

        """
        fasta_split \\
            --fasta-file ${fasta} \\
            --out-dir splits \\
            ${args.join(' ')}
        """

    stub:
        """
        set -euo pipefail

        test_data_dir="${moduleDir}/tests/data"

        layout="default"
        if [[ "${params.unique_file_names ?: false}" == "true" ]]; then
            layout="unique"
        elif [[ -n "${params.max_dirs_per_directory ?: ''}" || -n "${params.max_files_per_directory ?: ''}" ]]; then
            layout="multi_dir"
        fi

        mkdir -p splits
        cp -R "\$test_data_dir/splits/\$layout/." "splits/"

        if [[ "${params.write_agp ?: false}" == "true" ]]; then
            cp "\$test_data_dir/agp/test.agp" "splits/${meta.id}.agp"
        fi
        """

        
}
