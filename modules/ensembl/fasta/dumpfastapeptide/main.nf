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

process FASTA_DUMPFASTAPEPTIDE {
    tag "${db.species}"
    label 'process_low'
    maxForks "${params.max_database_forks}"

    conda "${moduleDir}/environment.yml"
    container 'ensemblorg/ensembl-legacy-scripts:e112_APIv0.4'

    input:
        val(db)

    output:
        tuple val(db), val("fasta_pep"), path("*.fasta"), optional:false, emit: peptide_fasta
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${db.server.database}"
        def version = "0.4" // No way to get the version from installed repos
        password_arg = db.server.password ? "--pass ${db.server.password}" : ""
        output = "${db.species}_fasta_pep.fasta"

        """
        dump_fasta_peptide.pl \
            --host ${db.server.host} \
            --port ${db.server.port} \
            --user ${db.server.user} \
            ${password_arg} \
            --dbname ${db.server.database} \
            > ${output}

        echo -e -n "${task.process}:\n\tensembl-genomio: ${version}" > versions.yml
        """

    stub:
        def version = "0.4"
        output_file = "pep.fasta"
        dump_dir = "${workflow.projectDir}/tests/modules/ensembl/fasta/dump_peptide/"
        dump_file = "dumped_pep.fasta"
        """
        cp ${dump_dir}/${dump_file} ${output_file}
        echo -e -n "${task.process}:\n\tensembl-genomio: ${version}" > versions.yml
        """
}
