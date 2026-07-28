#requires BIDS data at data/rawdata/bids/{field_strength}
#requires B1map.smk and qMT.smk
import glob
import shutil
from pathlib import Path
from bids import BIDSLayout
import logging

wildcard_constraints:
    seq = config["qmt_sequence"]

bidspath = Path("data/rawdata/bids")

def get_mt0_phase(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}mt0*{wildcards.qMT_params}*_echo-*_flip-*_mt-off_part-phase_MPM.nii.gz'))[0]

def qsm_nii_list(wildcards):
    layout=layout_dict[wildcards.field_strength]
    qsm_nii_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mpm))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mpm))
        for session in sessionlist:
            mpm_acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for mpm in mpm_acqlist:
                mpm = mpm.replace("6eco", "").replace("3eco", "").replace("sag", "").replace(config["qmt_sequence"], "").replace("mag", "").replace("pha", "").replace("DL", "")
                for contrast in config["qmt_contrasts"].split():
                    mpm = mpm.replace(contrast, "")
                qsm_nii_list.append("data/derivatives/{field_strength}/QSM/sub-" + subject + "/ses-" + session + "/anat/sub-" + subject + "_ses-" + session + "_acq-" + config["qmt_sequence"] + "mt0" + mpm + "_echo-1_part-phase_MEGRE.nii.gz")
    qsm_nii_list = list(set(qsm_nii_list))
    return qsm_nii_list

def qsm_json_list(wildcards):
    layout=layout_dict[wildcards.field_strength]
    qsm_json_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mpm))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mpm))
        for session in sessionlist:
            mpm_acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for mpm in mpm_acqlist:
                mpm = mpm.replace("6eco", "").replace("3eco", "").replace("sag", "").replace(config["qmt_sequence"], "").replace("mag", "").replace("pha", "").replace("DL", "")
                for contrast in config["qmt_contrasts"].split():
                    mpm = mpm.replace(contrast, "")
                qsm_json_list.append("data/derivatives/{field_strength}/QSM/sub-" + subject + "/ses-" + session + "/anat/sub-" + subject + "_ses-" + session + "_acq-" + config["qmt_sequence"] + "mt0" + mpm + "_echo-1_part-phase_MEGRE.json")
    qsm_json_list = list(set(qsm_json_list))
    return qsm_json_list

def qsm_mask_list(wildcards):
    layout=layout_dict[wildcards.field_strength]
    qsm_mask_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mpm))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mpm))
        for session in sessionlist:
            mpm_acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for mpm in mpm_acqlist:
                mpm = mpm.replace("6eco", "").replace("3eco", "").replace("sag", "").replace(config["qmt_sequence"], "").replace("mag", "").replace("pha", "").replace("DL", "")
                for contrast in config["qmt_contrasts"].split():
                    mpm = mpm.replace(contrast, "")
                qsm_mask_list.append("data/derivatives/{field_strength}/QSM/derivatives/brain_spine_mask/sub-" + subject + "/ses-" + session + "/anat/sub-" + subject + "_ses-" + session + "_acq-" + config["qmt_sequence"] + "mt0" + mpm + "_mask.nii.gz")
    qsm_mask_list = list(set(qsm_mask_list))
    return qsm_mask_list

def get_inv1(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-*{wildcards.mp2rage_params}*_inv-1_MP2RAGE.nii.gz'))[0]

def t1w_nii_list(wildcards):
    layout=layout_dict[wildcards.field_strength]
    t1w_nii_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mpm))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mpm))
        for session in sessionlist:
            mp2rage_first_acq = layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            t1w_nii_list.append("data/derivatives/{field_strength}/QSM/sub-" + subject + "/ses-" + session + "/anat/sub-" + subject + "_ses-" + session + "_acq-" + mp2rage_first_acq + "_T1w.nii.gz")
    t1w_nii_list = list(set(t1w_nii_list))
    return t1w_nii_list

def t1w_json_list(wildcards):
    layout=layout_dict[wildcards.field_strength]
    t1w_json_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mpm))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mpm))
        for session in sessionlist:
            mp2rage_first_acq = layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            t1w_json_list.append("data/derivatives/{field_strength}/QSM/sub-" + subject + "/ses-" + session + "/anat/sub-" + subject + "_ses-" + session + "_acq-" + mp2rage_first_acq + "_T1w.json")
    t1w_json_list = list(set(t1w_json_list))
    return t1w_json_list


rule copy_raw_qsm:
    input:
        get_mt0_phase
    output:
        "data/derivatives/{field_strength}/QSM/sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_echo-1_part-phase_MEGRE.json"
    resources:
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    threads: 1
    log:
        "logs/{field_strength}/QSM/sub-{subject}/ses-{session}/copy_raw_qsm_acq-{seq}mt0{qMT_params}.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")

        qsm_folder = Path(str(output)).parent
        qsm_folder.mkdir(exist_ok=True, parents=True)

        phase_list = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}mt0*{wildcards.qMT_params}*_echo-*_flip-*_mt-off_part-phase_MPM.nii.gz'))
        num_phase = len(phase_list)
        mag_list_clipped = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}mt0*{wildcards.qMT_params}*_echo-*_flip-*_mt-off_part-mag_MPM.nii.gz'))[num_phase:]
        raw_list = phase_list + mag_list_clipped
        i=0
        for img in phase_list:
            i += 1
            raw = Path(img)
            qsm_name = "sub-" + wildcards.subject + "_ses-" + wildcards.session + "_acq-" + wildcards.seq + "mt0" + wildcards.qMT_params + "_echo-" + str(i) + "_part-phase_MEGRE.nii.gz"
            qsm = qsm_folder / qsm_name
            raw_json = raw.with_suffix("").with_suffix(".json")
            qsm_json = qsm.with_suffix("").with_suffix(".json")
            shutil.copy(raw_json, qsm_json)
        i=0
        for img in mag_list_clipped:
            i += 1
            raw = Path(img)
            qsm_name = "sub-" + wildcards.subject + "_ses-" + wildcards.session + "_acq-" + wildcards.seq + "mt0" + wildcards.qMT_params + "_echo-" + str(i) + "_part-mag_MEGRE.nii.gz"
            qsm = qsm_folder / qsm_name
            raw_json = raw.with_suffix("").with_suffix(".json")
            qsm_json = qsm.with_suffix("").with_suffix(".json")
            shutil.copy(raw_json, qsm_json)


rule copy_denoised_qsm:
    input:
        phase = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-phase_echos4d_riciancorr.nii",
        mag = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_echos4d_riciancorr.nii"
    params:
        anatdir="data/derivatives/{field_strength}/QSM/sub-{subject}/ses-{session}/anat/",
        subject="sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}"
    output:
        "data/derivatives/{field_strength}/QSM/sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_echo-1_part-phase_MEGRE.nii.gz"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/QSM/sub-{subject}/ses-{session}/copy_denoised_qsm_acq-{seq}mt0{qMT_params}.log"
    shell:
        """
        vols="$(mrinfo -size {input.phase} | awk '{{print $4}}')"
        for vol in $(seq 1 $vols); do
            i="$((${{vol}}-1))"
            mrconvert {input.phase} -coord 3 $i -axes 0,1,2 {params.anatdir}/tmp_phase.nii.gz -force
            mv {params.anatdir}/tmp_phase.nii.gz {params.anatdir}/{params.subject}_echo-${{vol}}_part-phase_MEGRE.nii.gz
            mrconvert {input.mag} -coord 3 $i -axes 0,1,2 {params.anatdir}/tmp_mag.nii.gz -force
            mv {params.anatdir}/tmp_mag.nii.gz {params.anatdir}/{params.subject}_echo-${{vol}}_part-mag_MEGRE.nii.gz
        done
        """


rule copy_raw_t1w_json_qsm:
    input:
        inv1 = get_inv1
    output:
        "data/derivatives/{field_strength}/QSM/sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w.json"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    threads: 1
    log:
        "logs/{field_strength}/QSM/sub-{subject}/ses-{session}/copy_raw_t1w_json_qsm_acq-{mp2rage_params}.log"
    run:
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        inv1_json = Path(input.inv1).with_suffix("").with_suffix(".json")
        shutil.copy(inv1_json, str(output))

        
rule copy_uniden_qsm:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN.nii.gz"
    output:
        "data/derivatives/{field_strength}/QSM/sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w.nii.gz"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    threads: 1
    log:
       "logs/{field_strength}/QSM/sub-{subject}/ses-{session}/copy_uniden_qsm_acq-{mp2rage_params}.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        cp {input} {output}
        """


rule copy_mask_qsm:
    input:
        mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_spine_mask.nii.gz",
        ref = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_sos.nii.gz",
        reg = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_reg2{seq}t1w{qMT_params}_0GenericAffine.mat"
    output:
        "data/derivatives/{field_strength}/QSM/derivatives/brain_spine_mask/sub-{subject}/ses-{session}/anat/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mask.nii.gz"
    resources: #limit memory by input size
        mem_mb=lambda wc, input: 2.5 * input.size_mb
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
       "logs/{field_strength}/QSM/sub-{subject}/ses-{session}/copy_mask_qsm_acq-{seq}mt0{qMT_params}.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        maskfilter {input.mask} erode {output} -force
        antsApplyTransforms -d 3 -v 1 -n NearestNeighbor -i {output} -r {input.ref} -t [ {input.reg}, 1 ] -o {output}
        """


rule qsmxt:
    input:
        qsm_nii_list = qsm_nii_list,
        qsm_json_list = qsm_json_list,
        # qsm_mask_list,
        # t1w_nii_list,
        # t1w_json_list
    params:
        qsm_folder="data/derivatives/{field_strength}/QSM/"
    output:
        directory("data/derivatives/{field_strength}/QSM/derivatives/qsmxt/")    
    threads: 8
    resources:
        mem_mb=11000
    container:
        "docker://vnmd/qsmxt_8.2.2:20260105"
    log:
        "logs/{field_strength}/QSM/qsmxt.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        
        rm -rf {output}
        mkdir -p {output}

        export qsm_nii_list=({input.qsm_nii_list})
        if [ ${{#qsm_nii_list[@]}} -gt 0 ]; then

            if command -v nvidia-smi; then
                export CUDA_VISIBLE_DEVICES=0
            fi
            
            rm -rf {params.qsm_folder}/derivatives/qsmxt-*

            qsmxt {params.qsm_folder} --do_qsm --do_swi --do_t2starmap --do_r2starmap --premade gre --n_procs {threads} --gpu --auto_yes || \
            qsmxt {params.qsm_folder} --do_qsm --do_swi --do_t2starmap --do_r2starmap --premade gre --n_procs {threads} --auto_yes

            #move qsmxt folder so it has a consistent name for snakemake
            mv {params.qsm_folder}/derivatives/qsmxt-*/* {output}
            rm -rf {params.qsm_folder}/derivatives/qsmxt-*/*
        
        fi
        """

rule aggregate_qsmxt:
    input:
        expand("data/derivatives/{field_strength}/QSM/derivatives/qsmxt/", field_strength=field_strength_list)