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
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/ensembl-genomio:1.6.1--pyhdfd78af_0'
        : 'biocontainers/ensembl-genomio:1.6.1--pyhdfd78af_0'}"

    input:
        tuple val(meta), path(json_manifest), path(agp)

    output:
        tuple val(meta), path("${meta.id}.${meta.analysis}.json"), emit: combined_json
        tuple val("${task.process}"), val('features_combine_json'), eval('echo 1.6.1'), emit: versions_features_combine_json, topic: versions

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

        def out_json = "${meta.id}.${meta.analysis}.json"

        """
        features_combine_json \\
            --json-manifest '${json_manifest}' \\
            --out-json '${out_json}' \\
            ${args.join(' ')}
        """

    stub:
        """
        set -euo pipefail

        out_json="${meta.id}.${meta.analysis}.json"

        test -s "${json_manifest}"

        agp_path="${agp}"
        agp_name="\${agp_path##*/}"

        manifest_real="\$(python -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "${json_manifest}")"
        manifest_dir="\$(dirname "\$manifest_real")"

        first_json="\$(head -n 1 "${json_manifest}")"
        if [[ -z "\$first_json" ]]; then
            echo "ERROR: manifest is empty: ${json_manifest}" >&2
            exit 1
        fi
        if [[ "\$first_json" != /* ]]; then
            first_json="\${manifest_dir}/\${first_json}"
        fi
        if [[ ! -s "\$first_json" ]]; then
            echo "ERROR: first JSON in manifest does not exist or is empty: \$first_json" >&2
            exit 1
        fi

        if grep -q '"ncrna_features"' "\$first_json"; then
            load_type="ncrna"
        elif grep -q '"repeat_features"' "\$first_json"; then
            load_type="repeat"
        else
            echo "ERROR: cannot detect load type from first JSON: \$first_json" >&2
            echo "Expected top-level key: 'repeat_features' or 'ncrna_features'." >&2
            exit 1
        fi

        if [[ "\$load_type" == "repeat" ]]; then
            cat > "\$out_json" <<-EOF
{
    "analysis": {
        "logic_name": "stub_repeat"
    },
    "source": {
        "source_provider": "stub"
    },
    "repeat_consensus": [],
    "repeat_features": []
}
EOF
        else
            cat > "\$out_json" <<-EOF
{
    "analysis": {
        "logic_name": "stub_ncrna"
    },
    "source": {
        "source_provider": "stub"
    },
    "ncrna_tool": "stub",
    "ncrna_features": []
    }
EOF
        fi

        """
        
}
