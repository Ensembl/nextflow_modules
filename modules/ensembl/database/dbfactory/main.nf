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

process DATABASE_DBFACTORY {
    tag "${server.host}"
    label 'process_low'
    time '5min'

    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:GenomioDockerRebuild_v1.5.0a"
    
    input:
        tuple val(server), val(filter_map)

    output:
        path "dbs.json", emit: dbs_meta_json
        path "versions.yml" , emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        // Module specific vars:
        output_file = "dbs.json"
        dbname_re = filter_map.dbname_re ? "--db_regex ${filter_map}.dbname_re" : ''
        password_arg = server.password ? "--password ${server}.password" : ''

        // Prepare db_list to write in a file
        db_list = ""
        db_list_str = ""
        db_list_file = "db_list.tsv"

        if (filter_map.db_list) {
            db_list_str = filter_map.db_list.join("\n")
            db_list = "--db_list ${db_list_file}"
        }
        """
        echo "${db_list_str}" > ${db_list_file}

        database_factory --host '${server.host}' \
            --port '${server.port}' \
            --user '${server.user}' \
            ${password_arg} \
            --prefix '${filter_map.prefix}' \
            ${dbname_re} \
            ${db_list} \
            > ${output_file}
        
        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)" >> versions.yml
        """

    stub:
        output_file = "dbs.json"
        """
        echo "{"species": "aaegL5", "division": "VectorBase", "release": 60}" > ${output_file}

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)" >> versions.yml
        """
}
