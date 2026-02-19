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

process REPEATS_COMBINE_JSON {

    tag "${meta.id}"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "ensemblorg/ensembl-genomio:v1.6.1"

    input:
        tuple val(meta), path(json_manifest), path(agp)

    output:
        tuple val(meta), path("${meta.id}.repeat.json"), emit: combined_json

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
            args << "--agp-file ${agp}"
        }

        def out_json = "${meta.id}.repeat.json"

        """
        python -m ensembl.io.genomio.repeats.combine_json \\
            --json-manifest ${json_manifest} \\
            --out-json ${out_json} \\
            ${args.join(' ')}
        """

    stub:
        """
        set -euo pipefail

        test_data_dir="${moduleDir}/tests/data"

        out_json="${meta.id}.repeat.json"

        test -s "${json_manifest}"

        mode="header"
        agp_path="${agp}"
        agp_name="\${agp_path##*/}"
        if [[ "\$agp_name" != "NO_FILE" ]]; then
            mode="agp"
        fi

        # Provide a schema-valid combined JSON fixture.
        # Arrange fixtures under:
        #   tests/data/header/output/<id>.repeat.json
        #   tests/data/agp/output/<id>.repeat.json
        cp "\$test_data_dir/\$mode/output/${meta.id}.repeat.json" "\$out_json"
        """
}
