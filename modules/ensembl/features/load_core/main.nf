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

process FEATURES_LOAD_CORE {
    tag "${meta.id}"
    label 'process_medium'
    maxForks 1
    conda "${moduleDir}/environment.yml"
    container 'docker.io/ensemblorg/ensembl-genomio:v1.9.0'

    secret 'CORE_DB_PASSWORD'
    secret 'PROD_DB_PASSWORD'

    input:
        record(
            meta: Map,
            features_json: Path,
            core_host: String,
            core_database: String,
            core_user: String,
            core_port: Integer,
            prod_host: String,
            prod_database: String,
            prod_user: String,
            prod_port: Integer,
        )

    topic:
        tuple(task.process, 'features_core_load', eval("features_core_load --version 2>/dev/null || echo unknown")) >> 'versions'

    script:
        def args = task.ext.args ?: ''

        """
        features_core_load --input-file ${features_json} \
            --core-host=${core_host} \
            --core-database=${core_database} \
            --core-user=${core_user} \
            --core-port=${core_port} \
            --prod-host=${prod_host} \
            --prod-database=${prod_database} \
            --prod-user=${prod_user} \
            --prod-port=${prod_port} \
            ${args}
        """

    stub:
        """
        true
        """
}
