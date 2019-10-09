#!/usr/bin/env cwl-runner

class: Workflow
cwlVersion: v1.1
id: calculate-contamination

requirements:
- class: StepInputExpressionRequirement
- class: ScatterFeatureRequirement

inputs:
    contamination_name: string
    interval_files: File[]
    jvm_mem: int?
    merged_pileup_name: string
    normal_seq_file:
      type: File
      secondaryFiles: ['.bai?', '.crai?']
    pileup_summary_name: string
    ref_dict: File
    ref_fa: 
      secondaryFiles: 
        - .fai
        - ^.dict
      type: File
    segmentation_name: string
    tumour_seq_file:
      type: File
      secondaryFiles: ['.bai?', '.crai?']
    variants_for_contamination: 
      secondaryFiles: 
        - .tbi
      type: File


outputs:
  contamination_table:
    type: File
    outputSource: calculate_contamination/contamination_table
  tumour_segmentation_table:
    type: File
    outputSource: calculate_contamination/segmentation_table

steps:

  get_normal_pileup_summaries:
    run: https://raw.githubusercontent.com/icgc-argo/gatk-tools/gatk-get-pileup-summaries.4.1.3.0-1.1/tools/gatk-get-pileup-summaries/gatk-get-pileup-summaries.cwl
    scatter: intervals
    in:
      jvm_mem: jvm_mem
      ref_fa: ref_fa
      seq_file: normal_seq_file
      variants: variants_for_contamination
      intervals: interval_files
      output_name: pileup_summary_name
    out: [ pileups_table ]

  get_tumour_pileup_summaries:
    run: https://raw.githubusercontent.com/icgc-argo/gatk-tools/gatk-get-pileup-summaries.4.1.3.0-1.1/tools/gatk-get-pileup-summaries/gatk-get-pileup-summaries.cwl
    scatter: intervals
    in:
      jvm_mem: jvm_mem
      ref_fa: ref_fa
      seq_file: tumour_seq_file
      variants: variants_for_contamination
      intervals: interval_files
      output_name: pileup_summary_name
    out: [ pileups_table ]

  merge_normal_pileups:
    run: https://raw.githubusercontent.com/icgc-argo/gatk-tools/gatk-gather-pileup-summaries.4.1.3.0-1.0/tools/gatk-gather-pileup-summaries/gatk-gather-pileup-summaries.cwl
    in:
      jvm_mem: jvm_mem
      ref_dict: ref_dict
      input_pileup: get_normal_pileup_summaries/pileups_table
      output_name: merged_pileup_name
    out: [ merged_pileup ]

  merge_tumour_pileups:
    run: https://raw.githubusercontent.com/icgc-argo/gatk-tools/gatk-gather-pileup-summaries.4.1.3.0-1.0/tools/gatk-gather-pileup-summaries/gatk-gather-pileup-summaries.cwl
    in:
      jvm_mem: jvm_mem
      ref_dict: ref_dict
      input_pileup: get_tumour_pileup_summaries/pileups_table
      output_name: merged_pileup_name
    out: [ merged_pileup ]

  calculate_contamination:
    run: https://raw.githubusercontent.com/icgc-argo/gatk-tools/gatk-calculate-contamination.4.1.3.0-1.0/tools/gatk-calculate-contamination/gatk-calculate-contamination.cwl
    in:
      jvm_mem: jvm_mem
      tumour_pileups: merge_tumour_pileups/merged_pileup
      normal_pileups: merge_normal_pileups/merged_pileup
      segmentation_output: segmentation_name
      contamination_output: contamination_name
    out: [ segmentation_table, contamination_table ]


