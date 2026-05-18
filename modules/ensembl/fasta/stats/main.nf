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

    input:
        tuple val(meta), path(fasta)

    output:
        tuple val(meta), path(fasta), path("${meta.id}.fasta_stats.txt"), emit: stats
        tuple val("${task.process}"), val('fasta_stats'), val('1.0.0'), emit: versions_fasta_stats, topic: versions

    script:
        template 'fasta_stats.sh'

    stub:
        """
        set -euo pipefail

        test -s "${fasta}"

        cat <<-EOF > "${meta.id}.fasta_stats.txt"
        1 1 1
        EOF
        """
}
