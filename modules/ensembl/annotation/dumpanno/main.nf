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

process ANNOTATION_DUMPANNO {
    tag "${db.species}"
    label 'process_low'
    
    container 'ensemblorg/ensembl-legacy-scripts:e112_APIv0.4'

    input:
        val(db)

    output:
        tuple val(db), val("functional_annotation"), path("*.json"), emit: functional_annotation
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        // Defining version as we cannot retrieve the container version here 
        version = "0.4"
        output = "${db.species}_functional_annotation.json"
        schema = "functional_annotation"
        password_arg = db.server.password ? "--pass ${db.server.password}" : ""
        """
        dump_functional_annotation.pl \
            --host $db.server.host \
            --port $db.server.port \
            --user $db.server.user \
            $password_arg \
            --dbname $db.server.database > $output

        # Get version from container please
        echo -e -n "${task.process}:\n\tensembl-legacy-scripts:e112_APIv0.4 : $version " > versions.yml
        """

    stub:
        version = "0.4"
        """
        echo "No change, create an empty json file" > functional_annotation.json

        # Get version from genomio please
        echo -e -n "${task.process}:\n\tensembl-legacy-scripts:e112_APIv0.4 : $version" > versions.yml
        """
}
