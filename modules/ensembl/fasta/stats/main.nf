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

process FASTA_STATS {

    tag "${meta.id}"
    label 'process_small'

    conda "${moduleDir}/environment.yml"
    container "docker.io/ensemblorg/ensembl-genomio:v1.7.0"

    input:
        tuple val(meta), path(fasta)

    output:
        tuple val(meta), path("${fasta.simpleName}.stats.json"), emit: stats
        tuple val("${task.process}"), val('fasta_stats'), eval("fasta_stats --version"), emit: versions_fasta_stats, topic: versions

    script:
        """
        fasta_stats --fasta ${fasta} --output ${fasta.simpleName}.stats.json
        """

    stub:
        """
        stats_out="${fasta.simpleName}.stats.json"
        touch "\${stats_out}"
        """
}
