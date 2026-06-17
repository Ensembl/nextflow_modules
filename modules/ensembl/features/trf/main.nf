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

process FEATURES_TRF {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/trf:4.09.1--h7b50bb2_7"

    input:
        tuple val(meta), path(fasta)

    output:
        tuple val(meta), path("*.dat"), emit: dat
        tuple val("${task.process}"), val('trf'), eval("trf -v 2>&1 | grep -oE '[0-9]+(\\.[0-9]+)+' || echo 4.09.1"), emit: versions_trf, topic: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: '2 7 7 80 10 100 500'
        """
        trf '${fasta}' ${args} -d -h
        """

    stub:
        """
        cat > "${fasta.name}.dat" << 'EOF'
        Sequence: ${fasta.name}
        EOF
        """
}
