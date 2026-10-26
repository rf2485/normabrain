# rule multimodal_withinsubj_wholewm_desc_stats:
#     input:
#         wm90percent_mask="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/masks_segs/sub-{subject}_ses-{session}_acq-{mp2rage_params}_wm90percent_mask.nii.gz",
#         mp2rage_R1map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_R1map_b1corr_brain.nii.gz",
#         qMT_R1map="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map.nii.gz",
#         qMT_MPFmap="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_MPFmap.nii.gz",
#         qMT_MTRmap="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_MTRmap.nii.gz",
#         dki_dir="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/",
#     params:
#         #ihMTR depending on contrast type
#         ihMTR_cosmod="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_cosmod_ihMTR.nii.gz",
#         ihMTR_freqalt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_freqalt_ihMTR.nii.gz",
#         dki_fa="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_fa.nii.gz",
#         dki_kfa="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_kfa.nii.gz",
#         dki_md="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_md.nii.gz",
#         dki_mkt="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_mkt.nii.gz",
#     output:
#         "data/derivatives/{field_strength}/stats/sub-{subject}/ses-{session}/multimodal_withinsubj_wholewm_desc_stats.csv" 
#     conda:
#         "../envs/stats_plots.yaml"
#     log:
#         "logs/multimodal_withinsubj_wholewm_desc_stats.ipynb"
#     notebook:
#         "../notebooks/multimodal_withinsubj_wholewm_desc_stats.py.ipynb"


rule view_wholewm_desc_stats_datavzrd:
    input:
        config="config/datavzrd_ihmt.yaml",
        desc_stats="data/derivatives/ihmt_wm90percent_lobes_stats_hist.csv",
        vref_stats="data/derivatives/ihmt_vref100vs80.csv",
        b1corr_stats="data/derivatives/ihmt_b1corr_vs_uncorr.csv",
        sym_stats="data/derivatives/ihmt_rightleft_symmetry.csv"
    output:
        report(
            directory("reports/tables/ihmt"),
            htmlindex="index.html",
            caption="report/ihmt.rst",
            category="Tables",
            labels={"table": "ihMT"},
        ),
    log:
            "logs/datavzrd.log"
    wrapper:
            "v9.16.0/utils/datavzrd"


rule wm90percent_lobes_desc_stats:
    input:
       "data/derivatives/{modality}_stats.pickle"
    output:
        "data/derivatives/{modality}_wm90percent_lobes_desc_stats.csv" 
    conda:
        "../envs/stats_plots.yaml"
    log:
        "logs/{modality}_wm90percent_lobes_desc_stats.ipynb"
    notebook:
        "../notebooks/wm90percent_lobes_desc_stats.py.ipynb"


rule ihmt_b1corr_test_retest:
    input:
        "data/derivatives/ihmt_stats.pickle"
    output:
        vref="data/derivatives/ihmt_vref100vs80.csv",
        b1corr="data/derivatives/ihmt_b1corr_vs_uncorr.csv",
        sym="data/derivatives/ihmt_rightleft_symmetry.csv"
    conda:
        "../envs/stats_plots.yaml"
    log:
        "logs/ihmt_b1corr_test_retest.csv"
    notebook:
        "../notebooks/ihmt_b1corr_test_retest.py.ipynb"


rule view_ihmt_stats_datavzrd:
    input:
        config="config/datavzrd_ihmt.yaml",
        desc_stats="data/derivatives/ihmt_wm90percent_lobes_desc_stats.csv",
        vref_stats="data/derivatives/ihmt_vref100vs80.csv",
        b1corr_stats="data/derivatives/ihmt_b1corr_vs_uncorr.csv",
        sym_stats="data/derivatives/ihmt_rightleft_symmetry.csv"
    output:
        report(
            directory("reports/tables/ihmt"),
            htmlindex="index.html",
            caption="report/ihmt.rst",
            category="Tables",
            labels={"table": "ihMT"},
        ),
    log:
            "logs/datavzrd.log"
    wrapper:
            "v9.16.0/utils/datavzrd"