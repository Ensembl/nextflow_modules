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

process DOWNLOAD_ASSEMBLYDATA {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container 'ensemblorg/ensembl-genomio:v1.5.0'
    
    input:
        tuple val(meta)

    output:
        tuple val(meta),
            path("*_assembly_report.txt"),
            path("*_genomic.fna.gz"),
            path("*_genomic.gbff.gz"),
            emit: min_set
        tuple val(meta),
            path("*_genomic.gff.gz"),
            path("*_protein.faa.gz"),
            path("*_genomic.gbff.gz"),
            emit: opt_set, optional: true

    when:
        task.ext.when == null || task.ext.when

    shell:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"

        '''
        assembly_download --accession !{meta.accession} --download_dir ./ --verbose

        echo -e -n "${task.process}":\n\tensembl-genomio: " > versions.yml
        python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)" >> versions.yml
        '''

    stub:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${meta.id}"
        """
        assembly_download --help
        cp $workflow.projectDir/../../../../tests/modules/ensembl_modules/download/assemblydata/* .

        echo -e -n "${task.process}":\n\tensembl-genomio: " > versions.yml
        python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)" >> versions.yml
        """
}
