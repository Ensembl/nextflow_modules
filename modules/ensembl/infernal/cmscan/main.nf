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
nextflow.enable.types = true

process CMSCAN {
    tag "${meta.id}"
    label 'process_high'

    conda "bioconda::infernal=1.1.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/infernal:1.1.5--pl5321h7b50bb2_4' :
        'quay.io/biocontainers/infernal:1.1.5--pl5321h7b50bb2_4' }"

    input:
        record(
            meta:  Map,
            chunk: Path,
            rfam_filtered_cm: Path
        )

    output:
        record(
            meta:   meta,
            tblout: file("*.tblout")
        ), emit: tblout

    topic:
        tuple(
            task.process,
            'infernal',
            eval("cmscan -h 2>&1 | sed -nE 's/^# INFERNAL ([^ ]+).*/\\1/p'")
        ) >> 'versions'

    script:
        def prefix = task.ext.prefix
            ? "${task.ext.prefix}.${meta.id}.${task.index}"
            : "${meta.id}.${task.index}"
        """
        cmpress ${rfam_filtered_cm}
        cmscan --rfam --nohmmonly --cut_ga \\
        --notextw \\
        --fmt 2 \\
        --cpu ${task.cpus} \\
        --tblout ${prefix}.tblout \\
        ${rfam_filtered_cm} \\
        ${chunk}

        """

    stub:
        def prefix = task.ext.prefix
            ? "${task.ext.prefix}.${meta.id}.${task.index}"
            : "${meta.id}.${task.index}"
        """
        touch ${prefix}.tblout

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            infernal: "stub"
        END_VERSIONS
        """
}
