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

process FASTA_RECOMBINE {

    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:v1.6.1"

    publishDir "${params.outdir ?: '.'}", mode: 'copy'

    input:
        tuple val(meta), path(fasta_manifest), path(agp)

    output:
        tuple val(meta), path("*.fa"), emit: fasta

    script:
        def args = []

        if (params.chunk_id_regex) {
            args << "--chunk-id-regex ${params.chunk_id_regex}"
        }

        if (params.allow_revcomp) {
            args << "--allow-revcomp"
        }

        if (agp) {
            args << "--agp-file ${agp}"
        }

        def out_fasta = "${meta.id}.fa"

        """
        fasta_recombine \\
            --fasta-manifest ${fasta_manifest} \\
            --out-fasta ${out_fasta} \\
            ${args.join(' ')}
        """

    stub:
        """
        set -euo pipefail

        test_data_dir="${moduleDir}/tests/data"

        out_fasta="${meta.id}.fa"

        test -s "${fasta_manifest}"

        mode="header"
        if [[ -n "${agp ?: ''}" ]]; then
            mode="agp"
        fi

        cp "\$test_data_dir/\$mode/output/${meta.id}.fa" "\$out_fasta"
        
        """

        
}
