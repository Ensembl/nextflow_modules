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

nextflow.enable.dsl = 2

process FEATURES_CONVERTTOJSON {
    tag "${meta.id}"
    label 'process_small'
    container 'ensemblorg/ensembl-genomio:v1.6.1'

    input:
        tuple val(meta), path(features_out), path(consensus_lib_fasta)
        val(analysis_logic_name)
        val(analysis_display_label)
        val(analysis_description)
        val(program_name)
        val(program_version)
        val(program_parameters)
        val(annotation_provider)
        val(is_primary_source)

    output:
        tuple val(meta), path("${meta.id}.${analysis_logic_name}.features.json"), emit: json
        tuple val("${task.process}"), val('features_convert_to_genomio_json'), eval("features_convert_to_genomio_json --version"), emit: versions_features_combine_json, topic: versions

    script:
        def analysis_display_label_arg = analysis_display_label != null ? "--analysis-display-label '${analysis_display_label}'" : ''
        def analysis_description_arg = analysis_description != null ? "--analysis-description '${analysis_description}'" : ''
        def program_name_arg = program_name != null ? "--program '${program_name}'" : ''
        def program_parameters_arg = program_parameters != null ? "--program-parameters '${program_parameters}'" : ''
        def annotation_provider_arg = annotation_provider != null ? "--source-provider '${annotation_provider}'" : ''
        def primary_provider = (is_primary_source in [true, 'true', 'TRUE', '1']) ? '--is-primary' : ''
        """
        args=(
            --input ${features_out}
            --analysis-logic-name '${analysis_logic_name}'
            --output ${meta.id}.${analysis_logic_name}.features.json
            ${analysis_display_label_arg}
            ${analysis_description_arg}
            ${program_name_arg}
            --program-version '${program_version}'
            ${program_parameters_arg}
            ${annotation_provider_arg}
            ${primary_provider}
        )

        if [[ "${consensus_lib_fasta.name}" != "NO_FILE" ]]; then
            args+=( --rm-consensus-lib ${consensus_lib_fasta} )
        fi

        features_convert_to_json "\${args[@]}"
        """

    stub:
        """
        set -euo pipefail

        out_json="${meta.id}.${analysis_logic_name}.features.json"
        used_consensus_lib=false

        if [[ "${consensus_lib_fasta.name}" != "NO_FILE" ]]; then
            used_consensus_lib=true
            repeat_consensus='[
                {
                    "name": "stub_consensus",
                    "repeat_type": "stub",
                    "repeat_class": "stub"
                }
            ]'
        else
            repeat_consensus='[]'
        fi

        cat > "\$out_json" <<-EOF
{
    "analysis": {
        "logic_name": "${analysis_logic_name}",
        "description": "Stub features output"
    },
    "source": {
        "source_provider": "stub",
        "program_version": "${program_version}"
    },
    "repeat_consensus": \$repeat_consensus,
    "repeat_features": [
        {
            "seq_region_name": "${meta.chunk_id ?: meta.id}",
            "repeat_type": "stub",
            "repeat_class": "stub",
            "used_consensus_lib": \$used_consensus_lib
        }
    ]
}
EOF
        """
}