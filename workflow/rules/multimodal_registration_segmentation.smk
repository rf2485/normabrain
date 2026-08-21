#rules for multimodal registration and segmentation, not including B1map which is a dependency for regular pre-processing for MP2RAGE and qMT
#dependent on all other smk files
import os
import shutil
from bids import BIDSLayout
from collections import Counter
from pathlib import Path


wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["qmt_contrasts"].split()]),
    seq = config["qmt_sequence"],
    part = 'mag|phase'

bidspath = Path("data/rawdata/bids")
try:
    field_strength_list=next(os.walk(bidspath))[1]
except:
    field_strength_list=[]

def resliced_segmentation_first_acq_mp2rage(wildcards):
    layout=layout_dict[wildcards.field_strength]
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/coreg/sub-{subject}_ses-{session}_acq-{mp2rage_params}_coreg_{segmentation}.nii.gz", mp2rage_params=first_acq, allow_missing=True)

def qMT_to_mp2rage(wildcards):
    layout=layout_dict[wildcards.field_strength]
    apply_reg_list = []
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
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            for mpm in mpm_acqlist:
                mpm = mpm.replace("6eco", "").replace("3eco", "").replace("sag", "").replace("mag", "").replace("pha", "").replace("DL", "")
                for contrast in config["qmt_contrasts"].split():
                    mpm = mpm.replace(contrast, "")
                apply_reg_list.append("data/derivatives/{field_strength}/qMT/sub-" + subject + "/ses-" + session + "/reg2MP2RAGE/sub-" + subject + "_ses-" + session + "_acq-" + mpm + "_applyreg2" + mp2rage_first_acq + ".done")
    counts = Counter(apply_reg_list)
    apply_reg_list = [reg for reg, count in counts.items() if count > 3]
    return apply_reg_list

# def ihmt_to_mp2rage(wildcards):
def ihmt_to_freesurfer(wildcards):
    layout=layout_dict[wildcards.field_strength]
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_ihmt = layout.get_subject(suffix="ihmt")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_ihmt))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_ihmt = layout.get_session(suffix="ihmt", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_ihmt))
        for session in sessionlist:
            ihmt_acqlist = layout.get_acquisition(suffix="ihmt", subject=subject, session=session)
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            for ihmt in ihmt_acqlist:
                apply_reg_list.append("data/derivatives/{field_strength}/ihmt/sub-" + subject + "/ses-" + session + "/acq-" + ihmt + "/reg2MP2RAGE/sub-" + subject + "_ses-" + session + "_acq-" + ihmt + "_applyreg2FS" + mp2rage_first_acq + ".done")
    return apply_reg_list

def dwi_to_mp2rage(wildcards):
    layout=layout_dict[wildcards.field_strength]
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_dwi = layout.get_subject(suffix="dwi")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_dwi))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_dwi = layout.get_session(suffix="dwi", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_dwi))
        for session in sessionlist:
            dwi_acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            for dwi in dwi_acqlist:
                # dwi = dwi.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "").replace("3shb3ktra", "").replace("pha", "")
                apply_reg_list.append("data/derivatives/{field_strength}/dwi/sub-" + subject + "/ses-" + session + "/acq-DWI" + dwi + "/reg2MP2RAGE/sub-" + subject + "_ses-" + session + "_acq-DWI" + dwi + "_applyreg2" + mp2rage_first_acq + ".done" )
    return apply_reg_list

# def ihmt_reg2first_acq_mp2rage(wildcards):
def ihmt_reg2first_acq_freesurfer(wildcards):
    layout=layout_dict[wildcards.field_strength]
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2FS{mp2rage_params}.lta", mp2rage_params=first_acq, allow_missing=True)

def qMT_reg2first_acq_mp2rage(wildcards):
    layout=layout_dict[wildcards.field_strength]
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_reg2{mp2rage_params}_0GenericAffine.mat", mp2rage_params=first_acq, allow_missing=True)

def dwi_reg2first_acq_mp2rage(wildcards):
    layout=layout_dict[wildcards.field_strength]
    first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=wildcards.subject, session=wildcards.session)[0]
    return expand("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2{mp2rage_params}.lta", mp2rage_params=first_acq, allow_missing=True)

def ihmt_statslist(wildcards):
    layout=layout_dict[wildcards.field_strength]
    statslist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_ihmt = layout.get_subject(suffix="ihmt")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_ihmt))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_ihmt = layout.get_session(suffix="ihmt", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_ihmt))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="ihmt", subject=subject, session=session)
            for acq in acqlist:
                statslist.append("data/derivatives/{field_strength}/ihmt/sub-" + subject + "/ses-" + session + "/acq-" + acq + "/sub-" + subject + "_ses-" + session + "_acq-" + acq + "_stats.pickle")
                # statslist.append("data/derivatives/{field_strength}/freesurfer/sub-" + subject + "_ses-" + session + "_acq-" + acq + "/stats/ihmt_stats.done")
    return sorted(statslist)

def qMT_statslist(wildcards):
    layout=layout_dict[wildcards.field_strength]
    statslist = []
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
            acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for acq in acqlist:
                acq = acq.replace("6eco", "").replace("3eco", "").replace("sag", "").replace("mag", "").replace("pha", "").replace("DL", "")
                for contrast in config["qmt_contrasts"].split():
                    acq = acq.replace(contrast, "")
                statslist.append("data/derivatives/{field_strength}/freesurfer/sub-" + subject + "_ses-" + session + "_acq-" + acq + "/stats/qMT_stats.done")
    counts = Counter(statslist)
    statslist = [stat for stat, count in counts.items() if count > 3]
    return sorted(statslist)

def dwi_statslist(wildcards):
    layout=layout_dict[wildcards.field_strength]
    statslist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_dwi = layout.get_subject(suffix="dwi")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_dwi))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_dwi = layout.get_session(suffix="dwi", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_dwi))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            for acq in acqlist:
                # acq = acq.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "").replace("3shb3ktra", "").replace("pha", "")
                statslist.append("data/derivatives/{field_strength}/freesurfer/sub-" + subject + "_ses-" + session + "_acq-DWI" + acq + "/stats/dwi_stats.done")
    return sorted(statslist)

def freesurfer_subjectlist_ihmt(wildcards):
    layout=layout_dict[wildcards.field_strength]
    fs_subjectlist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_ihmt = layout.get_subject(suffix="ihmt")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_ihmt))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_ihmt = layout.get_session(suffix="ihmt", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_ihmt))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="ihmt", subject=subject, session=session)
            for acq in acqlist:
                fs_subjectlist.append("sub-" + subject + "_ses-" + session + "_acq-" + acq)
    fs_subjectarray = " ".join(fs_subjectlist)
    return fs_subjectarray

def freesurfer_subjectlist_qMT(wildcards):
    layout=layout_dict[wildcards.field_strength]
    fs_subjectlist = []
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
            acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for acq in acqlist:
                acq = acq.replace("6eco", "").replace("3eco", "").replace("sag", "").replace("mag", "").replace("pha", "").replace("DL", "")
                for contrast in config["qmt_contrasts"].split():
                    acq = acq.replace(contrast, "")
                fs_subjectlist.append("sub-" + subject + "_ses-" + session + "_acq-" + acq)
    counts = Counter(fs_subjectlist)
    fs_subjectlist = [sub for sub, count in counts.items() if count > 3]
    fs_subjectarray = " ".join(fs_subjectlist)
    return fs_subjectarray

def freesurfer_subjectlist_dwi(wildcards):
    layout=layout_dict[wildcards.field_strength]
    fs_subjectlist = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_dwi = layout.get_subject(suffix="dwi")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_dwi))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_dwi = layout.get_session(suffix="dwi", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_dwi))
        for session in sessionlist:
            acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            for acq in acqlist:
                # acq = acq.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "").replace("3shb3ktra", "").replace("pha", "")
                fs_subjectlist.append("sub-" + subject + "_ses-" + session + "_acq-DWI" + acq)
    fs_subjectlist = list(set(fs_subjectlist))
    fs_subjectarray = " ".join(fs_subjectlist)
    return fs_subjectarray

def mp2rage_to_ihmt(wildcards):
    layout=layout_dict[wildcards.field_strength]
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_ihmt = layout.get_subject(suffix="ihmt")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_ihmt))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_ihmt = layout.get_session(suffix="ihmt", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_ihmt))
        for session in sessionlist:
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            ihmt_acqlist = layout.get_acquisition(suffix="ihmt", subject=subject, session=session)
            for ihmt in ihmt_acqlist:
                apply_reg_list.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + mp2rage_first_acq + "/reg2IHMT/sub-" + subject + "_ses-" + session + "_acq-" + mp2rage_first_acq + "_applyreg2" + ihmt + ".done")
    return apply_reg_list

def mp2rage_to_qMT(wildcards):
    layout=layout_dict[wildcards.field_strength]
    apply_reg_list = []
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
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            mpm_acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for mpm in mpm_acqlist:
                mpm = mpm.replace("6eco", "").replace("3eco", "").replace("sag", "").replace("mag", "").replace("pha", "").replace("DL", "")
                for contrast in config["qmt_contrasts"].split():
                    mpm = mpm.replace(contrast, "")
                apply_reg_list.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + mp2rage_first_acq + "/reg2qMT/sub-" + subject + "_ses-" + session + "_acq-" + mp2rage_first_acq + "_applyreg2" + mpm + ".done")
    counts = Counter(apply_reg_list)
    apply_reg_list = [reg for reg, count in counts.items() if count > 3]
    return apply_reg_list

def mp2rage_to_dwi(wildcards):
    layout=layout_dict[wildcards.field_strength]
    apply_reg_list = []
    subjectlist_mp2rage = layout.get_subject(suffix="MP2RAGE")
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_dwi = layout.get_subject(suffix="dwi")
    subjectlist = list(set(subjectlist_mp2rage) & (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_dwi))
    for subject in subjectlist:
        sessionlist_mp2rage = layout.get_session(suffix="MP2RAGE", subject=subject)
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_dwi = layout.get_session(suffix="dwi", subject=subject)
        sessionlist = list(set(sessionlist_mp2rage) & (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_dwi))
        for session in sessionlist:
            mp2rage_first_acq=layout.get_acquisition(suffix="MP2RAGE", subject=subject, session=session)[0]
            dwi_acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            for dwi in dwi_acqlist:
                # dwi = dwi.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "").replace("3shb3ktra", "").replace("pha", "")
                apply_reg_list.append("data/derivatives/{field_strength}/MP2RAGE/sub-" + subject + "/ses-" + session + "/acq-" + mp2rage_first_acq + "/reg2DWI/sub-" + subject + "_ses-" + session + "_acq-" + mp2rage_first_acq + "_applyreg2DWI" + dwi + ".done")
    return apply_reg_list


rule register_ihmt_to_freesurfer_bbregister:
    input:
        ihmt="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.nii.gz",
        orig_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz"
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2FS{mp2rage_params}.lta"
    params:
        subjects_dir="data/derivatives/{field_strength}/freesurfer/",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}",
        outbase="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2FS{mp2rage_params}"
    resources:
        mem_mb=1500
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2FS{mp2rage_params}.log"
    shell:
        """
        export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license
        
        bbregister --s {params.subject} --mov {input.ihmt} --reg {output} --t1 --init-rr
        mv {params.outbase}.log {log}
        """

# rule register_ihmt_to_MP2RAGE_ants:
#     input:
#         ref="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN.nii.gz",
#         moving="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.nii.gz",
#         ref_mask="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz",
#         moving_mask="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
#     params:
#         outprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_"
#     output:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_0GenericAffine.mat"
#     conda:
#         "../envs/qMT.yaml"
#     resources: 
#         mem_mb=700
#     threads: 4
#     log:
#        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}.log" 
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

#         antsRegistration \
#         --random-seed 1 \
#         --dimensionality 3 \
#         --verbose 1 \
#         --convergence [ 1000x500x250x100, 1e-7, 100 ] \
#         --shrink-factors 8x4x2x1 \
#         --smoothing-sigmas 4x2x1x0vox \
#         --transform Rigid[0.1] \
#         --metric MI[ {input.ref}, {input.moving}, 1, 32 ] \
#         -o {params.outprefix} \
#         -x [ {input.ref_mask}, {input.moving_mask} ]
#         """

rule apply_reg_ihmt_to_freesurfer_bbregister:
    input:
        reg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2FS{mp2rage_params}.lta",
        target="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        ihmt_maps_done="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_b1corr_brain.done"
    params:
        acqdir="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/",
        subject="sub-{subject}_ses-{session}_acq-{ihmt_params}"
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_applyreg2FS{mp2rage_params}.done")
    resources:
        mem_mb=1500
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_applyreg2FS{mp2rage_params}.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        MTmaps=("cosmod_ihMTR" "freqalt_ihMTR" "BPR" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr")
        mkdir -p "{params.acqdir}/reg2MP2RAGE"
        for map in "${{MTmaps[@]}}"; do
            moving="{params.acqdir}/{params.subject}_"$map"_brain.nii.gz"
            out="{params.acqdir}/reg2MP2RAGE/{params.subject}_"$map"_reg2FS{wildcards.mp2rage_params}.nii.gz"
            if [ -f $moving ]; then
                mri_vol2vol --mov $moving --targ {input.target} --o $out --reg {input.reg} --no-save-reg
            fi
        done
        touch {output}
        """


# rule apply_reg_ihmt_to_MP2RAGE_ants:
#     input:
#         ref="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1w_UNIDEN.nii.gz",
#         reg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_0GenericAffine.mat",
#         ihmt_maps_done="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_b1corr_brain.done"
#     params:
#         acqdir="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/",
#         subject="sub-{subject}_ses-{session}_acq-{ihmt_params}"
#     output:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_applyreg2{mp2rage_params}.done"
#     resources: 
#         mem_mb=500
#     conda:
#         "../envs/qMT.yaml"
#     threads: 1
#     log:
#         "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_applyreg2{mp2rage_params}.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

#         MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTR" "freqalt_ihMTR" "BPR" "MTRs_b1corr" "cosmod_MTRd_b1corr" "freqalt_MTRd_b1corr" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr")
#         mkdir -p "{params.acqdir}/reg2MP2RAGE"
#         for map in "${{MTmaps[@]}}"; do
#             moving="{params.acqdir}/{params.subject}_"$map".nii.gz"
#             out="{params.acqdir}/reg2MP2RAGE/{params.subject}_"$map"_reg2{wildcards.mp2rage_params}.nii.gz"
#             if [ -f $moving ]; then
#                 antsApplyTransforms \
#                 --dimensionality 3 \
#                 --interpolation Linear \
#                 --verbose 1 \
#                 -i $moving \
#                 -r {input.ref} \
#                 -t {input.reg} \
#                 -o $out
#             fi
#         done
#         touch {output}
#         """


# rule gather_ihmt_to_MP2RAGE_ants:
rule gather_ihmt_to_freesurfer_bbregister:
    input:
        # ihmt_to_mp2rage,
        ihmt_to_freesurfer
    output:
        # "data/derivatives/{field_strength}/ihmt/ihmt_to_MP2RAGE.done"
        "data/derivatives/{field_strength}/ihmt/ihmt_to_freesurfer.done"
    log:
        # "logs/{field_strength}/ihmt/ihmt_to_MP2RAGE.log"
        "logs/{field_strength}/ihmt/ihmt_to_freesurfer.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


# rule apply_reg_seg_to_ihmt_ants:
#     input:
#         seg = resliced_segmentation_first_acq_mp2rage,
#         reg = ihmt_reg2first_acq_mp2rage,
#         ihmt_maps_done="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_b1corr_brain.done"
#     params:
#         refprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}"
#     output:
#         "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_{segmentation}.nii.gz"
#     resources: 
#         mem_mb=500
#     conda:
#         "../envs/qMT.yaml"
#     threads: 1
#     log:
#        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_{segmentation}.log" 
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

#         #choose ref based on what maps are available
#         MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTR" "freqalt_ihMTR" "BPR" "MTRs_b1corr" "cosmod_MTRd_b1corr" "freqalt_MTRd_b1corr" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr")
#         for map in "${{MTmaps[@]}}"; do
#             ref_init="{params.refprefix}_"$map".nii.gz"
#             if [ -f $ref_init ]; then #if file exists, then set ref
#                 ref=$ref_init
#             fi
#         done
        
#         #apply inverse reg so that seg is in ihmt space, to avoid interpolation of ihmt
#         antsApplyTransforms \
#         --dimensionality 3 \
#         --interpolation NearestNeighbor \
#         --verbose 1 \
#         -i {input.seg} \
#         -r $ref \
#         -t [ {input.reg}, 1 ] \
#         -o {output}
#         """

rule apply_aparc_aseg_to_ihmt_bbregister:
    input:
        seg = aparc_aseg_first_acq_freesurfer,
        reg = ihmt_reg2first_acq_freesurfer,
        ihmt_maps_done="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_b1corr_brain.done"
    params:
        refprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}"
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_aparc+aseg.nii.gz"
    resources: 
        mem_mb=500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    threads: 1
    log:
       "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_aparc+aseg.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        #choose ref based on what maps are available
        MTmaps=("cosmod_ihMTR" "freqalt_ihMTR" "BPR" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr")
        for map in "${{MTmaps[@]}}"; do
            ref_init="{params.refprefix}_"$map"_brain.nii.gz"
            if [ -f $ref_init ]; then #if file exists, then set ref
                ref=$ref_init
            fi
        done
        
        #apply inverse reg so that seg is in ihmt space, to avoid interpolation of ihmt
        mri_vol2vol \
        --inv --nearest --no-save-reg \
        --mov "$ref" --targ {input.seg} --reg {input.reg} \
        --o {output}
        """


rule warp_ihmt_to_mni152:
    input:
        ihmt2fs=ihmt_reg2first_acq_freesurfer,
        fs2mni152=fs2mni152_first_acq
    output:
        ihmt2mni152="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2mni152_warp.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2mni152_warp.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_warp_convert \
        --lta1 {input.ihmt2fs} \
        --inm3z {input.fs2mni152} \
        --outm3z {output.ihmt2mni152}
        """


rule apply_warp_mni_atlases_to_ihmt:
    input:
        subj2mni152="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2mni152_warp.nii.gz",
        aparc_aseg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_aparc+aseg.nii.gz",
        wm90percent_lobes="data/atlases/mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/atlases/mni_icbm152_wm_lobes.nii.gz"
    output:
        wm_mask="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_wm_mask.nii.gz",
        wm90percent_lobes="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_mni_icbm152_wm_lobes.nii.gz",
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}/apply_warp_mni_atlases_to_ihmt.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_binarize --i {input.aparc_aseg} --o {output.wm_mask} --match 2 7 41 46

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm90percent_lobes} {output.wm90percent_lobes}
        mri_mask {output.wm90percent_lobes} {output.wm_mask} {output.wm90percent_lobes}

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm_lobes} {output.wm_lobes}
        mri_mask {output.wm_lobes} {output.wm_mask} {output.wm_lobes}
        """


rule ihmt_roi_stats:
    input:
        ihmt_done="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_b1corr_brain.done",
        # seg="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/mri/ihmt/{segmentation}_reg2{ihmt_params}.nii.gz",
        seg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_{segmentation}.nii.gz",
        lut="data/atlases/{segmentation}_lut.txt",
    params:
        ihmtprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}",
        outdir="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/stats_temp",
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/stats_temp/sub-{subject}_ses-{session}_acq-{ihmt_params}_{segmentation}_stats.done"),
        # stats=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_{segmentation}_stats.pickle"),
        # nooutliers_stats=temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_{segmentation}_nooutliers_stats.pickle")
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_seg-{segmentation}_stats.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        MTmaps=("cosmod_ihMTR" "freqalt_ihMTR" "BPR" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr")
        for map in "${{MTmaps[@]}}"; do
            ihmt="{params.ihmtprefix}_${{map}}_brain.nii.gz"
            if [ -f $ihmt ]; then
                python3 workflow/scripts/roi_stats.py "${{ihmt}}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.subject}" "{wildcards.session}" "{wildcards.ihmt_params}" "${{map}}"
                python3 workflow/scripts/roi_stats.py -r "${{ihmt}}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.subject}" "{wildcards.session}" "{wildcards.ihmt_params}" "${{map}}"
            fi
        done

        touch {output}
        
        """


rule ihmt_roi_stats_agg_segs:
    input:
        stats=expand("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/stats_temp/sub-{subject}_ses-{session}_acq-{ihmt_params}_{segmentation}_stats.done", 
        segmentation=config["segmentations"].split(), allow_missing=True),    
    params:
        stats_temp="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/stats_temp",
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_stats.pickle",
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_stats.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        stats_list = sorted(Path(input.stats[0]).parent.glob("*_stats.pickle"))
        df_stats = pd.concat((pd.read_pickle(s) for s in stats_list), ignore_index=True)
        df_stats.to_pickle(str(output))
        shutil.rmtree(params.stats_temp)


rule ihmt_roi_stats_agg_subjs:
    input:
        ihmt_statslist
    output:
        "data/derivatives/{field_strength}/ihmt/ihmt_stats.pickle"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/ihmt/ihmt_stats.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        df_stats = pd.concat((pd.read_pickle(i) for i in input), ignore_index=True)
        df_stats.to_pickle(str(output))


# rule ihmt_stats:
#     input:
#         "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/mri/aparc+aseg_reg2IHMT.nii.gz"
#     params:
#         ihmtprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}",
#         statsprefix="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/stats/ihmt"
#     output:
#         "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/stats/ihmt_stats.done"
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     resources:
#         mem_mb=500
#     threads: 1
#     log:
#         "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{ihmt_params}/ihmt_stats.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export FS_LICENSE=$HOME/.snakemake/scripts/.license

#         MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTR" "freqalt_ihMTR" "BPR" "MTRs_b1corr" "cosmod_MTRd_b1corr" "freqalt_MTRd_b1corr" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr")
        
#         for map in "${{MTmaps[@]}}"; do
#             ihmt="{params.ihmtprefix}_${{map}}.nii.gz"
#             stats="{params.statsprefix}_${{map}}.stats"
#             if [ -f $ihmt ]; then
#                 mri_segstats --seg {input} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i $ihmt --sum $stats --excludeid 0
#             fi
#         done

#         touch {output}
#         """


# rule ihmt_tsv:
#     input:
#         ihmt_statslist,
#     params:
#         subjectlist=freesurfer_subjectlist_ihmt,
#         subjects_dir="data/derivatives/{field_strength}/freesurfer/"
#     output:
#         "data/derivatives/{field_strength}/freesurfer/ihmt_stats.done"
#     container:
#         "docker://freesurfer/freesurfer:8.1.0"
#     resources:
#         mem_mb=500
#     threads: 1
#     log:
#         "logs/{field_strength}/freesurfer/ihmt_stats_tsv.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        
#         export FS_LICENSE=$HOME/.snakemake/scripts/.license

#         MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTR" "freqalt_ihMTR" "BPR" "MTRs_b1corr" "cosmod_MTRd_b1corr" "freqalt_MTRd_b1corr" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr")
        
#         if ! [ -n {params.subjectlist} ]; then
#             for map in "${{MTmaps[@]}}"; do
#                 asegstats2table --subjects {params.subjectlist} --statsfile ihmt_${{map}}.stats -t $SUBJECTS_DIR/ihmt_${{map}}_stats.tsv --meas mean --common-segs --no-segno 0 --skip || \
#                 echo "no subjects have this map!"
#             done
#         fi
#         touch {output}
#         """

rule apply_reg_MP2RAGE_to_ihmt_ants:
    input:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_b1corr.nii.gz",
        reg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_0GenericAffine.mat",
        ihmt_maps_done="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_b1corr_brain.done"
    params:
        ihmt_prefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}",
        mp2rage_acqdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/",
        mp2rage_subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2IHMT/sub-{subject}_ses-{session}_acq-{mp2rage_params}_applyreg2{ihmt_params}.done"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
      "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2IHMT/applyreg2{ihmt_params}.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        #set reference based on what maps are availble
        MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTR" "freqalt_ihMTR" "BPR" "MTRs_b1corr" "cosmod_MTRd_b1corr" "freqalt_MTRd_b1corr" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr")
        for map in "${{MTmaps[@]}}"; do
            ref_init="{params.ihmt_prefix}_"$map".nii.gz"
            if [ -f $ref_init ]; then #if file exists, then set ref
                ref=$ref_init
            fi
        done

        MP2RAGEmaps=("R1map_b1corr" "T1map_b1corr" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
        mkdir -p {params.mp2rage_acqdir}/reg2IHMT
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="{params.mp2rage_acqdir}/{params.mp2rage_subject}_"$map".nii.gz"
            out="{params.mp2rage_acqdir}/reg2IHMT/{params.mp2rage_subject}_"$map"_reg2{wildcards.ihmt_params}.nii.gz"

            #apply inverse of ihmt to MP2RAGE transform to each MP2RAGE map
            antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i $moving \
            -r $ref \
            -t [ {input.reg}, 1 ] \
            -o $out
        done
        touch {output}
        """

        
# rule apply_reg_MP2RAGE_to_ihmt_ants:
#     input:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_b1corr.nii.gz",
#         reg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2{mp2rage_params}_0GenericAffine.mat",
#         ihmt_maps_done="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_b1corr_brain.done"
#     params:
#         ihmt_prefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}",
#         mp2rage_acqdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/",
#         mp2rage_subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2IHMT/sub-{subject}_ses-{session}_acq-{mp2rage_params}_applyreg2{ihmt_params}.done"
#     resources: 
#         mem_mb=500
#     threads: 1
#     conda:
#         "../envs/qMT.yaml"
#     log:
#       "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2IHMT/applyreg2{ihmt_params}.log"  
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

#         #set reference based on what maps are availble
#         MTmaps=("MTRs" "cosmod_MTRd" "freqalt_MTRd" "cosmod_ihMTR" "freqalt_ihMTR" "BPR" "MTRs_b1corr" "cosmod_MTRd_b1corr" "freqalt_MTRd_b1corr" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr")
#         for map in "${{MTmaps[@]}}"; do
#             ref_init="{params.ihmt_prefix}_"$map".nii.gz"
#             if [ -f $ref_init ]; then #if file exists, then set ref
#                 ref=$ref_init
#             fi
#         done

#         MP2RAGEmaps=("R1map_b1corr" "T1map_b1corr" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
#         mkdir -p {params.mp2rage_acqdir}/reg2IHMT
#         for map in "${{MP2RAGEmaps[@]}}"; do
#             moving="{params.mp2rage_acqdir}/{params.mp2rage_subject}_"$map".nii.gz"
#             out="{params.mp2rage_acqdir}/reg2IHMT/{params.mp2rage_subject}_"$map"_reg2{wildcards.ihmt_params}.nii.gz"

#             #apply inverse of ihmt to MP2RAGE transform to each MP2RAGE map
#             antsApplyTransforms \
#             --dimensionality 3 \
#             --interpolation Linear \
#             --verbose 1 \
#             -i $moving \
#             -r $ref \
#             -t [ {input.reg}, 1 ] \
#             -o $out
#         done
#         touch {output}
#         """


# rule gather_MP2RAGE_to_ihmt_ants:
#     input:
#         mp2rage_to_ihmt,
#     output:
#         "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_ihmt.done"
#     log:
#         "logs/{field_strength}/MP2RAGE/MP2RAGE_to_ihmt.log"
#     shell:
#         """
#         exec > >(tee {log}) 2>&1 #save output to log AND print to console

#         touch {output}
#         """


rule aggregate_multimodal_ihmt_mp2rage:
    input:
        expand("data/derivatives/{field_strength}/ihmt/ihmt_stats.pickle", field_strength=field_strength_list),
        # expand("data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_ihmt.done", field_strength=field_strength_list),
        expand("data/derivatives/{field_strength}/ihmt/ihmt_to_freesurfer.done", field_strength=field_strength_list)


rule register_qMT_to_MP2RAGE_ants:
    input:
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_b1corr_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_mask.nii.gz"
    params:
        outprefix="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_reg2{mp2rage_params}_"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_reg2{mp2rage_params}_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1500
    threads: 4
    log:
       "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_reg2{mp2rage_params}.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        antsRegistration \
        --random-seed 1 \
        --dimensionality 3 \
        --verbose 1 \
        --convergence [ 1000x500x250x100, 1e-7, 100 ] \
        --shrink-factors 8x4x2x1 \
        --smoothing-sigmas 4x2x1x0vox \
        --transform Rigid[0.1] \
        --metric MI[ {input.ref}, {input.moving}, 1, 32 ] \
        -o {params.outprefix} \
        -x [ {input.ref_mask}, {input.moving_mask} ]
        """


rule apply_reg_qMT_to_MP2RAGE_ants:
    input:
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.nii.gz",
        reg = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_reg2{mp2rage_params}_0GenericAffine.mat"
    params:
        sessiondir="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/",
        regto="reg2{mp2rage_params}",
        qMTprefix="sub-{subject}_ses-{session}_acq-{seq}{qMT_params}"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_applyreg2{mp2rage_params}.done"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
      "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_applyreg2{mp2rage_params}.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        qMTmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        mkdir -p {params.sessiondir}/reg2MP2RAGE
        for map in "${{qMTmaps[@]}}"; do
            moving="{params.sessiondir}/{params.qMTprefix}_"$map".nii.gz"
            out="{params.sessiondir}/reg2MP2RAGE/{params.qMTprefix}_"$map"_{params.regto}.nii.gz"
            if [ -f $moving ]; then
                antsApplyTransforms \
                --dimensionality 3 \
                --interpolation Linear \
                --verbose 1 \
                -i $moving \
                -r {input.ref} \
                -t {input.reg} \
                -o $out
            fi
        done
        touch {output}
        """


rule gather_qMT_to_MP2RAGE_ants:
    input:
        qMT_to_mp2rage,
    output:
        "data/derivatives/{field_strength}/qMT/qMT_to_MP2RAGE.done"
    log:
        "logs/{field_strength}/qMT/qMT_to_MP2RAGE.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        touch {output}
        """


rule apply_reg_seg_to_qMT_ants:
    input:
        seg = resliced_segmentation_first_acq_mp2rage,
        reg = qMT_reg2first_acq_mp2rage,
        ref = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}/mri/aparc+aseg_reg2qMT.nii.gz"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}/aparc+aseg_reg2qMT.log"
    shell:
        """ 
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        #apply inverse reg so that seg is in qMT space, to avoid interpolation of qMT
        antsApplyTransforms \
        --dimensionality 3 \
        --interpolation NearestNeighbor \
        --verbose 1 \
        -i {input.seg} \
        -r {input.ref} \
        -t [ {input.reg}, 1 ] \
        -o {output}
        """
  

rule qMT_stats:
    input:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}/mri/aparc+aseg_reg2qMT.nii.gz",
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_MTRmap.nii.gz"
    params:
        qMTprefix="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}",
        statsprefix="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}/stats/qMT"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}/stats/qMT_stats.done"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=500
    threads: 1
    log:
       "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}/qMT_stats.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        qMTmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        
        for map in "${{qMTmaps[@]}}"; do
            qMT="{params.qMTprefix}_"$map".nii.gz"
            stats="{params.statsprefix}_${{map}}.stats"
            if [ -f $qMT ]; then
                mri_segstats --seg {input[0]} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i $qMT --sum $stats --excludeid 0
            fi
        done

        touch {output}
        """


rule qMT_tsv:
    input:
        qMT_statslist,
    output:
        "data/derivatives/{field_strength}/freesurfer/qMT_stats.done"
    params:
        subjectlist=freesurfer_subjectlist_qMT,
        subjects_dir="data/derivatives/{field_strength}/freesurfer/"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=500
    threads: 1
    log:
      "logs/{field_strength}/freesurfer/qMT_stats_tsv.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        qMTmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        
        if ! [ -n {params.subjectlist} ]; then
            for map in "${{qMTmaps[@]}}"; do
                asegstats2table --subjects {params.subjectlist} --statsfile qMT_${{map}}.stats -t $SUBJECTS_DIR/qMT_${{map}}_stats.tsv --meas mean --common-segs --no-segno 0 --skip || \
                echo "no subjects have this map!"
            done
        fi
        touch {output}
        """


rule apply_reg_MP2RAGE_to_qMT_ants:
    input:
        ref="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map.nii.gz",
        reg="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_reg2{mp2rage_params}_0GenericAffine.mat"
    params:
        mp2rage_acqdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/",
        regto="reg2{seq}{qMT_params}",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2qMT/sub-{subject}_ses-{session}_acq-{mp2rage_params}_applyreg2{seq}{qMT_params}.done"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2qMT/sub-{subject}_ses-{session}_acq-{mp2rage_params}_applyreg2{seq}{qMT_params}.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        MP2RAGEmaps=("R1map_b1corr" "T1map_b1corr" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
        mkdir -p {params.mp2rage_acqdir}/reg2qMT
        for map in "${{MP2RAGEmaps[@]}}"; do
            moving="{params.mp2rage_acqdir}/{params.subject}_"$map".nii.gz"
            out="{params.mp2rage_acqdir}/reg2qMT/{params.subject}_"$map"_{params.regto}.nii.gz"

            #apply inverse of qMT to MP2RAGE registration
            antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i $moving \
            -r {input.ref} \
            -t [ {input.reg}, 1 ] \
            -o $out
        done
        touch {output}
        """


rule gather_MP2RAGE_to_qMT_ants:
    input:
        mp2rage_to_qMT,
    output:
        "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_qMT.done"
    log:
        "logs/{field_strength}/MP2RAGE/MP2RAGE_to_qMT.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule aggregate_multimodal_qMT_mp2rage:
    input:
        expand("data/derivatives/{field_strength}/freesurfer/qMT_stats.done", field_strength=field_strength_list),
        expand("data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_qMT.done", field_strength=field_strength_list),
        expand("data/derivatives/{field_strength}/qMT/qMT_to_MP2RAGE.done", field_strength=field_strength_list)


rule register_DWI_to_MP2RAGE_bbregister:
    input:
        meanb0="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brain.nii.gz",
        orig_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz"
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2{mp2rage_params}.lta"
    params:
        subjects_dir="data/derivatives/{field_strength}/freesurfer/",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}",
        outbase="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2{mp2rage_params}"
    resources:
        mem_mb=1500
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2{mp2rage_params}.log"
    shell:
        """
        export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license
        
        bbregister --s {params.subject} --mov {input.meanb0} --reg {output} --dti --init-fsl --9
        mv {params.outbase}.log {log}
        """


rule apply_reg_DWI_to_MP2RAGE_bbregister:
    input:
        reg="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2{mp2rage_params}.lta",
        target="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        moving="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/"
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_applyreg2{mp2rage_params}.done"
    params:
        acqdir="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/",
        regto="reg2{mp2rage_params}",
        dwiprefix="sub-{subject}_ses-{session}_acq-DWI{dwi_params}"
    resources:
        mem_mb=1500
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
       "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_applyreg2{mp2rage_params}.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        dkimaps=("ad" "ak" "color_fa" "fa" "kfa" "md" "mk" "mkt" "rd" "rk" "rtk")

        for map in "${{dkimaps[@]}}"; do
            moving="{params.acqdir}/dki/{params.dwiprefix}_"$map".nii.gz"
            out="{params.acqdir}/reg2MP2RAGE/dki/{params.dwiprefix}_"$map"_{params.regto}.nii.gz"
            if [ -f $moving ]; then
                mri_vol2vol --mov $moving --targ {input.target} --o $out --reg {input.reg} --no-save-reg
            fi
        done
        touch {output}
        """


rule gather_DWI_to_MP2RAGE_bbregister:
    input:
        dwi_to_mp2rage,
    output:
        "data/derivatives/{field_strength}/dwi/DWI_to_MP2RAGE.done"
    log:
        "logs/{field_strength}/dwi/DWI_to_MP2RAGE.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule apply_reg_seg_to_dwi_bbregister:
    input:
        seg = resliced_segmentation_first_acq_mp2rage,
        reg = dwi_reg2first_acq_mp2rage,
        b0 = "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brain.nii.gz"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-DWI{dwi_params}/mri/aparc+aseg_reg2DWI.nii.gz"
    resources: 
        mem_mb=500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-DWI{dwi_params}/aparc+aseg_reg2DWI.log"
    shell:
        """ 
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        #apply inverse reg so that seg is in dwi space, to avoid interpolation of dwi
        mri_vol2vol --mov {input.b0} --targ {input.seg} --inv --interp nearest --o {output} --reg {input.reg} --no-save-reg
        """


rule dwi_stats:
    input:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-DWI{dwi_params}/mri/aparc+aseg_reg2DWI.nii.gz",
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/"
    params:
        dkiprefix="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/sub-{subject}_ses-{session}_acq-DWI{dwi_params}",
        statsprefix="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-DWI{dwi_params}/stats/dki"
    output:
        "data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-DWI{dwi_params}/stats/dwi_stats.done"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=500
    threads: 1
    log:
       "logs/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-DWI{dwi_params}/dwi_stats.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        dkimaps=("ad" "ak" "color_fa" "fa" "kfa" "md" "mk" "mkt" "rd" "rk" "rtk")
        
        for map in "${{dkimaps[@]}}"; do
            qMT="{params.dkiprefix}_"$map".nii.gz"
            stats="{params.statsprefix}_${{map}}.stats"
            if [ -f $qMT ]; then
                mri_segstats --seg {input[0]} --ctab $FREESURFER_HOME/FreeSurferColorLUT.txt --i $qMT --sum $stats --excludeid 0
            fi
        done

        touch {output}
        """


rule dwi_tsv:
    input:
        dwi_statslist,
    output:
        "data/derivatives/{field_strength}/freesurfer/dwi_stats.done"
    params:
        subjectlist=freesurfer_subjectlist_dwi,
        subjects_dir="data/derivatives/{field_strength}/freesurfer/"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=500
    threads: 1
    log:
      "logs/{field_strength}/freesurfer/dwi_stats_tsv.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export SUBJECTS_DIR=$HOME/{params.subjects_dir}
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        dkimaps=("ad" "ak" "color_fa" "fa" "kfa" "md" "mk" "mkt" "rd" "rk" "rtk")
        
        if ! [ -n {params.subjectlist} ]; then
            for map in "${{dkimaps[@]}}"; do
                asegstats2table --subjects {params.subjectlist} --statsfile dki_${{map}}.stats -t $SUBJECTS_DIR/dki_${{map}}_stats.tsv --meas mean --common-segs --no-segno 0 --skip || \
                echo "no subjects have this map!"
            done
        fi
        touch {output}
        """


rule apply_reg_MP2RAGE_to_dwi_bbregister:
    input:
        b0 = "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brain.nii.gz",
        target="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        reg = "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2{mp2rage_params}.lta"
    params:
        mp2rage_acqdir="data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/",
        regto="reg2DWI{dwi_params}",
        mp2rage_subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}"
    output:
        "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2DWI/sub-{subject}_ses-{session}_acq-{mp2rage_params}_applyreg2DWI{dwi_params}.done"
    resources: 
        mem_mb=500
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/reg2DWI/sub-{subject}_ses-{session}_acq-{mp2rage_params}_applyreg2DWI{dwi_params}.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        
        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        MP2RAGEmaps=("R1map_b1corr" "T1map_b1corr" "T1w_UNIDEN_b1corr" "T1w_UNI_b1corr" "T1w_UNIDEN")
        mkdir -p {params.mp2rage_acqdir}/reg2DWI
        for map in "${{MP2RAGEmaps[@]}}"; do
            target="{params.mp2rage_acqdir}/{params.mp2rage_subject}_"$map".nii.gz"
            out="{params.mp2rage_acqdir}/reg2DWI/{params.mp2rage_subject}_"$map"_{params.regto}.nii.gz"

            #apply inverse of qMT to MP2RAGE registration
            mri_vol2vol --mov {input.b0} --targ $target --inv --o $out --reg {input.reg} --no-save-reg
        done
        touch {output}
        """


rule gather_MP2RAGE_to_dwi_bbregister:
    input:
        mp2rage_to_dwi,
    output:
        "data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_DWI.done"
    log:
        "logs/{field_strength}/MP2RAGE/MP2RAGE_to_DWI.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """

rule aggregate_multimodal_dwi_mp2rage:
    input:
        expand("data/derivatives/{field_strength}/freesurfer/dwi_stats.done", field_strength=field_strength_list),
        expand("data/derivatives/{field_strength}/MP2RAGE/MP2RAGE_to_DWI.done", field_strength=field_strength_list),
        expand("data/derivatives/{field_strength}/dwi/DWI_to_MP2RAGE.done", field_strength=field_strength_list)