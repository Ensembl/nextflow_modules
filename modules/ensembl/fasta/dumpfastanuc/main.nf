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

process FASTA_DUMPFASTANUC {
    tag "$meta.id"
    label 'process_low'
    // conda "${moduleDir}/environment.yml" // this is not a genomio process
    container 'ensemblorg/ensembl-legacy-scripts:e112_APIv0.4'

    input:
        tuple val(meta), val(db)

    output:
        tuple val(db), val("fasta_dna"), path("*.fasta"), optional:false, emit: nucleotide_fasta

    when:
    task.ext.when == null || task.ext.when

    script:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
        def version = "0.4" // No way to get the version from installed repos

        output = "${db.species}_fasta_dna.fasta"
        password_arg = db.server.password ? "--pass ${db.server.password}" : ""

        """
        dump_fasta_dna.pl \
            --host $db.server.host \
            --port $db.server.port \
            --user $db.server.user \
            $password_arg \
            --dbname $db.server.database > $output
        
        echo -e -n "${task.process}":\n\tensembl-genomio: ${version}" > versions.yml
        """

    stub:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
        def version = "0.4" // No way to get the version from installed repos

        output_file = "dna.fasta"
        """
        echo -e -n ">SEQ1\nCGTA" > ${output_file}
        echo -e -n "${task.process}:\n\tensembl-genomio: ${version}" > versions.yml
        """
}
