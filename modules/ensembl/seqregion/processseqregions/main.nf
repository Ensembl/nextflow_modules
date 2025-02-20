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

process SEQREGION_PROCESSSEQREGIONS {
    tag "${meta.species}"
    label 'process_low'
    
    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:v1.6.0"

    input:
        tuple val (meta),
            path (genome_json),
            path (assembly_report),
            path (genomic_gbff)

    output:
        tuple val(meta), path("seq_region.json"), emit: seq_region
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        output = "seq_region.json"
        """
        seq_region_prepare \
            --genome_file ${genome_json} \
            --report_file ${assembly_report} \
            --gbff_file ${genomic_gbff} \
            --dst_file ${output}
        
        schemas_json_validate --json_file ${output} --json_schema seq_region

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        seq_region_prepare --version >> versions.yml
        """

    stub:
        output = "seq_region.json"
        """
        seq_region_prepare \
            --genome_file ${genome_json} \
            --report_file ${assembly_report} \
            --gbff_file ${genomic_gbff} \
            --dst_file ${output} \
            --mock_run

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        seq_region_prepare --version >> versions.yml
        """
}
