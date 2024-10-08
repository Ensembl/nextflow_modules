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

process GFF3_VALIDATION {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'quay.io/biocontainers/genometools-genometools:1.6.5--py310h3db02ab_0' :
        'biocontainers/genometools-genometools:1.6.5--py310h3db02ab_0' }"    

    input:
        tuple val(meta), path (gene_models, stageAs: "incoming.gff3")

    output:
        tuple val(meta), path("gene_models.gff3"), emit: gene_models
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        out_gff = "gene_models.gff3"
        """
        cp ${gene_models} temp.gff3
        gt gff3 -tidy -sort -retainids -force -o ${out_gff} temp.gff3
        gt gff3validator ${out_gff}
        
        # Get version from gt tools please
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            genometools: \$(gt --version | head -1 | sed 's/gt (GenomeTools) //')
        END_VERSIONS
        """

    stub:
        gene_models = "gene_models.gff3"
        """
        echo "No change, create an emply gff" >> ${gene_models}

        # Get version from gt tools please
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            genometools: \$(gt --version | head -1 | sed 's/gt (GenomeTools) //')
        END_VERSIONS
        """
}