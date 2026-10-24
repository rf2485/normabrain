#rules for multimodal registration and segmentation, not including B1map which is a dependency for regular pre-processing for MP2RAGE, ihMT, and qMT
#dependent on all other smk files
import os
import shutil
from bids import BIDSLayout
from collections import Counter
from pathlib import Path

qmt_contrasts = ("mt0", "mtw", "pdw", "t1w")

#get field strength list from BIDS folder
bidspath = Path("data/rawdata/bids")
try:
    field_strength_list = next(os.walk(bidspath))[1]
except (OSError, StopIteration): #if there's no BIDS folder return empty list
    field_strength_list = []
layout_dict = { #run BIDSLayout once per field_strength and save to dictionary
    field_strength: BIDSLayout(bidspath / field_strength, validate=False)
    for field_strength in field_strength_list
}


wildcard_constraints:
    contrast = '|'.join(qmt_contrasts),
    part = 'mag|phase',


def qMT_to_freesurfer(wildcards):
    """Return list of expected qMT registered to FreeSurfer done files, given raw BIDS images."""
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
            mpm_acqlist = get_mpm_acquisitions(
                wildcards.field_strength, subject, session
            )
            mp2rage_first_acq=get_mp2rage_acquisitions(
                wildcards.field_strength, subject, session)[0]
            for mpm in mpm_acqlist:

                apply_reg_list.append("data/derivatives/{field_strength}/qMT/sub-" + subject + "/ses-" + session + "/acq-" + mpm + "/reg2MP2RAGE/sub-" + subject + "_ses-" + session + "_acq-" + mpm + "_applyreg2FS" + mp2rage_first_acq + ".done")
    return sorted(set(apply_reg_list))

def ihmt_to_freesurfer(wildcards):
    """Return list of expected ihMT registered to FreeSurfer done files, given raw BIDS images."""
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
            ihmt_acqlist = get_ihmt_acquisitions(
                wildcards.field_strength, subject, session)
            mp2rage_first_acq=get_mp2rage_acquisitions(
                wildcards.field_strength, subject, session)[0]
            for ihmt in ihmt_acqlist:
                apply_reg_list.append("data/derivatives/{field_strength}/ihmt/sub-" + subject + "/ses-" + session + "/acq-" + ihmt + "/reg2MP2RAGE/sub-" + subject + "_ses-" + session + "_acq-" + ihmt + "_applyreg2FS" + mp2rage_first_acq + ".done")
    return apply_reg_list

def dwi_to_freesurfer(wildcards):
    """Return list of expected DWI registered to FreeSurfer done files, given raw BIDS images."""
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
            mp2rage_first_acq=get_mp2rage_acquisitions(
                wildcards.field_strength, subject, session)[0]
            for dwi in dwi_acqlist:
                # dwi = dwi.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "").replace("3shb3ktra", "").replace("pha", "")
                apply_reg_list.append("data/derivatives/{field_strength}/dwi/sub-" + subject + "/ses-" + session + "/acq-DWI" + dwi + "/reg2MP2RAGE/sub-" + subject + "_ses-" + session + "_acq-DWI" + dwi + "_applyreg2FS" + mp2rage_first_acq + ".done" )
    return apply_reg_list

def ihmt_reg2first_acq_freesurfer(wildcards):
    """Return filepath for registration of ihMT to FreeSurfer space of the first MP2RAGE acquisiton."""
    first_acq=get_mp2rage_acquisitions(
                wildcards.field_strength, wildcards.subject, wildcards.session)[0]
    return expand(
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2FS{mp2rage_params}.lta", 
        field_strength=wildcards.field_strength,
        subject=wildcards.subject,
        session=wildcards.session,
        ihmt_params=wildcards.ihmt_params,
        mp2rage_params=first_acq)

def qMT_reg2first_acq_freesurfer(wildcards):
    """Return filepath for registration of qMT to FreeSurfer space of the first MP2RAGE acquisiton"""
    first_acq=get_mp2rage_acquisitions(
                wildcards.field_strength, wildcards.subject, wildcards.session)[0]
    return expand(
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{qMT_params}_reg2FS{mp2rage_params}.lta", 
        field_strength=wildcards.field_strength,
        subject=wildcards.subject,
        session=wildcards.session,
        qMT_params=wildcards.qMT_params,
        mp2rage_params=first_acq)

def dwi_reg2first_acq_freesurfer(wildcards):
    """Return filepath for registration of DWI to FreeSurfer space of the first MP2RAGE acquisition."""
    first_acq=get_mp2rage_acquisitions(
                wildcards.field_strength, wildcards.subject, wildcards.session)[0]
    return expand(
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2FS{mp2rage_params}.lta", 
        field_strength=wildcards.field_strength,
        subject=wildcards.subject,
        session=wildcards.session,
        dwi_params=wildcards.dwi_params,
        mp2rage_params=first_acq)

def ihmt_statslist(wildcards):
    """Return list of expected ihMT stats files given raw BIDS files."""
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
            acqlist = get_ihmt_acquisitions(
                wildcards.field_strength, subject, session)
            for acq in acqlist:
                statslist.append("data/derivatives/" + wildcards.field_strength + "/ihmt/sub-" + subject + "/ses-" + session + "/acq-" + acq + "/sub-" + subject + "_ses-" + session + "_acq-" + acq + "_stats.pickle")
    return sorted(statslist)

def qMT_statslist(wildcards):
    """Return list of expected qMT stats files given raw BIDS files."""
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
            acqlist = get_mpm_acquisitions(
                wildcards.field_strength, subject, session
            )
            for acq in acqlist:
                statslist.append("data/derivatives/" + wildcards.field_strength + "/qMT/sub-" + subject + "/ses-" + session + "/acq-" + acq + "/sub-" + subject + "_ses-" + session + "_acq-" + acq + "_stats.pickle")
    return sorted(set(statslist))

def dwi_statslist(wildcards):
    """Return list of expected DWI stats files given raw BIDS files."""
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
                statslist.append("data/derivatives/" + wildcards.field_strength + "/dwi/sub-" + subject + "/ses-" + session + "/acq-DWI" + acq + "/sub-" + subject + "_ses-" + session + "_acq-DWI" + acq + "_stats.pickle")
    return sorted(statslist)


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

        MTmaps=("cosmod_ihMTR" "freqalt_ihMTR" "BPR" "DO" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr" "DO_b1corr")
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


rule gather_ihmt_to_freesurfer_bbregister:
    input:
        ihmt_to_freesurfer
    output:
        temp("data/derivatives/{field_strength}/ihmt/ihmt_to_freesurfer.done")
    log:
        "logs/{field_strength}/ihmt/ihmt_to_freesurfer.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule apply_aparc_aseg_to_ihmt_bbregister:
    input:
        seg = aparc_aseg_first_acq_freesurfer,
        reg = ihmt_reg2first_acq_freesurfer,
        ihmt_maps_done="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_b1corr_brain.done"
    params:
        refprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}"
    output:
        "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/masks_segs/sub-{subject}_ses-{session}_acq-{ihmt_params}_aparc+aseg.nii.gz"
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
        MTmaps=("cosmod_ihMTR" "freqalt_ihMTR" "BPR" "DO" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr" "DO_b1corr")
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
        ihmt2mni152="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/masks_segs/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2mni152_warp.nii.gz"
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
        subj2mni152="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/masks_segs/sub-{subject}_ses-{session}_acq-{ihmt_params}_reg2mni152_warp.nii.gz",
        aparc_aseg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/masks_segs/sub-{subject}_ses-{session}_acq-{ihmt_params}_aparc+aseg.nii.gz",
        wm90percent_lobes="data/atlases/mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/atlases/mni_icbm152_wm_lobes.nii.gz"
    output:
        wm_mask="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/masks_segs/sub-{subject}_ses-{session}_acq-{ihmt_params}_wm_mask.nii.gz",
        wm90percent_lobes="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/masks_segs/sub-{subject}_ses-{session}_acq-{ihmt_params}_mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/masks_segs/sub-{subject}_ses-{session}_acq-{ihmt_params}_mni_icbm152_wm_lobes.nii.gz",
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_apply_warp_mni_atlases_to_ihmt.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_binarize --i {input.aparc_aseg} --o {output.wm_mask} --match 2 7 41 46

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm90percent_lobes} {output.wm90percent_lobes}
        masked_wm90percent_lobes="{output.wm90percent_lobes}.masked.nii.gz"
        mri_mask {output.wm90percent_lobes} {output.wm_mask} "$masked_wm90percent_lobes"
        mv "$masked_wm90percent_lobes" {output.wm90percent_lobes}

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm_lobes} {output.wm_lobes}
        masked_wm_lobes="{output.wm_lobes}.masked.nii.gz"
        mri_mask {output.wm_lobes} {output.wm_mask} "$masked_wm_lobes"
        mv "$masked_wm_lobes" {output.wm_lobes}
        """


rule ihmt_roi_stats:
    input:
        ihmt_done="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_b1corr_brain.done",
        seg="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/masks_segs/sub-{subject}_ses-{session}_acq-{ihmt_params}_{segmentation}.nii.gz",
        lut="data/atlases/{segmentation}_lut.txt",
    params:
        ihmtprefix="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}",
        outdir="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/stats_temp",
    output:
        temp("data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/stats_temp/sub-{subject}_ses-{session}_acq-{ihmt_params}_{segmentation}_stats.done"),
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_seg-{segmentation}_stats.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        MTmaps=("cosmod_ihMTR" "freqalt_ihMTR" "BPR" "DO" "cosmod_ihMTR_b1corr" "freqalt_ihMTR_b1corr" "BPR_b1corr" "DO_b1corr")
        for map in "${{MTmaps[@]}}"; do
            ihmt="{params.ihmtprefix}_${{map}}_brain.nii.gz"
            if [ -f $ihmt ]; then
                python3 workflow/scripts/roi_stats.py "${{ihmt}}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.field_strength}" "ihMT" "{wildcards.subject}" "{wildcards.session}" "{wildcards.ihmt_params}" "${{map}}"
                python3 workflow/scripts/roi_stats.py -r "${{ihmt}}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.field_strength}" "ihMT" "{wildcards.subject}" "{wildcards.session}" "{wildcards.ihmt_params}" "${{map}}"
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
        "data/derivatives/{field_strength}/ihmt/ihmt_stats_{field_strength}.pickle"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/ihmt/ihmt_stats_{field_strength}.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        if input:
            df_stats = pd.concat((pd.read_pickle(i) for i in input), ignore_index=True)
        else:
            df_stats = pd.DataFrame()
        df_stats.to_pickle(str(output))


rule aggregate_ihmt_stats:
    input:
        expand("data/derivatives/{field_strength}/ihmt/ihmt_stats_{field_strength}.pickle", field_strength=field_strength_list),
    output:
        "data/derivatives/ihmt_stats.pickle"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/ihmt_stats.log"
    run:
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        if input:
            df_stats = pd.concat((pd.read_pickle(i) for i in input), ignore_index=True)
        else:
            df_stats = pd.DataFrame()
        df_stats.to_pickle(str(output))


rule aggregate_multimodal_ihmt_mp2rage:
    input:
        "data/derivatives/ihmt_stats.pickle",
        expand("data/derivatives/{field_strength}/ihmt/ihmt_to_freesurfer.done", field_strength=field_strength_list)


rule register_qMT_to_freesurfer_bbregister:
    input:
        qMT="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain_denoised_n4.nii.gz",
        orig_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{qMT_params}_reg2FS{mp2rage_params}.lta"
    params:
        subjects_dir="data/derivatives/{field_strength}/freesurfer/",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}",
        outbase="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{qMT_params}_reg2FS{mp2rage_params}"
    resources:
        mem_mb=1500
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{qMT_params}_reg2FS{mp2rage_params}.log"
    shell:
        """
        export SUBJECTS_DIR=$HOME/{params.subjects_dir}

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        bbregister --s {params.subject} --mov {input.qMT} --reg {output} --t1 --init-rr
        mv {params.outbase}.log {log}
        """


rule apply_reg_qMT_to_freesurfer_bbregister:
    input:
        reg="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{qMT_params}_reg2FS{mp2rage_params}.lta",
        target="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        qMT_maps_done="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain_denoised_n4.nii.gz"
    params:
        acqdir="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/",
        subject="sub-{subject}_ses-{session}_acq-{qMT_params}"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{qMT_params}_applyreg2FS{mp2rage_params}.done")
    resources:
        mem_mb=1500
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-{qMT_params}_applyreg2FS{mp2rage_params}.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        qMTmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        mkdir -p {params.acqdir}/reg2MP2RAGE
        for map in "${{qMTmaps[@]}}"; do
            moving="{params.acqdir}/{params.subject}_"$map".nii.gz"
            out="{params.acqdir}/reg2MP2RAGE/{params.subject}_"$map"_reg2FS{wildcards.mp2rage_params}.nii.gz"
            if [ -f $moving ]; then
                mri_vol2vol --mov $moving --targ {input.target} --o $out --reg {input.reg} --no-save-reg
            fi
        done
        touch {output}
        """


rule gather_qMT_to_freesurfer_bbregister:
    input:
        qMT_to_freesurfer
    output:
        temp("data/derivatives/{field_strength}/qMT/qMT_to_freesurfer.done")
    log:
        "logs/{field_strength}/qMT/qMT_to_freesurfer.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule apply_aparc_aseg_to_qMT_bbregister:
    input:
        seg = aparc_aseg_first_acq_freesurfer,
        reg = qMT_reg2first_acq_freesurfer,
        ref="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain_denoised_n4.nii.gz"
    params:
        refprefix="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_aparc+aseg.nii.gz"
    resources:
        mem_mb=500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    threads: 1
    log:
       "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_aparc+aseg.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        #apply inverse reg so that seg is in ihmt space, to avoid interpolation of ihmt
        mri_vol2vol \
        --inv --nearest --no-save-reg \
        --mov {input.ref} --targ {input.seg} --reg {input.reg} \
        --o {output}
        """


rule warp_qMT_to_mni152:
    input:
        qMT2fs=qMT_reg2first_acq_freesurfer,
        fs2mni152=fs2mni152_first_acq
    output:
        qMT2mni152="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_reg2mni152_warp.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_reg2mni152_warp.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_warp_convert \
        --lta1 {input.qMT2fs} \
        --inm3z {input.fs2mni152} \
        --outm3z {output.qMT2mni152}
        """


rule apply_warp_mni_atlases_to_qMT:
    input:
        subj2mni152="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_reg2mni152_warp.nii.gz",
        aparc_aseg="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_aparc+aseg.nii.gz",
        wm90percent_lobes="data/atlases/mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/atlases/mni_icbm152_wm_lobes.nii.gz"
    output:
        wm_mask="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_wm_mask.nii.gz",
        wm90percent_lobes="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_mni_icbm152_wm_lobes.nii.gz",
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_apply_warp_mni_atlases_to_ihmt.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_binarize --i {input.aparc_aseg} --o {output.wm_mask} --match 2 7 41 46

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm90percent_lobes} {output.wm90percent_lobes}
        masked_wm90percent_lobes="{output.wm90percent_lobes}.masked.nii.gz"
        mri_mask {output.wm90percent_lobes} {output.wm_mask} "$masked_wm90percent_lobes"
        mv "$masked_wm90percent_lobes" {output.wm90percent_lobes}

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm_lobes} {output.wm_lobes}
        masked_wm_lobes="{output.wm_lobes}.masked.nii.gz"
        mri_mask {output.wm_lobes} {output.wm_mask} "$masked_wm_lobes"
        mv "$masked_wm_lobes" {output.wm_lobes}
        """


rule qMT_roi_stats:
    input:
        mpfmap="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_MPFmap.nii.gz",
        t1map="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_T1map.nii.gz",
        r1map="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map.nii.gz",
        mtr="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_MTRmap.nii.gz",
        seg="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_{segmentation}.nii.gz",
        lut="data/atlases/{segmentation}_lut.txt",
    params:
        qMTprefix="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}",
        outdir="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/stats_temp",
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/stats_temp/sub-{subject}_ses-{session}_acq-{qMT_params}_seg-{segmentation}_stats.done"),
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_seg-{segmentation}_stats.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        qMTmaps=("MPFmap" "MTRmap" "R1map" "T1map")
        for map in "${{qMTmaps[@]}}"; do
            qMT="{params.qMTprefix}_${{map}}.nii.gz"
            if [ -f $qMT ]; then
                echo "${{map}} stats unfiltered"
                python3 workflow/scripts/roi_stats.py "${{qMT}}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.field_strength}" "qMT" "{wildcards.subject}" "{wildcards.session}" "{wildcards.qMT_params}" "${{map}}"
                echo "${{map}}" stats without outliers
                python3 workflow/scripts/roi_stats.py -r "${{qMT}}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.field_strength}" "qMT" "{wildcards.subject}" "{wildcards.session}" "{wildcards.qMT_params}" "${{map}}"
            fi
        done

        touch {output}

        """


rule qMT_roi_stats_agg_segs:
    input:
        stats=lambda wildcards: expand(
            "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/"
            "acq-{qMT_params}/stats_temp/sub-{subject}_ses-{session}_"
            "acq-{qMT_params}_seg-{segmentation}_stats.done",
            field_strength=wildcards.field_strength,
            subject=wildcards.subject,
            session=wildcards.session,
            qMT_params=wildcards.qMT_params,
            segmentation=config["segmentations"].split(),
        ),
    params:
        stats_temp="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/stats_temp/",
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_stats.pickle",
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_stats.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        stats_list = sorted(Path(input.stats[0]).parent.glob("*_stats.pickle"))
        df_stats = pd.concat((pd.read_pickle(s) for s in stats_list), ignore_index=True)
        df_stats.to_pickle(str(output))
        if os.path.exists(params.stats_temp):
            shutil.rmtree(params.stats_temp)


rule qMT_roi_stats_agg_subjs:
    input:
        qMT_statslist
    output:
        "data/derivatives/{field_strength}/qMT/qMT_stats_{field_strength}.pickle"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/qMT/qMT_stats_{field_strength}.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        if input:
            df_stats = pd.concat((pd.read_pickle(i) for i in input), ignore_index=True)
        else:
            df_stats = pd.DataFrame()
        df_stats.to_pickle(str(output))


rule aggregate_qMT_stats:
    input:
        expand("data/derivatives/{field_strength}/qMT/qMT_stats_{field_strength}.pickle", field_strength=field_strength_list),
    output:
        "data/derivatives/qMT_stats.pickle"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/qMT_stats.log"
    run:
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        if input:
            df_stats = pd.concat((pd.read_pickle(i) for i in input), ignore_index=True)
        else:
            df_stats = pd.DataFrame()
        df_stats.to_pickle(str(output))


rule aggregate_multimodal_qMT_mp2rage:
    input:
        "data/derivatives/qMT_stats.pickle",
        expand("data/derivatives/{field_strength}/qMT/qMT_to_freesurfer.done", field_strength=field_strength_list)


rule register_dwi_to_freesurfer_bbregister:
    input:
        meanb0="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brain.nii.gz",
        orig_mgz="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz"
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2FS{mp2rage_params}.lta"
    params:
        subjects_dir="data/derivatives/{field_strength}/freesurfer/",
        subject="sub-{subject}_ses-{session}_acq-{mp2rage_params}",
        outbase="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2FS{mp2rage_params}"
    resources:
        mem_mb=1500
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2FS{mp2rage_params}.log"
    shell:
        """
        export SUBJECTS_DIR=$HOME/{params.subjects_dir}

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        bbregister --s {params.subject} --mov {input.meanb0} --reg {output} --dti --init-rr
        mv {params.outbase}.log {log}
        """


rule apply_reg_dwi_to_freesurfer_bbregister:
    input:
        reg="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2FS{mp2rage_params}.lta",
        target="data/derivatives/{field_strength}/freesurfer/sub-{subject}_ses-{session}_acq-{mp2rage_params}/mri/orig.mgz",
        dki_done="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/",
    params:
        acqdir="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/",
        subject="sub-{subject}_ses-{session}_acq-DWI{dwi_params}"
    output:
        temp("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_applyreg2FS{mp2rage_params}.done")
    resources:
        mem_mb=1500
    threads: 1
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_applyreg2FS{mp2rage_params}.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        dkimaps=("ad" "ak" "color_fa" "fa" "kfa" "md" "mk" "mkt" "rd" "rk" "rtk")
        mkdir -p "{params.acqdir}/reg2MP2RAGE/dki"
        for map in "${{dkimaps[@]}}"; do
            moving="{params.acqdir}/dki/{params.subject}_"$map".nii.gz"
            out="{params.acqdir}/reg2MP2RAGE/dki/{params.subject}_"$map"_reg2FS{wildcards.mp2rage_params}.nii.gz"
            if [ -f $moving ]; then
                mri_vol2vol --mov $moving --targ {input.target} --o $out --reg {input.reg} --no-save-reg
            fi
        done
        touch {output}
        """


rule gather_dwi_to_freesurfer_bbregister:
    input:
        dwi_to_freesurfer
    output:
        temp("data/derivatives/{field_strength}/dwi/dwi_to_freesurfer.done")
    log:
        "logs/{field_strength}/dwi/dwi_to_freesurfer.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule apply_aparc_aseg_to_dwi_bbregister:
    input:
        seg = aparc_aseg_first_acq_freesurfer,
        reg = dwi_reg2first_acq_freesurfer,
        meanb0="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brain.nii.gz",
    params:
        refprefix="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}"
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/masks_segs/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_aparc+aseg.nii.gz"
    resources:
        mem_mb=500
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    threads: 1
    log:
       "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_aparc+aseg.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export FS_LICENSE=$HOME/.snakemake/scripts/.license

        #apply inverse reg so that seg is in dwi space, to avoid interpolation of dwi
        mri_vol2vol \
        --inv --nearest --no-save-reg \
        --mov {input.meanb0} --targ {input.seg} --reg {input.reg} \
        --o {output}
        """


rule warp_dwi_to_mni152:
    input:
        dwi2fs=dwi_reg2first_acq_freesurfer,
        fs2mni152=fs2mni152_first_acq
    output:
        dwi2mni152="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/masks_segs/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2mni152_warp.nii.gz"
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2mni152_warp.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_warp_convert \
        --lta1 {input.dwi2fs} \
        --inm3z {input.fs2mni152} \
        --outm3z {output.dwi2mni152}
        """


rule apply_warp_mni_atlases_to_dwi:
    input:
        subj2mni152="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/masks_segs/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_reg2mni152_warp.nii.gz",
        aparc_aseg="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/masks_segs/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_aparc+aseg.nii.gz",
        wm90percent_lobes="data/atlases/mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/atlases/mni_icbm152_wm_lobes.nii.gz"
    output:
        wm_mask="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/masks_segs/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_wm_mask.nii.gz",
        wm90percent_lobes="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/masks_segs/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_mni_icbm152_nlin_asym_09c_wm90percent_lobes.nii.gz",
        wm_lobes="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/masks_segs/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_mni_icbm152_wm_lobes.nii.gz",
    container:
        "docker://freesurfer/freesurfer:8.1.0"
    resources:
        mem_mb=700
    threads: 1
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_apply_warp_mni_atlases_to_dwi.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FS_LICENSE=".snakemake/scripts/.license"

        mri_binarize --i {input.aparc_aseg} --o {output.wm_mask} --match 2 7 41 46

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm90percent_lobes} {output.wm90percent_lobes}
        masked_wm90percent_lobes="{output.wm90percent_lobes}.masked.nii.gz"
        mri_mask {output.wm90percent_lobes} {output.wm_mask} "$masked_wm90percent_lobes"
        mv "$masked_wm90percent_lobes" {output.wm90percent_lobes}

        mri_convert --resample_type nearest --apply_inverse_transform {input.subj2mni152} {input.wm_lobes} {output.wm_lobes}
        masked_wm_lobes="{output.wm_lobes}.masked.nii.gz"
        mri_mask {output.wm_lobes} {output.wm_mask} "$masked_wm_lobes"
        mv "$masked_wm_lobes" {output.wm_lobes}
        """


rule dwi_roi_stats:
    input:
        dki_done="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/",
        seg="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/masks_segs/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_{segmentation}.nii.gz",
        lut="data/atlases/{segmentation}_lut.txt",
    params:
        dwiprefix="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/sub-{subject}_ses-{session}_acq-DWI{dwi_params}",
        outdir="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/stats_temp",
    output:
        temp("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/stats_temp/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_{segmentation}_stats.done"),
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_seg-{segmentation}_stats.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        dkimaps=("ad" "ak" "color_fa" "fa" "kfa" "md" "mk" "mkt" "rd" "rk" "rtk")
        for map in "${{dkimaps[@]}}"; do
            dki="{params.dwiprefix}_${{map}}.nii.gz"
            if [ -f $dki ]; then
                python3 workflow/scripts/roi_stats.py "${{dki}}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.field_strength}" "DWI" "{wildcards.subject}" "{wildcards.session}" "DWI{wildcards.dwi_params}" "${{map}}"
                python3 workflow/scripts/roi_stats.py -r "${{dki}}" "{input.seg}" "{input.lut}" "{params.outdir}" "{wildcards.field_strength}" "DWI" "{wildcards.subject}" "{wildcards.session}" "DWI{wildcards.dwi_params}" "${{map}}"
            fi
        done

        touch {output}

        """


rule dwi_roi_stats_agg_segs:
    input:
        stats=expand("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/stats_temp/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_{segmentation}_stats.done",
        segmentation=config["segmentations"].split(), allow_missing=True),
    params:
        stats_temp="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/stats_temp",
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_stats.pickle",
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_stats.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        stats_list = sorted(Path(input.stats[0]).parent.glob("*_stats.pickle"))
        df_stats = pd.concat((pd.read_pickle(s) for s in stats_list), ignore_index=True)
        df_stats.to_pickle(str(output))
        shutil.rmtree(params.stats_temp)


rule dwi_roi_stats_agg_subjs:
    input:
        dwi_statslist
    output:
        "data/derivatives/{field_strength}/dwi/dwi_stats_{field_strength}.pickle"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/dwi/dwi_stats_{field_strength}.log"
    run: #python code, not shell
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        if input:
            df_stats = pd.concat((pd.read_pickle(i) for i in input), ignore_index=True)
        else:
            df_stats = pd.DataFrame()
        df_stats.to_pickle(str(output))


rule aggregate_dwi_stats:
    input:
        expand("data/derivatives/{field_strength}/dwi/dwi_stats_{field_strength}.pickle", field_strength=field_strength_list),
    output:
        "data/derivatives/dwi_stats.pickle"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/dwi_stats.log"
    run:
        logging.basicConfig(level=logging.INFO, filename=log[0], filemode="w")
        if input:
            df_stats = pd.concat((pd.read_pickle(i) for i in input), ignore_index=True)
        else:
            df_stats = pd.DataFrame()
        df_stats.to_pickle(str(output))


rule aggregate_multimodal_dwi_mp2rage:
    input:
        "data/derivatives/dwi_stats.pickle",
        expand("data/derivatives/{field_strength}/dwi/dwi_to_freesurfer.done", field_strength=field_strength_list)
