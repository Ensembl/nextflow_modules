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
    container "ensemblorg/ensembl-genomio:v1.7.0-docker"

    input:
        tuple val(meta), path(fasta_manifest), path(agp)

    output:
        tuple val(meta), path("${meta.id}.fa"), emit: recombined_fasta
        tuple val("${task.process}"), val('fasta_recombine'), eval("fasta_recombine --version"), emit: versions_fasta_recombine, topic: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = []

        if (params.chunk_id_regex) {
            def rx = params.chunk_id_regex.replace("'", "'\"'\"'")
            args << "--chunk-id-regex '${rx}'"
        }

        if (params.allow_revcomp) {
            args << "--allow-revcomp"
        }

        def has_agp = agp && agp.baseName != 'NO_FILE'
        if (has_agp) {
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
        touch "${meta.id}.fa"
        """   
}
