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

process DOWNLOAD_GENBANK {
    tag "${meta.production_name}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:GenomioDockerRebuild_v1.5.0a"

    input:
        val(meta)

    output:
        tuple val(meta), path("output.gb"), emit: gb_sequence
        path "versions.yml" , emit: versions // need to add versions output to other ported modules!

    when:
        task.ext.when == null || task.ext.when

    script:
        def prefix = task.ext.prefix ?: "${meta.accession}"
        output_file = "output.gb"

        """
        genbank_download --accession ${meta.accession} --output_file ${output_file} --debug

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)" >> versions.yml
        """

    stub:
        def prefix = task.ext.prefix ?: "${meta.accession}"
        output_file = "output.gb"
        """
        cp ${workflow.projectDir}/tests/modules/ensembl/download/genbank/${output_file} ./${output_file}
        
        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)" >> versions.yml
        """
}
