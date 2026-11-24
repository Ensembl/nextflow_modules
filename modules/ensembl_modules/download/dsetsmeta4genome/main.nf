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

process DOWNLOAD_DSETSMETA4GENOME {
    tag "$meta.id"
    label 'process_low'
    container 'ensemblorg/datasets-cli:v16.33.0'

    input:
        val(meta)  // with keys [ id, accession ]

    output:
        tuple val(meta), path("ncbi_stats.json")
        path "versions.yml", emit: versions

    when:
        task.ext.when == null || task.ext.when

    shell:
        output = "ncbi_stats.json"
        '''
        echo "Calling datasets-cli.... datasets 'summary' 'genome' 'accession' [!{meta.accession}]'"

        # Pipe datasets to jq instead of '--as-json-lines' to 
        # obtain a total_count of reports returned.
        datasets summary genome accession !{meta.accession} | jq '.' > !{output}

        if [ "$?" -ne 0 ]; then
            echo "Invalid or unsupported assembly accession: !{meta.accession}"
            exit 1
        fi

        # Check if it should maybe be using RefSeq?
        if [[ $(jq '.total_count' !{output}) -eq 0 ]] && [[ !{meta.accession} =~ "GCA_" ]]; then
            accession=$(echo !{meta.accession} | sed 's/^GCA_/GCF_/')
            echo "Trying again with RefSeq accession: $accession"
            datasets summary genome accession $accession | jq '.' > !{output}
        fi

        # Get version from datasets and jq
        cat <<-END_VERSIONS > versions.yml
        "!{task.process}":
            NcbiDatasets: $(datasets  --version | cut -f 2 -d :)
            Jq: $(jq --version)
        END_VERSIONS
        '''
    
    stub:
        output_file = "ncbi_stats.json"
        '''
        touch $output_file

        # Get version from datasets and jq
        cat <<-END_VERSIONS > versions.yml
        "!{task.process}":
            NcbiDatasets: $(datasets  --version | cut -f 2 -d :)
            Jq: $(jq --version)
        END_VERSIONS
        '''
}
