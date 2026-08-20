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

process TAXONOMY_CLASSIFICATION {
    tag "${meta.id}"
    label 'process_small'

    conda "${moduleDir}/environment.yml"
    container "ensemblorg/datasets-cli:latest"

    input:
        record(
            meta:    Map,
            species: String
        )

    output:
        record(
            meta: meta,
            species: species,
            json: file("classification.json")
        )

    topic:
        tuple("${task.process}", 'datasets', eval('datasets --version | sed "s/^.*datasets version: //"')) >> 'versions'

    script:
        """
        echo "Calling datasets-cli for ${species}"
        datasets summary taxonomy taxon"${species}" --report names --parents --rank "domain,kingdom,phylum,class,order,family,genus,species,subspecies" > report.json
        if [[ $(jq -r '.total_count' report.json) -eq "0" ]]; then
            echo "No classification found for ${species}" >&2
            exit 1
        fi
        
        jq -c '[.reports[].taxonomy.current_scientific_name.name]' report.json > classification.json
        """

    stub:
        """
        cat <<'EOF' > classification.json
        ["cellular organisms", "Eukaryota", "Viridiplantae"]
        EOF
        """
}

