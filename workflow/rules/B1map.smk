#necessary for MP2RAGE.smk and qMT.smk processing
#requires BIDS data at data/rawdata/bids/{field_strength}
import json
import logging
import glob
import shutil


def get_last_b1anat_run(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/fmap/sub-{wildcards.subject}_ses-{wildcards.session}_acq-anat*_TB1*.nii.gz'))[-1]

def get_last_b1map_run(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/fmap/sub-{wildcards.subject}_ses-{wildcards.session}_acq-famp*_TB1*.nii.gz'))[-1]

def get_target_flip(wildcards):
    json_path = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/fmap/sub-{wildcards.subject}_ses-{wildcards.session}_acq-famp*_TB1*.json'))[-1] #select last run
    with open(json_path, "r") as f:
        b1map_meta = json.load(f)
    try: #set default to 900 for now
        target_fa = b1map_meta["target_fa_deg"] * 10
    except:
        target_fa = 900
    return target_fa

def get_b1anat2mp2rage_reg(wildcards):
    #get b1anat2mp2rage registration if b1anat exists, otherwise return a blank string (applyAntsTransforms will then reslice instead of register)
    try:
        b1anat = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/fmap/sub-{wildcards.subject}_ses-{wildcards.session}_acq-anat*_TB1*.nii.gz'))[-1]
        b1anat2mp2rage_reg = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_b1_reg2{mp2rage_params}_0GenericAffine.mat"
    except:
       b1anat2mp2rage_reg = []
    return b1anat2mp2rage_reg

def get_b1anat2qMT_reg(wildcards):
    #get b1anat2qMT registration if b1anat exists, otherwise return a blank string (applyAntsTransforms will then reslice instead of register)
    try:
        b1anat = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/fmap/sub-{wildcards.subject}_ses-{wildcards.session}_acq-anat*_TB1*.nii.gz'))[-1]
        b1anat2qMT_reg = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_b1_reg2{seq}t1w{qMT_params}_0GenericAffine.mat"
    except:
       b1anat2qMT_reg = []
    return b1anat2qMT_reg

def get_b1anat2ihmt_reg(wildcards):
    #get b1anat2ihmt registration if b1anat exists, otherwise return a blank string (applyAntsTransforms will then reslice instead of register)
    try:
        b1anat = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/fmap/sub-{wildcards.subject}_ses-{wildcards.session}_acq-anat*_TB1*.nii.gz'))[-1]
        b1anat2ihmt_reg = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_b1_reg2{ihmt_params}_0GenericAffine.mat"
    except:
       b1anat2ihmt_reg = []
    return b1anat2ihmt_reg

#rules for registering with ANTs

rule synthstrip_b1anat:
    input:
        get_last_b1anat_run
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=9000
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} -g --no-csf || mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_b1anat:
    input:
        brain_mask = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz",
        b1anat = get_last_b1anat_run
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    threads: 1
    resources: 
        mem_mb=500
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.b1anat} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_b1anat:
    input:
        input_image = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised.log"
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


rule N4BiasFieldCorrection_b1anat:
    input:
        input_image = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4.nii.gz"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
       "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4.log"
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


rule register_b1anat_to_mp2rage:
    input:
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/preproc/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_b1_reg2{mp2rage_params}_0GenericAffine.mat"
    params:
        outprefix="data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_b1_reg2{mp2rage_params}_"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=700
    threads: 4
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_b1_reg2{mp2rage_params}.log"
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


rule apply_reg_b1_to_mp2rage:
    input:
        moving = get_last_b1map_run,
        ref = "data/derivatives/{field_strength}/MP2RAGE/sub-{subject}/ses-{session}/acq-{mp2rage_params}/sub-{subject}_ses-{session}_acq-{mp2rage_params}_T1map.nii.gz",
        reg = get_b1anat2mp2rage_reg
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        if [ {input.reg} ]; then
            antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i {input.moving} \
            -r {input.ref} \
            -t {input.reg} \
            -o {output}
        else
           antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i {input.moving} \
            -r {input.ref} \
            -o {output} 
        fi
        """


rule register_b1anat_to_qMT_t1w_ants: 
    input:
        ref = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4.nii.gz",
        ref_mask ="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_b1_reg2{seq}t1w{qMT_params}_0GenericAffine.mat"
    params:
        outprefix="data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_b1_reg2{seq}t1w{qMT_params}_"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    threads: 4
    log:
       "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_b1_reg2{seq}t1w{qMT_params}.log" 
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


rule apply_reg_b1map_to_qMT_t1w_ants:
    input:
        moving = get_last_b1map_run,
        ref = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos.nii.gz",
        reg = get_b1anat2qMT_reg
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{seq}t1w{qMT_params}_ants.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
       "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{seq}t1w{qMT_params}_ants.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        if [ {input.reg} ]; then
            antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i {input.moving} \
            -r {input.ref} \
            -t {input.reg} \
            -o {output}
        else
           antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i {input.moving} \
            -r {input.ref} \
            -o {output} 
        fi
        """


rule register_b1anat_to_ihmt:
    input:
        ref = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-anat_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_b1_reg2{ihmt_params}_0GenericAffine.mat"
    params:
        outprefix="data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_b1_reg2{ihmt_params}_"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=700
    threads: 4
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_b1_reg2{ihmt_params}.log"
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


rule apply_reg_b1_to_ihmt:
    input:
        moving = get_last_b1map_run,
        ref = "data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/preproc/sub-{subject}_ses-{session}_acq-{ihmt_params}_MTmap.nii.gz",
        reg = get_b1anat2ihmt_reg
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_acq-famp_reg2{ihmt_params}_ants.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_acq-famp_reg2{ihmt_params}_ants.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        if [ {input.reg} ]; then
            antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i {input.moving} \
            -r {input.ref} \
            -t {input.reg} \
            -o {output}
        else
           antsApplyTransforms \
            --dimensionality 3 \
            --interpolation Linear \
            --verbose 1 \
            -i {input.moving} \
            -r {input.ref} \
            -o {output} 
        fi
        """


#Post registration rules

rule copy_b1map_json_after_regtoMP2RAGE:
    input:
        b1map_raw = get_last_b1map_run,
        b1map_reg2MP2RAGE = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_acq-famp_reg2{mp2rage_params}_ants.json")
    resources: 
        mem_mb=300
    threads: 1
    log:
       out="logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2MP2RAGE/sub-{subject}_ses-{session}_copy_b1map_json_after_reg2{mp2rage_params}.log" 
    run:
        logging.basicConfig(level=logging.INFO, filename=log.out, filemode="w")
        
        b1map_raw_json = Path(input.b1map_raw).with_suffix("").with_suffix(".json")
        b1map_reg2MP2RAGE_json = Path(input.b1map_reg2MP2RAGE).with_suffix("").with_suffix(".json")
        shutil.copy(b1map_raw_json, b1map_reg2MP2RAGE_json)


rule smooth_B1_qMT:
    input:
       "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{seq}t1w{qMT_params}_ants.nii.gz" 
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{seq}t1w{qMT_params}_smooth.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{seq}t1w{qMT_params}_smooth.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}
        
        SmoothImage 3 {input[0]} 3x1x1 {output}
        """


rule normalize_B1_to_target_flip_qMT: #not masking because we are interested in the spinal cord
    input:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{seq}t1w{qMT_params}_smooth.nii.gz"
    params:
        target_flip = get_target_flip
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{seq}t1w{qMT_params}_smooth_norm.nii.gz"
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{seq}t1w{qMT_params}_smooth_norm.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input} -div {params.target_flip} {output} -odt float 
        """

rule smooth_B1_ihmt:
    input:
       "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_acq-famp_reg2{ihmt_params}_ants.nii.gz" 
    output:
        temp("data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_acq-famp_reg2{ihmt_params}_smooth.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_acq-famp_reg2{ihmt_params}_smooth.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}
        
        SmoothImage 3 {input[0]} 3x1x1 {output}
        """


rule normalize_B1_to_target_flip_ihmt:
    input:
        img="data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_acq-famp_reg2{ihmt_params}_smooth.nii.gz",
        mask="data/derivatives/{field_strength}/ihmt/sub-{subject}/ses-{session}/acq-{ihmt_params}/sub-{subject}_ses-{session}_acq-{ihmt_params}_ihmt_brain_mask.nii.gz"
    params:
        target_flip = get_target_flip
    output:
        "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_acq-famp_reg2{ihmt_params}_smooth_norm.nii.gz"
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2IHMT/sub-{subject}_ses-{session}_acq-famp_reg2{ihmt_params}_smooth_norm.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.img} -mul {input.mask} -div {params.target_flip} {output} -odt float 
        """