# nf-core/MOM: Output

## Introduction

This document describes the output produced by the pipeline. 

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

<!-- TODO nf-core: Write this documentation describing your workflow's output -->

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and performs the following steps:

1. RNAseq analysis on the level of :
   - mRNAs 
   - miRNAs
   - isoforms including lncRNAs
2. Functional annotation of transcripts
3. Lipidomics analysis
4. Proteomics analysis
5. Integration of multi omics data

See diagram:
[diagram.png](/docs/images/Figure_1.png) 

## RNAseq analysis

Plots included here are generated from RNAseq data however similar plots can be generated for proteomic data if provided with a count matrix and a samples info file:

[de_rnaprotmirna](/docs/images/Figure_3.png) 
Box plots of samples before and after filtering and normalizations steps (A) as well as PCA plots of raw and cleaned for batch effect samples (B) provide quality control of the data. Heatmaps (C) and Volcano plots (D) offer visual indications of differentially expressed features.

<details markdown="1">
<summary>Output files</summary>

- `genes/`
  - `filt` : Directory of filtered matrices.
  - `norm` : Directory of normalized matrices.
  - `edger` (or rankprod or deseq2) : Directory of differentially expressed features.
  - `clusterprofiler` : Directory of pathway enrichment analysis

</details>

## Isoform analysis

[Isoform analysis](/images/Figure_2.png) 
(A) Different isoforms of SNCA mRNA are detected and annotated with respect to their coding potential and protein domains. Moreover, the relative expression of the gene is displayed along with the relative expression of the isoforms as well as the fraction of the isoforms used. (B) Bar plots representing the number of genes encompassing functional implications of isoform switching. (C) Dot-plots representing which of the functional implications of isoform switching are statistically significant between conditions. (D) Violin plots depicting the number of isoforms hosting functional implications of isoform switching. 

<details markdown="1">
<summary>Output files</summary>

- `isoforms/`
  - `isopart1`: Directory of first part of analysis from isoformSwitchAnalyzer. 
  - `isopart2`: Directory of second part of analysis from isoformSwitchAnalyzer. 
  - `isovisual` : Directory of visualization part of analysis from isoformSwitchAnalyzer. 
</details>

## Lipidomics analysis

Plots included here are generated if the user chose lipidr = true

[lipids](/images/Figure_4.png) 
(A) Box plots of samples before and after filtering and normalizations steps as well as (B) PCA plots of raw and cleaned for batch effect samples provide quality control of the data. (C) Heatmaps and (D) Volcano plots  offer visual indications of differentially expressed features.

Otherwise similar plots to those shown in [de_rnaprotmirna] will be generated.

<details markdown="1">
<summary>Output files</summary>

- `lipids/`
  - `lipidr/`  : Directory with extensive lipidomics analysis

</details>

## Integration

Plots included here are generated from RNAseq data however similar plots can be generated for proteomic data if provided with a count matrix and a samples info file:

[MCIA](/docs/images/Figure_5.png) 
(A) MCIA reports the PCA of the sample space where we can see how samples differentiate according to the phenotype of interest. In addition, variables are projected on the same space (B) to explore the relative contribution of each variable to the distinction of the phenotypes. Elbow plots (C) inform us about the significant principal components and in panel (D) the space of the pseudo-eigen values of the different datasets is displayed, as an indication of the relative contribution of each dataset to the overall variance. 

[clusterprofiler](/docs/images/Figure_6.png) 
Clusterprofiler can be utilized by individual analyses or after the integration step of MCIA. Outputs include heatmaps of enriched processes (A) and the top features that participate in these processes (B), as well as tree plots of significant pathways (C) and the network that these pathways form (D). 

<details markdown="1">
<summary>Output files</summary>

- `mcia/`
  - `mcia_results/`: Directory of mcia results, including MCIA report and analysis from clusterprofiler

</details>

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.