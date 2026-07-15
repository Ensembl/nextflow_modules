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

process FEATURES_CONVERT_TO_JSON {
    tag "${meta.id}"
    label 'process_small'
    container 'docker.io/ensemblorg/ensembl-genomio:v1.7.1'

    input:
        tuple val(meta), path(features_out), path(repeatmasker_consensus_lib)
        val(analysis_logic_name)
        val(program_version)
        val(program_parameters)
        val(annotation_provider)
        val(is_primary_source)

    output:
        tuple val(meta), path("${meta.id}.${analysis_logic_name}.features.json"), emit: features_json
        tuple val("${task.process}"), val('features_convert_to_genomio_json'), eval("features_convert_to_genomio_json --version"), emit: versions_convert_to_genomio_json, topic: versions

    script:
        def prefix = ''
        def repeatmasker_consensus_lib_arg = ''
        if (analysis_logic_name) {
            if (analysis_logic_name == 'trf') {
                prefix = 'trf'
            } else if (analysis_logic_name == 'repeatdetector') {
                prefix = 'red'
            } else if (analysis_logic_name == 'repeatmask_repbase') {
                prefix = 'repeatmasker repbase'
            } else if (analysis_logic_name == 'repeatmask_customlib') {
                prefix = 'repeatmasker custom'
                if (repeatmasker_consensus_lib == null || repeatmasker_consensus_lib.name == "NO_FILE") {
                    throw new IllegalArgumentException("RepeatMasker consensus library is required for analysis logic name '${analysis_logic_name}'")
                }
                repeatmasker_consensus_lib_arg = "--consensus-lib ${repeatmasker_consensus_lib}"
            } else {
                throw new IllegalArgumentException("Unsupported analysis logic name '${analysis_logic_name}'")
            }
        }

        def program_parameters_arg = program_parameters != null ? "--program-parameters '${program_parameters}'" : ''
        def annotation_provider_arg = annotation_provider != null ? "--source-provider '${annotation_provider}'" : ''
        def primary_provider = is_primary_source ? '--is-primary' : ''

        """
        features_convert_to_genomio_json ${prefix} \
            --input ${features_out} \
            --output ${meta.id}.${analysis_logic_name}.features.json \
            ${repeatmasker_consensus_lib_arg} \
            --program-version '${program_version}' \
            ${program_parameters_arg} \
            ${annotation_provider_arg} \
            ${primary_provider}
        """

    stub:
        """
        cat > "${meta.id}.${analysis_logic_name}.features.json" <<'EOF'
        {}
        EOF
        """
}