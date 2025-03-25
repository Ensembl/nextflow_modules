// TODO nf-core: If in doubt look at other nf-core/subworkflows to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/subworkflows
//               You can also ask for help via your pull request or on the #subworkflows channel on the nf-core Slack workspace:
//               https://nf-co.re/join

include { METADATA_FETCH } from '../../../modules/ensembl/metadata/fetch/main.nf'

// function to create meta tuple from genome.json in the form:
// tuple("accession": accession, "production_name": production_name, "prefix": prefix)
def metaFromGenomeJson(json_path) {
    def data = read_json(json_path)

    def prod_name = data.assembly.accession
    def publish_dir = data.assembly.accession
    if ( params.brc_mode ) {
        prod_name = data.BRC4.organism_abbrev
        publish_dir = "${data.BRC4.component}/${data.BRC4.organism_abbrev}"
    } else if ( data.species && data.species.production_name ) {
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
        input                              // channel: [ path(json) ]

    main:

    // ch_versions = Channel.empty()
        METADATA_FETCH(input)
            .map{ meta, json_file -> tuple(meta + metaFromGenomeJson(json_file), json_file) }
            .set { genome_metadata }

    emit:
    // genome_metadata      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    genome_metadata // channel: [ val(meta) ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

