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

process GFF3_DUMPGFF3 {
    tag "${db.species}"
    label 'process_low'
    // maxForks "${params.max_database_forks}"
    
    container 'ensemblorg/ensembl-legacy-scripts:e112_APIv0.4'

    input:
        val db

    output:
        tuple val(db), val("gff3"), path("*.gff3"), emit: gff3
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        version = "0.4"
        output = "${db.species}.gff3"
        temp_gff = "temp.gff3"
        password_arg = db.server.password ? "--pass ${db.server.password}" : ""
        """
        dump_gff3.pl \
            --host ${db.server.host} \
            --port ${db.server.port} \
            --user ${db.server.user} \
            ${password_arg} \
            --dbname ${db.server.database} \
            > ${temp_gff}

        # Tidy up
        gt gff3 -tidy -sort -retainids ${temp_gff} > ${output}
        gt gff3validator ${output}
        rm ${temp_gff}

        echo -e -n "${task.process}:\n\tensembl-genomio: ${version}" > versions.yml
        """

    stub:
        version = "0.4"
        output_stub = "gff_outfile.gff3"
        input_gff3 = "${projectDir}/tests/module/ensembl/gff3/dumpgff3/test_dump.gff3"
        """
        cp ${input_gff3} ${output_stub}

        echo -e -n "${task.process}:\n\tensembl-genomio: ${version}" > versions.yml
        """
}
