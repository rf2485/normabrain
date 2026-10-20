#for creating data/rawdata folder structure necessary for the rest of the pipeline

import os
from pathlib import Path

def get_dicoms_folders(wildcards):
    checkpoint_output = checkpoints.symlink_dicoms_by_field_strength.get(**wildcards).output[0]
    return expand(os.path.join(checkpoint_output, "{field_strength}"),
        field_strength=wildcards.field_strength)

def check_bidscoiner_ran(wildcards):
    checkpoint_output = checkpoints.bidscoiner.get(**wildcards).output[0]
    return checkpoint_output

def aggregate_add_csa(wildcards): 
    #based on dicoms subdirectories (which correspond to field strength), return the list of add_csa_data_to_meta output
    dicoms_folder = checkpoints.symlink_dicoms_by_field_strength.get(**wildcards).output[0]
    return expand("data/rawdata/bids/{field_strength}/code/bidscoin/fixmeta.log", field_strength=next(os.walk(dicoms_folder))[1])

def aggregate_qmt_renames(wildcards):
    dicoms_folder = checkpoints.symlink_dicoms_by_field_strength.get(**wildcards).output[0]
    return expand(
        "data/rawdata/bids/{field_strength}/code/bidscoin/qmt_acquisitions_renamed.done",
        field_strength=next(os.walk(dicoms_folder))[1],
    )

def get_asl_contexts(field_strength):
    bids_root = Path(
        checkpoints.bidscoiner.get(field_strength=field_strength)
        .output[0]
    ).parent
    return [
        path.with_name(path.name.replace("_asl.json", "_aslcontext.tsv"))
        for path in bids_root.rglob("*_asl.json")
        if "_rec-" not in path.name
    ]

def aggregate_asl_contexts(wildcards):
    dicoms_folder = checkpoints.symlink_dicoms_by_field_strength.get(**wildcards).output[0]
    return [
        context
        for field_strength in next(os.walk(dicoms_folder))[1]
        for context in get_asl_contexts(field_strength)
    ]


checkpoint symlink_dicoms_by_field_strength:
    input:
        expand("{input_dicoms_path}", input_dicoms_path=config["input_dicoms_path"])
    params:
        subject_list=config["subject_list_dicom"]
    output:
        update(directory("data/rawdata/dicoms"))
    conda:
        "../envs/bidscoin.yaml"
    threads: 1
    log:
        "logs/symlink_dicoms_by_field_strength.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        if [ "{params.subject_list}" = "*" ]; then
            python workflow/scripts/symlink_dicoms_by_field_strength.py "{input}" "{output}" "*"
        else
            python workflow/scripts/symlink_dicoms_by_field_strength.py "{input}" "{output}" {params.subject_list}
        fi
        """


rule bidsmapper:
    input:
        get_dicoms_folders
    output:
        "data/rawdata/bids/{field_strength}/code/bidscoin/bidsmap.yaml"
    params:
        outdir="data/rawdata/bids/{field_strength}",
        template="config/bidsmap_normabrain_template",
        outcode="data/rawdata/bids/{field_strength}/code/bidscoin/bidsmapper.log"
    conda:
        "../envs/bidscoin.yaml"
    threads: 1
    log:
        "logs/{field_strength}/bidsmapper.log"
    shell:
        """
        bidsmapper {input} {params.outdir} -t {params.template} -a
        touch {output}
        cp {params.outcode} {log}
        """


checkpoint bidscoiner:
    input:
        rules.bidsmapper.output,
        dicoms = get_dicoms_folders
    output:
        "data/rawdata/bids/{field_strength}/participants.tsv"
    params:
        outdir="data/rawdata/bids/{field_strength}",
        outcode="data/rawdata/bids/{field_strength}/code/bidscoin/bidscoiner.log"
    conda:
        "../envs/bidscoin.yaml"
    threads: 1
    log:
        "logs/{field_strength}/bidscoiner.log"
    shell:
        """
        bidscoiner {input.dicoms} {params.outdir}
        touch {output}
        cp {params.outcode} {log}
        """


checkpoint add_csa_data_to_meta:
    input:
        bidscoiner = check_bidscoiner_ran
    output:
        "data/rawdata/bids/{field_strength}/code/bidscoin/fixmeta.log"
    params:
        outdir="data/rawdata/bids/{field_strength}"
    conda:
        "../envs/bidscoin.yaml"
    threads: 1
    log:
        "logs/{field_strength}/add_csa_data_to_meta.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        python workflow/scripts/add_csa_data_to_meta.py {params.outdir}
        """


rule generate_aslcontext:
    input:
        json="{prefix}_asl.json",
        nifti="{prefix}_asl.nii.gz"
    output:
        context="{prefix}_aslcontext.tsv"
    params:
        pattern=lambda wildcards: config.get("asl_context_pattern", ""),
        m0_indexes=lambda wildcards: config.get("asl_m0_indexes", "")
    conda:
        "../envs/bidscoin.yaml"
    threads: 1
    shell:
        """
        args=()
        if [ -n "{params.pattern}" ]; then
            args+=(--pattern "{params.pattern}")
        fi
        if [ -n "{params.m0_indexes}" ]; then
            args+=(--m0-indexes "{params.m0_indexes}")
        fi
        python workflow/scripts/generate_aslcontext.py \
            "{input.json}" --nifti "{input.nifti}" \
            --output "{output.context}" "${{args[@]}}"
        """


checkpoint gather_aslcontext:
    input:
        lambda wildcards: get_asl_contexts(wildcards.field_strength)
    output:
        "data/rawdata/bids/{field_strength}/code/bidscoin/aslcontext.done"
    shell:
        """
        touch {output}
        """


rule gather_add_csa_data_to_meta:
    input:
        "data/rawdata/qmt_acquisitions_renamed.done",
        aslcontext=aggregate_asl_contexts
    output:
        "data/rawdata/bidsify.done"
    threads: 1
    log:
        "logs/bidsify.log"
    priority: 50
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule rename_qmt_acquisitions_by_field_strength:
    input:
        aggregate_add_csa
    output:
        "data/rawdata/bids/{field_strength}/code/bidscoin/qmt_acquisitions_renamed.done"
    params:
        bids_root="data/rawdata/bids/{field_strength}"
    conda:
        "../envs/bidscoin.yaml"
    threads: 1
    log:
        "logs/{field_strength}/rename_qmt_acquisitions.log"
    priority: 50
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        python workflow/scripts/rename_qmt_acquisitions.py {params.bids_root}
        touch {output}
        """


rule rename_qmt_acquisitions:
    input:
        qmt_renames=aggregate_qmt_renames,
        asl_contexts=aggregate_asl_contexts
    output:
        "data/rawdata/qmt_acquisitions_renamed.done"
    threads: 1
    log:
        "logs/rename_qmt_acquisitions.log"
    priority: 50
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        touch {output}
        """