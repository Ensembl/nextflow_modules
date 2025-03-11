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

process SCHEMA_JSON {
    tag "$meta.id"
    label 'process_low'

    container "ensemblorg/ensembl-genomio:v1.6.1"

    input:
        tuple val(meta), path(json_file)

    output:
        tuple val(meta), path(json_file), emit: verified_json
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        schema_name = json_file.simpleName
        """
        schemas_json_validate --json_file !{json_file} --json_schema !{schema_name}

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        schemas_json_validate --version >> versions.yml
        """

    stub:
        schema_name = json_file.simpleName
        """
        echo "No change, don't create schema error log"

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        schemas_json_validate --version >> versions.yml
        """
}
