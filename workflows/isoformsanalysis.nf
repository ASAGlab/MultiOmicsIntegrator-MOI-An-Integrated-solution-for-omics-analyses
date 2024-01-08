#!/usr/bin/env nextflow


nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


params.fasta         = WorkflowMain.getGenomeAttribute(params, 'fasta')
params.gtf           = WorkflowMain.getGenomeAttribute(params, 'gtf')
params.gff           = WorkflowMain.getGenomeAttribute(params, 'gff')
params.bbsplit_index = WorkflowMain.getGenomeAttribute(params, 'bbsplit')
params.hisat2_index  = WorkflowMain.getGenomeAttribute(params, 'hisat2')


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE & PRINT PARAMETER SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//WorkflowIsoformsanalysis.initialise(workflow, params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOW FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
//workflows
include { QUALITYCONTROL } from './qualitycontrol'

include { ALIGNASSEMBLYISO } from './alignassemblyiso.nf'
include { ALIGNASSEMBLYMIRNA } from './alignassemblymirna.nf'
include { ISOFORMSPART1 } from './isoformspart1.nf'
include { ISOFORMSPART1A } from './isoformspart1a.nf'
include { PROTEINS } from './proteins.nf'
include { LIPIDS } from './lipids.nf'
include { DEA } from './dea.nf'
include {SRA}  from './sra.nf'
//subworkflows
include { FUNCTIONAL_ANNOTATION } from '../subworkflows/local/functional_annotation'
include { ISOFORMSPART2 } from '../subworkflows/local/isoformspart2'
include { ISOVISUAL} from '../subworkflows/local/isovisual'
include { PREPROCESS_MATRIX } from '../subworkflows/local/preprocess_matrix'
// default subworkflows
include { INPUT_CHECK } from '../subworkflows/local/input_check'
//modules
include { CAT_FASTQ                   } from '../modules/nf-core/cat/fastq/main'
include {SALMON_INDEX_ONLYFASTA              } from '../modules/nf-core/salmon/index_onlyfasta/main'
include { PREPARE_GENOME } from '../subworkflows/local/prepare_genome_isoforms'
include { SANITY                   } from '../modules/local/sanity/main'
include { ISOMCIA                  } from '../modules/local/isomcia/main'

// Check alignment parameters
def prepareToolIndices  = []
if (!params.skip_bbsplit_isoforms)   { prepareToolIndices << 'bbsplit'             }
if (!params.skip_alignment_isoforms) { prepareToolIndices << params.aligner_isoforms        }
if (!params.skip_pseudo_alignment_isoforms && params.pseudo_aligner_isoforms) { prepareToolIndices << params.pseudo_aligner_isoforms }



if(params.isoforms){
    if (params.input_isoforms) { ch_input = file(params.input_isoforms) } else { exit 1, 'Input samplesheet not specified!' }
}
// Read in ids from --input file
Channel
    .from(file(params.input_isoforms, checkIfExists: true))
    .splitCsv(header:true, sep:'', strip:true)
    .map { it.sample }
    .unique()
    .set { ch_ids_isoforms }


//
// WORKFLOW: Run main isoformanalysis pipeline
//
workflow ISOFORMSANALYSIS {

    ch_versions = Channel.empty()

if(params.isoforms){
    if(params.sra_isoforms){
        SRA(ch_ids_isoforms)
        ch_input_isoforms=  SRA.out.samplesheet
    }
}


if (params.isoforms){
    if (!params.skip_alignment_isoforms) {
            if (!params.skip_qc_isoforms) {
        QUALITYCONTROL(ch_input_isoforms, params.ribo_database_manifest, params.bbsplit_fasta_list_isoforms)
        ALIGNASSEMBLYISO(QUALITYCONTROL.out.filtered_reads)
        ISOFORMSPART1(params.salmonDirIso, params.input_isoforms, params.gtf_isoforms, ALIGNASSEMBLYISO.out.salmon_fasta, ALIGNASSEMBLYISO.out.salmon_outfiles)
        FUNCTIONAL_ANNOTATION(ISOFORMSPART1.out.nt_iso_part1, ISOFORMSPART1.out.aa_iso_part1)
        ISOFORMSPART2(ISOFORMSPART1.out.iso_part1_switchlist, FUNCTIONAL_ANNOTATION.out.out_cpat, FUNCTIONAL_ANNOTATION.out.out_pfam, FUNCTIONAL_ANNOTATION.out.out_signal, params.isopart2reduceToSwitchingGenes, params.saturn_run, params.saturn_fdr, params.saturn_fc)
        ISOVISUAL(ISOFORMSPART2.out.switchdexseq, params.topisoforms, params.isoformstosee)
        de_isoforms=ISOFORMSPART2.out.de_isoforms
        switchList = ISOFORMSPART2.out.switchdexseq
        ISOMCIA(ISOFORMSPART2.out.isoforms)
    } else if (params.skip_qc_isoforms) {
        INPUT_CHECK(ch_input_isoforms).reads
            .map { meta, fastq ->
                def meta_clone = meta.clone()
                meta_clone.id = meta_clone.id.split('_')[0..-2].join('_')
                [meta_clone, fastq]
            }
            .groupTuple(by: [0])
            .branch {
                meta, fastq ->
                    single: fastq.size() == 1
                            return [meta, fastq.flatten()]
                    multiple: fastq.size() > 1
                               return [meta, fastq.flatten()]
            }
            .set { ch_fastq }
        ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

        CAT_FASTQ(ch_fastq.multiple).reads
            .mix(ch_fastq.single)
            .set { ch_cat_fastq }
        ch_versions = ch_versions.mix(CAT_FASTQ.out.versions.first().ifEmpty(null))

        if (!params.skip_pseudo_alignment_isoforms) {
            ALIGNASSEMBLYISO(ch_cat_fastq)
            ISOFORMSPART1(params.salmonDirIso, params.input_isoforms, params.gtf_isoforms, ALIGNASSEMBLYISO.out.salmon_fasta, ALIGNASSEMBLYISO.out.salmon_outfiles)
            FUNCTIONAL_ANNOTATION(ISOFORMSPART1.out.nt_iso_part1, ISOFORMSPART1.out.aa_iso_part1)
            ISOFORMSPART2(ISOFORMSPART1.out.iso_part1_switchlist, FUNCTIONAL_ANNOTATION.out.out_cpat, FUNCTIONAL_ANNOTATION.out.out_pfam, FUNCTIONAL_ANNOTATION.out.out_signal, params.isopart2reduceToSwitchingGenes, params.saturn_run, params.saturn_fdr, params.saturn_fc)
            ISOVISUAL(ISOFORMSPART2.out.switchdexseq, params.topisoforms, params.isoformstosee)
            switchList = ISOFORMSPART2.out.switchdexseq
            de_isoforms=ISOFORMSPART2.out.de_isoforms
            ISOMCIA(ISOFORMSPART2.out.isoforms)
        }
    }
} else if (params.skip_pseudo_alignment_isoforms) {
    
    //ISOFORMSPART1A(params.salmonDirIso,params.input_isoforms, params.gtf_isoforms, params.fasta_salmon_isoforms)
    
    def biotype = params.gencode_isoforms ? "gene_type" : params.featurecounts_group_type_isoforms
    PREPARE_GENOME (
        prepareToolIndices, biotype, false ,params.salmon_index_isoforms
    )
    ISOFORMSPART1A(params.salmonDirIso,params.input_isoforms, PREPARE_GENOME.out.gtf, PREPARE_GENOME.out.salmon_fasta)
    FUNCTIONAL_ANNOTATION(ISOFORMSPART1A.out.nt_iso_part1, ISOFORMSPART1A.out.aa_iso_part1)
    ISOFORMSPART2(ISOFORMSPART1A.out.iso_part1_switchlist, FUNCTIONAL_ANNOTATION.out.out_cpat, FUNCTIONAL_ANNOTATION.out.out_pfam, FUNCTIONAL_ANNOTATION.out.out_signal, params.isopart2reduceToSwitchingGenes, params.saturn_run, params.saturn_fdr, params.saturn_fc)
    ISOVISUAL(ISOFORMSPART2.out.switchdexseq, params.topisoforms, params.isoformstosee)
    switchList = ISOFORMSPART2.out.switchdexseq
    de_isoforms=ISOFORMSPART2.out.de_isoforms
    ISOMCIA(ISOFORMSPART2.out.isoforms)
}
}


else if(!params.isoforms){
    SANITY("isoforms")
    de_isoforms = SANITY.out.sanity
}
emit:
de_isoforms = de_isoforms
}



/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
