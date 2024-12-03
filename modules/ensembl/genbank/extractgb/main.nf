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

process GENBANK_EXTRACTGB {
    tag "${meta.accession}:${gb_file}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:GenomioDockerRebuild_v1.5.0a"

    input:
        tuple val(meta), path(gb_file)

    output:
        tuple val(meta), path("genome.json"), emit: genome
        tuple val(meta), path("seq_region.json"), emit: seq_regions
        tuple val(meta), path("dna.fasta"), emit: dna_fasta
        tuple val(meta), path("*.gff"), emit: gene_gff, optional: true
        tuple val(meta), path("pep.fasta"), emit: pep_fasta, optional: true
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when


    shell:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${gb_file}"

        '''
        genbank_extract_data \
            --prefix !{meta.prefix} \
            --prod_name !{meta.production_name} \
            --gb_file !{gb_file} \
            --debug

        schemas_json_validate --json_file "genome.json" --json_schema "genome"
        schemas_json_validate --json_file "seq_region.json" --json_schema "seq_region"
        '''

    stub:
        def args = task.ext.args ?: ''
        def prefix = task.ext.prefix ?: "${gb_file}"
        out_genome_json = "genome.json"
        out_seq_json = "seq_region.json"
        out_dna_fa = "dna.fasta"
        out_gene_gff = "valida.gff"
        out_pep_fa = "pep.fasta"

        """
        echo "{"accession": "NC_00001"}" > ${out_genome_json}
        echo "{"seq_region": "Chrm1"}" > ${out_seq_json}
        echo -e -n ">Seq1\nATGC" > ${out_dna_fa}
        cp ${workflow.projectDir}/tests/modules/ensembl/download/genbank/test.gff ${out_gene_gff}
        echo ">Peptide_1a\nMPLEGM" > ${out_pep_fa}

        echo -e -n "${task.process}:\n\tensembl-genomio: " > versions.yml
        python -c "import ensembl.io.genomio; print(ensembl.io.genomio.__version__)" >> versions.yml
        """
}
