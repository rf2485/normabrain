#requires BIDS data at data/rawdata/bids/{field_strength}
#requires B1map.smk
import glob
from pathlib import Path
from bids import BIDSLayout
from lxml import etree
import re
from collections import Counter
import pandas as pd
import logging

bidspath = Path("data/rawdata/bids")
try:
    field_strength_list=next(os.walk(bidspath))[1]
except:
    field_strength_list=[]


def get_inv1(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}_*inv-1_MP2RAGE.nii.gz'))[0]

def get_inv1_json(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}_*inv-1_MP2RAGE.json'))[0]

def get_inv2(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}_*inv-2_MP2RAGE.nii.gz'))[0]

def get_inv2_json(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}_*inv-2_MP2RAGE.json'))[0]

def get_unit1(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}_*UNIT1.nii.gz'))[0]

def get_unit1_json(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.mp2rage_params}_*UNIT1.json'))[0]

# def get_preproc_uniden_list(wildcards):
#     # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
#     layout=layout_dict[wildcards.field_strength]
#     mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
#     return expand('data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr_brain.nii.gz', mp2rage_params=mp2rage_params_list, allow_missing=True)

# def get_mp2rage_brainmask_list(wildcards):
#     # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
#     layout=layout_dict[wildcards.field_strength]
#     mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
#     return expand('data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz', mp2rage_params=mp2rage_params_list, allow_missing=True)

def get_mp2rage_acq_array(wildcards):
    # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=layout_dict[wildcards.field_strength]
    mp2rage_params_list=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)
    mp2rage_params_array = " ".join(mp2rage_params_list)
    return mp2rage_params_array

def antsdnbrain_first_acq_mp2rage(wildcards):
    # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=layout_dict[wildcards.field_strength]
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand('data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/antsdn.brain.mgz', mp2rage_params=first_acq, allow_missing=True)

def aparc_aseg_first_acq_mp2rage(wildcards):
    # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=layout_dict[wildcards.field_strength]
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand('data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.mgz', mp2rage_params=first_acq, allow_missing=True)

def fs2mni152_first_acq_mp2rage(wildcards):
    # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=layout_dict[wildcards.field_strength]
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand('data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/transforms/synthmorph.1.0mm.1.0mm/warp.to.mni152.1.0mm.1.0mm.nii.gz', 
    mp2rage_params=first_acq, session=wildcards.session, subject=wildcards.subject, field_strength=wildcards.field_strength)

# def wm90percent_lobes_first_acq_mp2rage(wildcards):
#     # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
#     layout=layout_dict[wildcards.field_strength]
#     first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
#     return expand('data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz', mp2rage_params=first_acq, allow_missing=True)

# def wm_lobes_first_acq_mp2rage(wildcards):
#     # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
#     layout=layout_dict[wildcards.field_strength]
#     first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
#     return expand('data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/mni_icbm152_wm_lobes.nii.gz', mp2rage_params=first_acq, allow_missing=True)

def mp2rage_roi_statslist(wildcards):
    layout=layout_dict[wildcards.field_strength]
    statslist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist = list((set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mp2rage))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist = list((set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mp2rage))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)
            for acq in acqlist:
                statslist.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + acq + "/coreg/sub-" + subject + "_ses-" + session + "_acq-" + acq + "_stats.csv")
    return statslist

# def mp2rage_statslist(wildcards):
#     # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
#     layout=layout_dict[wildcards.field_strength]
#     statslist = []
#     subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
#     subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
#     subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
#     subjectlist = list((set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mp2rage))
#     for subject in subjectlist:
#         sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
#         sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
#         sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
#         sessionlist = list((set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mp2rage))
#         for session in sessionlist:
#             acqlist = layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)
#             for acq in acqlist:
#                 statslist.append("data/derivatives/{field_strength}/freesurfer/sub-" + subject + "_ses-" + session + "_acq-" + acq + "/stats/MP2RAGE_{mp2rage_map}.stats")
#     return sorted(statslist)

# def freesurfer_subjectlist_mp2rage(wildcards):
#     # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
#     layout=layout_dict[wildcards.field_strength]
#     fs_subjectlist = []
#     subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
#     subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
#     subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
#     subjectlist = list((set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mp2rage))
#     for subject in subjectlist:
#         sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
#         sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
#         sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
#         sessionlist = list((set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mp2rage))
#         for session in sessionlist:
#             acqlist = layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)
#             for acq in acqlist:
#                 fs_subjectlist.append("sub-" + subject + "_ses-" + session + "_acq-" + acq)
#     fs_subjectarray = " ".join(fs_subjectlist)
#     return fs_subjectarray

def aggregate_mp2rage(wildcards):
    # bidspath = Path("data/rawdata/bids/" + wildcards.field_strength)
    layout=layout_dict[wildcards.field_strength]
    mp2rage_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist = list((set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mp2rage))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist = list((set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mp2rage))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)
            for acq in acqlist:
                mp2rage_list.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + acq + "/preproc/sub-" + subject + "_ses-" + session + "_acq-" + acq + "_T1map_b1corr_brain_denoised_n4.nii.gz")
    return sorted(mp2rage_list)


rule add_xml_data_to_meta_mp2rage:
    input:
        inv1_json = get_inv1_json,
        inv2_json = get_inv2_json,
        unit1_json = get_unit1_json,
    params:
        protocol_path = config["protocol_path"]
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_addXMLdata.done")
    resources: #limit memory by input size
        mem_mb=200
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_addXMLdata.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        python workflow/scripts/add_xml_data_to_meta.py {input.inv1_json} {params.protocol_path}
        python workflow/scripts/add_xml_data_to_meta.py {input.inv2_json} {params.protocol_path}
        python workflow/scripts/add_xml_data_to_meta.py {input.unit1_json} {params.protocol_path}
        touch {output}
        """


rule json_for_uncorr_qT1:
    input:
        addXMLdone = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_addXMLdata.done",
        b1map_nifti = get_last_b1map_run,
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1,
    params:
        uncorr_qT1 = True
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.json"
    threads:
        8
    resources: 
        mem_mb=200
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        python workflow/scripts/create_json_for_mp2proc.py \
        -b1map_nifti {input.b1map_nifti} \
        -inv1_nifti {input.inv1_nifti} \
        -inv2_nifti {input.inv2_nifti} \
        -unit1_nifti {input.unit1_nifti} \
        -output_json {output} \
        -threads {threads} \
        -uncorr_qT1 {params.uncorr_qT1}
        """


rule create_uncorr_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.json"
    params:
        qT1="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.nii.gz"
    threads:
        8
    container:
        "docker://rflaherty3636/mp2proc:v0.1.2"
    resources:
        mem_mb=3000
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        /opt/MP2Proc/bin/main {input}
        cp {params.qT1} {output}
        """


rule json_for_mp2proc:
    input:
        b1map_nifti = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.nii.gz",
        b1map_json = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.json",
        inv1_nifti = get_inv1,
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mp2proc.json"
    threads:
        8
    resources: 
        mem_mb=200
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mp2proc_json.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        python workflow/scripts/create_json_for_mp2proc.py \
        -b1map_nifti {input.b1map_nifti} \
        -inv1_nifti {input.inv1_nifti} \
        -inv2_nifti {input.inv2_nifti} \
        -unit1_nifti {input.unit1_nifti} \
        -output_json {output} \
        -threads {threads}
        """


rule run_mp2proc:
    input:
        mp2proc_json="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mp2proc.json",
        b1map_nifti = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.nii.gz",
        b1map_json = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.json"
    output:
        b1="data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_smooth_norm.nii.gz",
        t1map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_b1corr.nii.gz",
        r1map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_R1map_b1corr.nii.gz",
        uniden_corr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr.nii.gz",
        uniden_uncorr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN.nii.gz",
        uni_corr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNI_b1corr.nii.gz"
    params:
        b1="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/b1_processed_relativeUnit_perThousand.nii.gz",
        t1map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qT1_msUnit.nii.gz",
        r1map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/qR1_pksUnit.nii.gz",
        uniden_corr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_DEN_dicomUnit.nii.gz",
        uniden_uncorr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_DEN_dicomUnit.nii.gz",
        uni_corr="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/t1wUNI_B1Corrected_dicomUnit.nii.gz"
    threads:
        8
    container:
        "docker://rflaherty3636/mp2proc:v0.1.2"
    resources: 
        mem_mb=5000
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mp2proc.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        /opt/MP2Proc/bin/main {input.mp2proc_json}

        mv {params.b1} {output.b1}
        mv {params.t1map} {output.t1map}
        mv {params.r1map} {output.r1map}
        mv {params.uniden_corr} {output.uniden_corr}
        mv {params.uniden_uncorr} {output.uniden_uncorr}
        mv {params.uni_corr} {output.uni_corr}
        """


# Rules for segmentation and registration to atlases

rule MPRAGEise:
    input:
        inv2_nifti = get_inv2,
        unit1_nifti = get_unit1
    output:
        outdir = temp(directory("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/MPRAGEise/")),
        outimg = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_MPRAGEise.nii.gz"
    params:
        "sub-{subject}_ses-{session}_acq-{mp2rage_params}_UNIT1_unbiased_clean.nii.gz"
    container:
         "docker://afni/afni_cmake_build:AFNI_26.1.04"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_MPRAGEise.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        python workflow/scripts/MPRAGEise.py -i {input.inv2_nifti} -u {input.unit1_nifti} -o {output.outdir}
        mv {output.outdir}/{params} {output.outimg}
        """


rule crop_mp2rage_256:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_MPRAGEise.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_MPRAGEise_cropped.nii.gz")
    resources:
        mem_mb=1000
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_MPRAGEise_cropped.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        #crop neck
        size_2="$(mrinfo -size {input} | awk '{{print $3}}')"
        start_2="$((${{size_2}}-256))"
        mrgrid {input} crop -axis 2 ${{start_2}}:end {output} -force 

        #crop coronal
        size_1="$(mrinfo -size {input} | awk '{{print $2}}')"
        crop_size_1="$(((${{size_1}}-256)/2))"
        crop_size_1a="$((${{crop_size_1}}-10))"
        crop_size_1b="$((${{crop_size_1}}+10))"
        mrgrid {output} crop -axis 1 ${{crop_size_1a}},${{crop_size_1b}} {output} -force 

        #pad ears
        size_0="$(mrinfo -size {input} | awk '{{print $1}}')"
        pad_size_0="$(((256-${{size_0}})/2))"
        mrgrid {output} pad -axis 0 ${{pad_size_0}},${{pad_size_0}} {output} -force 
        """


rule recon_all:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_MPRAGEise_cropped.nii.gz"
        # "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr_cropped.nii.gz"
    params:
        subjects_dir="data/derivatives/{field_strength}/freesurfer/",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
    output:
        aparc_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.mgz",
        aparc_nii="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.nii.gz",
        orig_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        orig_nii="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.nii.gz"
    threads: 8
    resources:
        mem_mb=15000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/recon-all.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        #create and set SUBJECTS_DIR
        mkdir -p $HOME/{params.subjects_dir}
        export SUBJECTS_DIR=$HOME/{params.subjects_dir}

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        #set up GPU
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
            export UseGPU=1
        fi

        #remove old recon-all folder
        rm -rf $SUBJECTS_DIR/{params.subject}

        #run recon-all
        recon-all -hires -parallel -3T -i {input} -all -s {params.subject}

        #convert aparc and orig to nii for easier QC
        mri_convert {output.aparc_mgz} {output.aparc_nii}
        mri_convert {output.orig_mgz} {output.orig_nii}

        #copy log to logs folder
        cp $SUBJECTS_DIR/{params.subject}/scripts/recon-all.log {log}
        """


rule convert_mgz_to_nii:
    input:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.mgz",
    params:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/antsdn.brain.mgz",
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/antsdn.brain.nii.gz",
    threads: 1
    resources:
        mem_mb=15000
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/convert_mgz_to_nii.log"
    shell:
        """
        mri_convert {params} {output}
        """


rule register_mp2rage_acqs:
    #register to first mp2rage acq in freesurfer space
    input:
        target=antsdnbrain_first_acq_mp2rage,
        moving="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr_brain.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_reg2fs.lta"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources: 
        mem_mb=1000
    threads: 4
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_reg2fs.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        mri_robust_register \
        --mov {input.moving} \
        --dst {input.target} \
        --lta {output} \
        --satit --iscale --initorient

        """

# rule register_mp2rage_acqs:
#     input:
#         img_list=get_preproc_uniden_list,
#         mask_list=get_mp2rage_brainmask_list
#     params:
#         acq_array=get_mp2rage_acq_array,
#         regdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/",
#         subject="sub-{subject}_ses-{session}"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/mp2rage_acqs_registration.done"
#     conda:
#         "../envs/qMT.yaml"
#     resources: 
#         mem_mb=1000
#     threads: 4
#     log:
#         "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/mp2rage_acqs_registration.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

#         img_array=( {input.img_list} )
#         mask_array=( {input.mask_list} )
#         acq_array=( {params.acq_array} )

#         if [ "${{#img_array[@]}}" -gt 1 ]; then
#             first_acq="${{acq_array[0]}}"
#             first_img="${{img_array[0]}}"
#             first_mask="${{mask_array[0]}}"
#             img_array_clipped=("${{img_array[@]:1}}")
            
#             i=0
#             for img in "${{img_array_clipped[@]}}"; do
#                 i=$((i+1))
#                 acq="${{acq_array[$i]}}"
#                 mask="${{mask_array[$i]}}"
                
#                 mkdir -p {params.regdir}/acq-$acq/coreg/

#                 antsRegistration \
#                 --random-seed 1 \
#                 --dimensionality 3 \
#                 --verbose 1 \
#                 --convergence [ 1000x500x250x100, 1e-7, 100 ] \
#                 --shrink-factors 8x4x2x1 \
#                 --smoothing-sigmas 4x2x1x0vox \
#                 --transform Rigid[0.1] \
#                 --metric MI[ ${{first_img}}, ${{img}}, 1, 32 ] \
#                 -o {params.regdir}/acq-$acq/coreg/{params.subject}_acq-${{acq}}_reg2${{first_acq}}_ \
#                 -x [ ${{first_mask}}, ${{mask}} ] 
#             done
#         fi
#         touch {output}
#         """


rule apply_reg_first_mp2rage_acq:
    input:
        reg="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_reg2fs.lta",
        target=antsdnbrain_first_acq_mp2rage,
        moving="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_brain.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_coreg.nii.gz"
    resources: 
        mem_mb=500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_coreg.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        mri_vol2vol --mov {input.moving} --targ {input.target} --reg {input.reg} --o {output} --no-save-reg
        """


rule aparc_aseg_to_subject_mp2rage:
    input:
        reg="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_reg2fs.lta",
        mp2rage="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr_brain.nii.gz",
        seg=aparc_aseg_first_acq_mp2rage
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_aparc+aseg.nii.gz"
    resources: 
        mem_mb=500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    threads: 1
    log:
       "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_aparc+aseg.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        mri_vol2vol \
        --inv --nearest --no-save-reg \
        --mov {input.mp2rage} --targ {input.seg} --reg {input.reg} \
        --o {output}
        """ 


# rule apply_reg_first_mp2rage_acq:
#     input:
#         reg_done="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/mp2rage_acqs_registration.done",
#         moving="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}.nii.gz"
#     params:
#         acq_array=get_mp2rage_acq_array,
#         sessiondir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/",
#         subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_coreg.nii.gz"
#     resources: 
#         mem_mb=500
#     conda:
#         "../envs/qMT.yaml"
#     threads: 1
#     log:
#         "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_coreg.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

#         acq_array=( {params.acq_array} )
#         first_acq="${{acq_array[0]}}"
#         if [ -f {params.sessiondir}/acq-{wildcards.mp2rage_params}/coreg/{params.subject}_reg2${{first_acq}}_0GenericAffine.mat ]; then    
#             antsApplyTransforms \
#             --dimensionality 3 \
#             --interpolation Linear \
#             --verbose 1 \
#             -i {input.moving} \
#             --reference-image {params.sessiondir}/acq-$first_acq/sub-{wildcards.subject}_ses-{wildcards.session}_acq-${{first_acq}}_{wildcards.mp2rage_map}.nii.gz \
#             --transform {params.sessiondir}/acq-{wildcards.mp2rage_params}/coreg/{params.subject}_reg2${{first_acq}}_0GenericAffine.mat \
#             -o {output}
#         else
#             cp {input.moving} {output}
#         fi
#         """

rule copy_aparc_aseg_lut:
    output:
        "data/atlases/aparc+aseg_lut.txt"
    resources:
        mem_mb=200
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/aparc+aseg_lut.txt"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        cp $FREESURFER_HOME/FreeSurferColorLUT.txt {output}
        """


rule download_mni_icbm152_nlin_sym_09c_minc2:
    output:
        mni152_sym=temp(directory("data/atlases/mni_icbm152_nlin_sym_09c_minc2/")),
        wm_lobes=temp("data/atlases/mni_icbm152_wm_lobes.nii"),
        lut="data/atlases/mni_icbm152_wm_lobes_lut.txt"
    resources:
        mem_mb=700
    threads: 1
    container:
        "docker://nistmni/minc-toolkit-min:1.9.18"
    log:
        "logs/download_mni_icbm152_nlin_sym_09c_minc2.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        
        mkdir -p {output.mni152_sym}
        cd {output.mni152_sym}
        wget https://www.bic.mni.mcgill.ca/~vfonov/icbm/icbm2009_lobe_defs.txt
        mv icbm2009_lobe_defs.txt ../mni_icbm152_wm_lobes_lut.txt
        wget https://www.bic.mni.mcgill.ca/~vfonov/icbm/2009/mni_icbm152_nlin_sym_09c_minc2.zip
        unzip mni_icbm152_nlin_sym_09c_minc2.zip
        mnc2nii  mni_icbm152_t1_tal_nlin_sym_09c_atlas/AtlasWhite.mnc
        cp mni_icbm152_t1_tal_nlin_sym_09c_atlas/AtlasWhite.nii ../mni_icbm152_wm_lobes.nii
        """


rule wm_lobes_nii_to_nii_gz:
    input:
        "data/atlases/mni_icbm152_wm_lobes.nii"
    output:
        "data/atlases/mni_icbm152_wm_lobes.nii.gz"
    conda:
        "../envs/fslmaths.yaml"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/atlases_nii_to_nii_gz.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'

        fslchfiletype NIFTI_GZ {input}
        """


rule wm90percent_lobes:
    input:
        wm_lobes="data/atlases/mni_icbm152_wm_lobes.nii.gz",
        wm_lobes_lut="data/atlases/mni_icbm152_wm_lobes_lut.txt"
    params:
        wm_percent="average/mni_icbm152_nlin_asym_09c/mni_icbm152_wm_tal_nlin_asym_09c.nii.gz"
    output:
        wm90percent_mask=temp("data/atlases/mni_icbm152_nlin_asym_09c_wm90percent_mask.nii.gz"),
        wm90percent_lobes="data/atlases/mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm90percent_lobes_lut="data/atlases/mni_icbm152_nlin_asym_09c_wm90percent_lobes_lut.txt",
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/mni_icbm152_nlin_sym_09c_wm90percent_lobes.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_binarize --i $FREESURFER_HOME/{params.wm_percent} --o {output.wm90percent_mask} --min 0.9
        mri_mask {input.wm_lobes} {output.wm90percent_mask} {output.wm90percent_lobes}
        cp {input.wm_lobes_lut} {output.wm90percent_lobes_lut}
        """


rule warp_subject_mp2rage_to_mni152:
    input:
        subj2fs="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_reg2fs.lta",
        antsdnbrain=antsdnbrain_first_acq_mp2rage
    params:
        fs2mni152=fs2mni152_first_acq_mp2rage
    output:
        subj2mni152="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_reg2mni152_warp.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_reg2mni152.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_warp_convert --inm3z {params.fs2mni152} \
        --lta1 {input.subj2fs} \
        --insrcgeom {input.antsdnbrain} \
        --outm3z {output.subj2mni152}
        """


rule apply_warp_mni_atlases_to_subject_mp2rage:
    input:
        subj2mni152="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_reg2mni152_warp.nii.gz",
        aparc_aseg="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_aparc+aseg.nii.gz",
        wm90percent_lobes="data/atlases/mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/atlases/mni_icbm152_wm_lobes.nii.gz"
    output:
        wm_mask="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_wm_mask.nii.gz",
        wm90percent_lobes="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_mni_icbm152_wm_lobes.nii.gz",
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}/apply_warp_mni_atlases_to_subject_mp2rage.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_binarize --i {input.aparc_aseg} --o {output.wm_mask} --match 2 7 41 46

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm90percent_lobes} {output.wm90percent_lobes}
        mri_mask {output.wm90percent_lobes} {output.wm_mask} {output.wm90percent_lobes}

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm_lobes} {output.wm_lobes}
        mri_mask {output.wm_lobes} {output.wm_mask} 
        """
# rule mni152_atlases_to_subject_mp2rage_space:                                                                 
#     input:
#         aparc_aseg="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg.nii.gz",
#         wm90percent_lobes="data/atlases/mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
#         wm_lobes="data/atlases/mni_icbm152_wm_lobes.nii.gz"
#     params:
#         warp_mni152_to_subject="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/transforms/synthmorph.1.0mm.1.0mm/warp.to.mni152.1.0mm.1.0mm.inv.nii.gz"
#     output:
#         wm90percent_lobes="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
#         wm_lobes="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/mni_icbm152_wm_lobes.nii.gz",
#         fs_wm_mask="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/fs_wm_mask.nii.gz"
#     threads: 1
#     resources:
#         mem_mb=700
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     log:
#         "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/mni_icbm152_nlin_asym_09c_wm90percent_lobes.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console
#         export FS_LICENSE=".snakemake/scripts/.license"

#         mri_binarize --i {input.aparc_aseg} --o {output.fs_wm_mask} --match 2 7 41 46
        
#         mri_synthmorph apply {params.warp_mni152_to_subject} {input.wm90percent_lobes} {output.wm90percent_lobes} -m nearest
#         mri_mask {output.wm90percent_lobes} {output.fs_wm_mask} {output.wm90percent_lobes}
        
#         mri_synthmorph apply {params.warp_mni152_to_subject} {input.wm_lobes} {output.wm_lobes} -m nearest
#         mri_mask {output.wm_lobes} {output.fs_wm_mask} {output.wm_lobes}
#         """


# rule reslice_segmentation:
#     input:
#         seg=segmentation_first_acq_mp2rage,
#         ref="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN_b1corr_coreg.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_coreg_{segmentation}.nii.gz"
#     resources:
#         mem_mb=1000
#     conda:
#         "../envs/qMT.yaml"
#     log:
#         "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_coreg_{segmentation}.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console
#         mrgrid {input.seg} regrid -template {input.ref} -strides {input.ref} -interp nearest {output} -force
#         """
    

rule mp2rage_roi_stats:
    input:
        mp2rage_map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_coreg.nii.gz",
        seg="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_coreg_{segmentation}.nii.gz",
        lut="data/atlases/{segmentation}_lut.txt"
    params:
        outdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/"
    output:
        stats="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_seg-{segmentation}_ctr-{mp2rage_map}_stats.csv",
        nooutliers_stats="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_seg-{segmentation}_ctr-{mp2rage_map}_nooutliers_stats.csv",
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_seg-{segmentation}_ctr-{mp2rage_map}_stats.log",
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        python3 workflow/scripts/roi_stats.py "{input.mp2rage_map}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.subject}" "{wildcards.session}" "{wildcards.mp2rage_params}" "{wildcards.mp2rage_map}"
        python3 workflow/scripts/roi_stats.py -r "{input.mp2rage_map}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.subject}" "{wildcards.session}" "{wildcards.mp2rage_params}" "{wildcards.mp2rage_map}"
        """


rule mp2rage_roi_stats_agg_segs:
    input:
        stats=expand("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_seg-{segmentation}_ctr-{mp2rage_map}_stats.csv", 
        segmentation=config["segmentations"].split(), mp2rage_map="R1map_b1corr", allow_missing=True),
        nooutliers=expand("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_seg-{segmentation}_ctr-{mp2rage_map}_nooutliers_stats.csv", 
        segmentation=config["segmentations"].split(), mp2rage_map="R1map_b1corr", allow_missing=True)
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_stats.csv"),
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_stats.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        df_stats = pd.concat((pd.read_csv(s) for s in input.stats), ignore_index=True)
        df_nooutliers = pd.concat((pd.read_csv(n) for n in input.nooutliers), ignore_index=True)
        df_stats = pd.concat([df_stats, df_nooutliers])
        df_stats.to_csv(str(output), index=False)


rule mp2rage_roi_stats_agg_subjs:
    input:
        mp2rage_roi_statslist
    output:
        "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_stats.csv"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/MP2RAGE_stats.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        df_stats = pd.concat((pd.read_csv(i) for i in input), ignore_index=True)
        df_stats.to_csv(str(output), index=False)


# rule mp2rage_segstats:
#     input:
#         seg="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/aparc+aseg_resliced.nii.gz",
#         mp2rage_map="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{mp2rage_map}_coreg.nii.gz"
#     output:
#         "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/stats/MP2RAGE_{mp2rage_map}.stats"
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     log:
#         "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/MP2RAGE_{mp2rage_map}_stats.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export FS_LICENSE=$HOME/.snakemake/scripts/.license
        
#         mri_segstats --seg {input.seg} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i {input.mp2rage_map} --sum {output} --excludeid 0
#         """  


# rule mp2rage_tsv:
#     input:
#         mp2rage_statslist,
#         # "data/rawdata/bidsify.done"
#     params:
#         subjects_dir="data/derivatives/{field_strength}/freesurfer/",
#         subjects_list=freesurfer_subjectlist_mp2rage,
#         statsfile="MP2RAGE_{mp2rage_map}.stats"
#     output:
#         "data/derivatives/{field_strength}/freesurfer/MP2RAGE_{mp2rage_map}_stats.tsv"  
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     log:
#         "logs/{field_strength}/freesurfer/MP2RAGE_{mp2rage_map}_stats_tsv.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export SUBJECTS_DIR=$HOME/{params.subjects_dir}
#         export FS_LICENSE=$HOME/.snakemake/scripts/.license

#         if ! [ -n {params.subjects_list} ]; then
#             asegstats2table --subjects {params.subjects_list} --statsfile {params.statsfile} -t {output} --meas mean --common-segs --no-segno 0
#         fi
#         touch {output}       
#         """


#rules for registering with ANTs

rule synthstrip_qT1:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=8000
    log:
       "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_mask.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} -g --no-csf || mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    log:
       "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        DenoiseImage \
        --image-dimensionality 3 \
        --noise-model Rician \
        --verbose 1 \
        -i {input.input_image} \
        -x {input.mask_image} \
        -o {output}
        """


rule N4BiasFieldCorrection_qT1:
    input:
        input_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised_n4.nii.gz"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_{qT1}_brain_denoised_n4.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}
        
        N4BiasFieldCorrection \
        --image-dimensionality 3 \
        --verbose 1 \
        -i {input.input_image} \
        -x {input.mask_image} \
        -o {output}
        """


rule aggregate_mp2rage_by_field_strength:
    input:
        aggregate_mp2rage
    output:
        "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE.done"
    log:
        "logs/{field_strength}/MP2RAGE/MP2RAGE.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule aggregate_mp2rage:
    input:
        expand("data/derivatives/{field_strength}/MP2RAGE/MP2RAGE.done", field_strength=field_strength_list),
        expand("data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_stats.csv", field_strength=field_strength_list),
        # expand("data/derivatives/{field_strength}/freesurfer/MP2RAGE_{mp2rage_map}_stats.tsv", field_strength=field_strength_list, mp2rage_map=["R1map_b1corr", "T1map_b1corr"])
