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

process FEATURES_COMBINE_JSON {
    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "docker.io/ensemblorg/ensembl-genomio:v1.7.0"

    input:
        tuple val(meta), val(analysis), path(json_manifest), path(agp)

    output:
        tuple val(meta), path("${meta.id}.${analysis}.json"), emit: combined_json
        tuple val("${task.process}"), val('features_combine_json'), eval("features_combine_json --version"), emit: versions_features_combine_json, topic: versions

    when:
        task.ext.when == null || task.ext.when

    script:
        def args = []

        if (params.chunk_id_regex) {
            def rx = params.chunk_id_regex.replace("'", "'\"'\"'")
            args << "--chunk-id-regex '${rx}'"
        }

        if (params.allow_revcomp) {
            args << "--allow-revcomp"
        }

        def has_agp = agp && agp.baseName != 'NO_FILE'
        if (has_agp) {
            args << "--agp-file '${agp}'"
        }

        def out_json = "${meta.id}.${analysis}.json"

        """
        features_combine_json \\
            --json-manifest '${json_manifest}' \\
            --out-json '${out_json}' \\
            ${args.join(' ')}
        """

    stub:
        """
        cat > "${meta.id}.${analysis}.json" <<'EOF'
        {}
        EOF
        """
        
}
