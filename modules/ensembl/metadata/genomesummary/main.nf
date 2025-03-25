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

process METADATA_GENOMESUMMARY {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:v1.6.1"

    input:
        tuple val(meta), path(input_query), path(genome_summary_json)

    output:
        tuple val(meta), path("genome.json"), emit: meta_json
        path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
        def prefix = task.ext.prefix ?: "${meta.accession}"
        def output_json = "genome.json"

        """
        genome_metadata_prepare --input_file ${input_query} --output_file ${output_json} --ncbi_meta ${genome_summary_json}

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        genome_metadata_prepare --version >> versions.yml
        """

    stub:
        def prefix = task.ext.prefix ?: "${meta.accession}"
        def testout_json = "genome-meta.json"
        def output_json = "genome.json"

        """
        cp ${workflow.projectDir}/tests/modules/ensembl/metadata/genomesummary/${testout_json} ./${output_json}

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        genome_metadata_prepare --version >> versions.yml
        """
}
