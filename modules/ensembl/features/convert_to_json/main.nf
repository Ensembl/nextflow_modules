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

nextflow.enable.types = true

process FEATURES_CONVERT_TO_JSON {
    tag "${meta.id}"
    label 'process_small'
    container 'docker.io/ensemblorg/ensembl-genomio:v1.7.0'

    input:
        record(
            meta: Map,
            features_out: Path,
            repeatmasker_consensus_lib: Path?,
            analysis_logic_name: String,
            program_version: String,
            program_parameters: String?,
            annotation_provider: String?,
            analysis_description: String?,
            analysis_display_label: String?,
            prod_host: String?,
            prod_database: String?,
            prod_user: String?,
            prod_port: Integer?,
            prod_password: String?,
            is_primary_source: Boolean
        )

    output:
        features_json = record(
            meta: meta,
            features_json: file("${meta.id}.${analysis_logic_name}.features.json"),
            invalid_tool_output: file("${meta.id}.${analysis_logic_name}.features.invalid_tool_output.txt")
        )

    topic:
        tuple(task.process, 'features_convert_to_genomio_json', eval("features_convert_to_genomio_json --version 2>/dev/null || echo unknown")) >> 'versions'

    script:
        def prefix = ''
        def repeatmasker_consensus_lib_arg = ''
        if (analysis_logic_name) {
            def repeatmasker_analyses = ['repeatmask_repbase', 'repeatmask_customlib']
            if (repeatmasker_analyses.contains(analysis_logic_name)) {
                if (repeatmasker_consensus_lib == null || repeatmasker_consensus_lib.name == 'NO_FILE') {
                    throw new IllegalArgumentException(
                        "RepeatMasker consensus library is required for analysis logic name '${analysis_logic_name}'"
                    )
                }
                repeatmasker_consensus_lib_arg = "--consensus-lib ${repeatmasker_consensus_lib}"
            }
            if (analysis_logic_name == 'trf') {
                prefix = 'trf'
            } else if (analysis_logic_name == 'repeatdetector') {
                prefix = 'red'
            } else if (analysis_logic_name == 'repeatmask_repbase') {
                prefix = 'repeatmasker repbase'
            } else if (analysis_logic_name == 'repeatmask_customlib') {
                prefix = 'repeatmasker custom'
            } else if (analysis_logic_name == 'trnascan') {
                prefix = 'trnascan'
            } else {
                throw new IllegalArgumentException("Unsupported analysis logic name '${analysis_logic_name}'")
            }
        }

        def program_parameters_arg = program_parameters != null ? "--program-parameters '${program_parameters}'" : ''
        def annotation_provider_arg = annotation_provider != null ? "--source-provider '${annotation_provider}'" : ''
        def analysis_description_arg = analysis_description != null ? "--analysis-description '${analysis_description}'" : ''
        def analysis_display_label_arg = analysis_display_label != null ? "--analysis-display-label '${analysis_display_label}'" : ''
        def prod_host_arg = prod_host != null ? "--prod_host '${prod_host}'" : ''
        def prod_database_arg = prod_database != null ? "--prod_database '${prod_database}'" : ''
        def prod_user_arg = prod_user != null ? "--prod_user '${prod_user}'" : ''
        def prod_port_arg = prod_port != null ? "--prod_port '${prod_port}'" : ''
        def prod_password_arg = prod_password != null ? "--prod_password '${prod_password}'" : ''
        def primary_provider = is_primary_source ? '--is-primary' : ''
        def args = task.ext.args ?: ''

        """
        touch ${meta.id}.${analysis_logic_name}.features.invalid_tool_output.txt

        features_convert_to_genomio_json ${prefix} \
            --input ${features_out} \
            --output ${meta.id}.${analysis_logic_name}.features.json \
            ${repeatmasker_consensus_lib_arg} \
            --program-version '${program_version}' \
            ${program_parameters_arg} \
            ${annotation_provider_arg} \
            ${analysis_description_arg} \
            ${analysis_display_label_arg} \
            ${prod_host_arg} \
            ${prod_database_arg} \
            ${prod_user_arg} \
            ${prod_port_arg} \
            ${prod_password_arg} \
            ${primary_provider} \
            ${args}
        """

    stub:
        """
        cat > "${meta.id}.${analysis_logic_name}.features.json" <<'EOF'
        {}
        EOF
        cat > "${meta.id}.${analysis_logic_name}.features.invalid_tool_output.txt" <<'EOF'
        stub invalid output
        EOF
        """
}
