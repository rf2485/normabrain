rule filter_data:
    input:
       "data/derivatives/3T/ihmt/ihmt_stats.csv"
    output:
        "data/derivatives/3T/ihmt/ihmt_stats_filteredROIs.csv" 
    conda:
        "../envs/stats_plots.yaml"
    log:
        "logs/3T/ihmt/ihmt_stats_filteredROIs.ipynb"
    notebook:
        "../notebooks/ihmt_stats_filteredROIs.py.ipynb"


rule view_ihmt_stats_datavzrd:
    input:
        config="config/datavzrd_ihmt.yaml",
        table="data/derivatives/3T/ihmt/ihmt_stats_filteredROIs.csv"
    output:
        report(
            directory("reports/tables/ihmt"),
            htmlindex="index.html",
            caption="report/ihmt.rst",
            category="Tables",
            labels={"table": "cars"},
        ),
    log:
            "logs/datavzrd.log"
    wrapper:
            "v9.16.0/utils/datavzrd"