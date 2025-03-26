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

include { METADATA_GENOMESUMMARY } from '../../../modules/ensembl/metadata/genomesummary'
include { SCHEMA_JSON } from '../../../modules/ensembl/schema/json'

import groovy.json.JsonSlurper
def readJson(json_path) {
    def slurp = new JsonSlurper()
    def json_file = file(json_path)
    def text = json_file.text
    def not_a_lazy_val = slurp.parseText(text)
    return not_a_lazy_val
}

// function to create meta tuple from genome.json in the form:
// tuple("accession": accession, "production_name": production_name, "prefix": prefix)
def metaFromGenomeJson(json_path) {
    def data = readJson(json_path)

    def prod_name = data.assembly.accession
    def publish_dir = data.assembly.accession

    if ( data.species && data.species.production_name ) {
        prod_name = data.species.production_name
        publish_dir = prod_name
    }
    def has_annotation = false
    if (data.annotation) {
        has_annotation = true
    }

    return [
        accession: data.assembly.accession,
        production_name: prod_name,
        publish_dir: publish_dir,
        prefix: "",
        has_annotation: has_annotation,
    ]
}

workflow PREPARE_GENOME_METADATA {

    take:
        input                   // channel: [ val(meta), path(query_json), path(genome_summary_json) ]

    main:
        channel_versions = Channel.empty()

        METADATA_GENOMESUMMARY(input)
            .meta_json
            .map{ meta, json_file -> tuple(meta + metaFromGenomeJson(json_file), json_file) }
            .set { genome_metadata }
        
        SCHEMA_JSON(genome_metadata)
            .verified_json
            .set { verified_genome_json }

        channel_versions.mix(METADATA_GENOMESUMMARY.versions, SCHEMA_JSON.versions)

    emit:
        prepared_metadata = verified_genome_json // channel: [ val(meta), path(json) ]
        versions = channel_versions      // channel: [ path(versions.yml), path(versions.yml) ]
}

