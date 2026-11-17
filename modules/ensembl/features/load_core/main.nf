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
    container 'docker.io/ensemblorg/ensembl-genomio:v1.8.0'

    input:
        record(
            meta: Map,
            features_json: Path,
            prod_host: String,
            prod_database: String,
            prod_user: String,
            prod_port: Integer,
            prod_password: String?,
            core_host: String,
            core_database: String,
            core_user: String,
            core_port: Integer,
            core_password: String?,
        )

    topic:
        tuple(task.process, 'features_core_load', eval("features_core_load --version 2>/dev/null || echo unknown")) >> 'versions'

    script:
        
        def prod_pass = prod_password != null ? "--prod_password ${prod_password}" : '' 
        def core_pass = core_password != null ? "--core_password ${core_password}" : ''
        def args = task.ext.args ?: ''

        """
        features_core_load  --input-file ${features_json} \
            --prod_host ${prod_host} \
            --prod_database ${prod_database} \
            --prod_user ${prod_user} \
            --prod_port ${prod_port} \
            ${prod_pass} \
            --core_host ${core_host} \
            --core_database ${core_database} \
            --core_user ${core_user} \
            --core_port ${core_port} \
            ${core_pass} \
            ${args}
        """

    stub:
        """
        true
        """
}
