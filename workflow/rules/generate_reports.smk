rule multimodal_withinsubj_wholewm_desc_stats:
    input:
        dwi="data/derivatives/dwi_stats.pickle",
        ihmt="data/derivatives/ihmt_stats.pickle",
        mp2rage="data/derivatives/MP2RAGE_stats.pickle",
        qMT="data/derivatives/qMT_stats.pickle"
    output:
        "data/derivatives/multimodal_withinsubj_wholewm_desc_stats.csv" 
    conda:
        "../envs/stats_plots.yaml"
    log:
        "logs/multimodal_withinsubj_wholewm_desc_stats.ipynb"
    notebook:
        "../notebooks/multimodal_withinsubj_wholewm_desc_stats.py.ipynb"


rule view_wholewm_desc_stats_datavzrd:
    input:
        config="config/datavzrd_wholewm_desc_stats.yaml",
        desc_stats="data/derivatives/multimodal_withinsubj_wholewm_desc_stats.csv",
    output:
        report(
            directory("reports/tables/wholewm"),
            htmlindex="index.html",
            caption="report/wholewm.rst",
            category="Tables",
            labels={"table": "Whole White Matter Descriptive Statistics"},
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