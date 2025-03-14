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

process DUMP_GENOMESTATS {
    tag "${db.species}"
    label 'process_low'
    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:v1.6.1"

    input:
        val(db)

    output:
        tuple val(db), path("core_stats.json"), emit: core_stats
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${db.server.database}"
        password_arg = db.server.password ? "--password ${db.server.password}" : ""
        output_file = "core_stats.json"
        """
        genome_stats_dump \
            --host '${db.server.host}' \
            --port '${db.server.port}' \
            --user '${db.server.user}' \
            ${password_arg} \
            --database '${db.server.database}' \
            > ${output_file}

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        genome_stats_dump --version >> versions.yml
        """

    stub:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${db.test_id}"
        output_file = "core_stats.json"
        dump_dir = "${workflow.projectDir}/tests/modules/ensembl/dump/genomestats/"
        dump_file = "dumped_core_stats.json"
        """
        cp ${dump_dir}/${dump_file} ${output_file}
        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        genome_stats_dump --version >> versions.yml
        """
}
