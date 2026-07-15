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

process FEATURES_RED {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "quay.io/biocontainers/red:2018.09.10--h9948957_3"

    input:
        tuple val(meta), path(fasta)

    output:
        tuple val(meta), path("rpt/*.bed"), emit: bed
        tuple val("${task.process}"), val('red'), eval("conda list red --json | python -c 'import sys,json; print(json.load(sys.stdin)[0][\"version\"])' || echo 2.0"), emit: versions_red, topic: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''

        def reserved = ['-gnm', '-rpt', '-msk', '-frm', '-cor']
        def supplied = args.tokenize()

        supplied.each { opt ->
            if (opt in reserved) {
                error "FEATURES_RED: ${opt} is managed by the module and must not be supplied via task.ext.args."
            }
        }

        """
        mkdir -p genome rpt

        # Red only scans .fa files in the genome directory
        cp ${fasta} genome/${meta.id}.fa

        Red \
            -gnm genome \
            -rpt rpt \
            -cor ${task.cpus} \
            -frm 2 \
            ${args}
        """

    stub:
        """
        mkdir -p rpt

        cat > rpt/${meta.id}.bed <<EOF
        ${meta.id}\t1\t100
        EOF
        """
}
