import glob
import os
from pathlib import Path

bidspath = Path("data/rawdata/bids")
try:
    field_strength_list=next(os.walk(bidspath))[1]
except:
    field_strength_list=[]

def get_dwi_PA_mag_nii(wildcards):
    #try filename with part-mag first, then use more generic name
    try:
        dwi_PA_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_part-mag_*dwi.nii.gz'))[0]
        dwi_PA_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_part-mag_*dwi.nii.gz'))
    except:
        dwi_PA_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_*dwi.nii.gz'))[0]    
        dwi_PA_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_*dwi.nii.gz'))
    return dwi_PA_mag

def get_dwi_PA_phase_nii(wildcards):
    dwi_PA_phase = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-PA_part-phase_*dwi.nii.gz'))
    return dwi_PA_phase

def get_dwi_PA_phase_mif(wildcards):
    dwi_PA_phase = sorted(glob.glob(f'data/derivatives/{wildcards.field_strength}/dwi/sub-{wildcards.subject}/ses-{wildcards.session}/acq-DWI{wildcards.dwi_params}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-DWI{wildcards.dwi_params}_dir-PA_part-phase_dwi.mif'))
    return dwi_PA_phase

def get_dwi_AP_mag_nii(wildcards):
    #try filename with part-mag first, then use more generic name
    try:
        dwi_AP_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-AP_part-mag_*dwi.nii.gz'))[0]
        dwi_AP_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-AP_part-mag_*dwi.nii.gz'))
    except:
        dwi_AP_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-AP_*dwi.nii.gz'))[0]    
        dwi_AP_mag = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-AP_*dwi.nii.gz'))
    return dwi_AP_mag

def get_dwi_AP_phase_nii(wildcards):
    dwi_AP_phase = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/dwi/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.dwi_params}*_dir-AP_part-phase_*dwi.nii.gz'))
    return dwi_AP_phase

def get_dwi_AP_phase_mif(wildcards):
    dwi_AP_phase = sorted(glob.glob(f'data/derivatives/{wildcards.field_strength}/dwi/sub-{wildcards.subject}/ses-{wildcards.session}/acq-DWI{wildcards.dwi_params}/sub-{wildcards.subject}_ses-{wildcards.session}_acq-DWI{wildcards.dwi_params}_dir-AP_part-phase_dwi.mif'))
    return dwi_AP_phase

def aggregate_dki(wildcards):
    layout=layout_dict[wildcards.field_strength]
    dki_list = []
    subjectlist = layout.get_subject(suffix="dwi")
    for subject in subjectlist:
        sessionlist = layout.get_session(suffix="dwi", subject=subject)
        for session in sessionlist:
            dwi_acqlist = layout.get_acquisition(suffix="dwi", subject=subject, session=session)
            for dwi in dwi_acqlist:
                # dwi = dwi.replace("dwi", "").replace("18iso", "").replace("2shb2ktra", "").replace("PA", "").replace("b0tra", "").replace("AP", "").replace("3shb3ktra", "").replace("pha", "")
                dki_list.append("data/derivatives/{field_strength}/dwi/sub-" + subject + "/ses-" + session + "/acq-DWI" + dwi + "/dki/")
    return dki_list


rule concat_dwi_runs:
    input:
        dwi_PA_mag=get_dwi_PA_mag_nii,
        dwi_AP_mag=get_dwi_AP_mag_nii,
        dwi_PA_phase=get_dwi_PA_phase_nii,
        dwi_AP_phase=get_dwi_AP_phase_nii
    output:
        dwi_PA_mag="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-PA_part-mag_dwi.mif",
        dwi_AP_mag="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-AP_part-mag_dwi.mif",
    params:
        dwi_PA_phase="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-PA_part-phase_dwi.mif",
        dwi_AP_phase="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-AP_part-phase_dwi.mif",
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    resources: 
        mem_mb=2000
    threads: 1
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/preproc/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_concatenate.log",
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export input_dwi_PA_mag=({input.dwi_PA_mag})
        dwi_PA_mag_tmp=()
        if [ ${{#input_dwi_PA_mag[@]}} -gt 1 ]; then
            for img in "${{input_dwi_PA_mag[@]}}"; do
                mrconvert -json_import "${{img%.nii.gz}}.json" -fslgrad "${{img%.nii.gz}}.bvec" "${{img%.nii.gz}}.bval" -force $img "${{img%.nii.gz}}.mif"
                dwi_PA_mag_tmp+=("${{img%.nii.gz}}.mif")
            done
            mrcat ${{dwi_PA_mag_tmp[@]}} {output.dwi_PA_mag} -force
            for img in "${{dwi_PA_mag_tmp[@]}}"; do
                rm $img
            done
        else
            mrconvert -json_import "${{input_dwi_PA_mag%.nii.gz}}.json" -fslgrad "${{input_dwi_PA_mag%.nii.gz}}.bvec" "${{input_dwi_PA_mag%.nii.gz}}.bval" -force {input.dwi_PA_mag} {output.dwi_PA_mag}
        fi
        
        export input_dwi_AP_mag=({input.dwi_AP_mag})
        dwi_AP_mag_tmp=()
        if [ ${{#input_dwi_AP_mag[@]}} -gt 1 ]; then
            for img in "${{input_dwi_AP_mag[@]}}"; do
                mrconvert -json_import "${{img%.nii.gz}}.json" -fslgrad "${{img%.nii.gz}}.bvec" "${{img%.nii.gz}}.bval" -force $img "${{img%.nii.gz}}.mif"
                dwi_AP_mag_tmp+=("${{img%.nii.gz}}.mif")
            done
            mrcat ${{dwi_AP_mag_tmp[@]}} {output.dwi_AP_mag} -force
            for img in "${{dwi_AP_mag_tmp[@]}}"; do
                rm $img
            done
        else
            mrconvert -json_import "${{input_dwi_AP_mag%.nii.gz}}.json" -fslgrad "${{input_dwi_AP_mag%.nii.gz}}.bvec" "${{input_dwi_AP_mag%.nii.gz}}.bval" -force {input.dwi_AP_mag} {output.dwi_AP_mag}
        fi
 
        export input_dwi_PA_phase=({input.dwi_PA_phase})
        dwi_PA_phase_tmp=()
        if [ ${{#input_dwi_PA_phase[@]}} -gt 0 ]; then
            if [ ${{#input_dwi_PA_phase[@]}} -gt 1 ]; then
                for img in "${{input_dwi_PA_phase[@]}}"; do
                    mrconvert -json_import "${{img%.nii.gz}}.json" -fslgrad "${{img%.nii.gz}}.bvec" "${{img%.nii.gz}}.bval" -force $img "${{img%.nii.gz}}.mif"
                    dwi_PA_phase_tmp+=("${{img%.nii.gz}}.mif")
                done
                mrcat ${{dwi_PA_phase_tmp[@]}} {params.dwi_PA_phase} -force
                for img in "${{dwi_PA_phase_tmp[@]}}"; do
                    rm $img
                done
            else
                mrconvert -json_import "${{input_dwi_PA_phase%.nii.gz}}.json" -fslgrad "${{input_dwi_PA_phase%.nii.gz}}.bvec" "${{input_dwi_PA_phase%.nii.gz}}.bval" -force {input.dwi_PA_phase} {params.dwi_PA_phase}
            fi
        fi

        export input_dwi_AP_phase=({input.dwi_AP_phase})
        dwi_AP_phase_tmp=()
        if [ ${{#input_dwi_AP_phase[@]}} -gt 0 ]; then
            if [ ${{#input_dwi_AP_phase[@]}} -gt 1 ]; then
                for img in "${{input_dwi_AP_phase[@]}}"; do
                    mrconvert -json_import "${{img%.nii.gz}}.json" -fslgrad "${{img%.nii.gz}}.bvec" "${{img%.nii.gz}}.bval" -force $img "${{img%.nii.gz}}.mif"
                    dwi_AP_phase_tmp+=("${{img%.nii.gz}}.mif")
                done
                mrcat ${{dwi_AP_phase_tmp[@]}} {params.dwi_AP_phase} -force
                for img in "${{dwi_AP_phase_tmp[@]}}"; do
                    rm $img
                done
            else
                mrconvert -json_import "${{input_dwi_AP_phase%.nii.gz}}.json" -fslgrad "${{input_dwi_AP_phase%.nii.gz}}.bvec" "${{input_dwi_AP_phase%.nii.gz}}.bval" -force {input.dwi_AP_phase} {params.dwi_AP_phase}
            fi
        fi       
        """


rule nyu_designer:
    input:
        dwi_PA_mag="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-PA_part-mag_dwi.mif",
        dwi_AP_mag="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_dir-AP_part-mag_dwi.mif",
        dwi_PA_phase=get_dwi_PA_phase_mif,
        dwi_AP_phase=get_dwi_AP_phase_mif
    params:
        preproc="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/preproc/"
    output:
        mif="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.mif",
        noisemap="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_noisemap.nii"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    threads:
        8
    resources:
        mem_mb=11000
    log:
       "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        rm -rf {params.preproc}
        if command -v eddy_cuda >/dev/null 2>&1; then
            export PATH="$(dirname "$(command -v eddy_cuda)"):$PATH"
        fi
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi

        echo "BZeroThreshold: 15.0" > $HOME/.mrtrix.conf

        export shells_PA="$(mrinfo -shell_bvalues {input.dwi_PA_mag})"
        shells_PA_arr=($shells_PA)
        export shells_AP="$(mrinfo -shell_bvalues {input.dwi_AP_mag})"
        shells_AP_arr=($shells_AP)

        if [ ${{#shells_PA_arr[@]}} -gt 1 ]; then
            export dwi="{input.dwi_PA_mag}"
            export phase="{input.dwi_PA_phase}"
            export rpe="{input.dwi_AP_mag}"
        elif [ ${{#shells_AP_arr[@]}} -gt 1 ]; then
            export dwi="{input.dwi_AP_mag}"
            export phase="{input.dwi_AP_phase}"
            export rpe="{input.dwi_PA_mag}"
        fi

        if [ ${{#shells_PA_arr[@]}} -eq ${{#shells_AP_arr[@]}} ]; then
            export rpe_flag=rpe_all
        else
            export rpe_flag=rpe_pair
        fi

        if [ "$phase" ]; then
            designer "$dwi" "{output.mif}" \
            -denoise -shrinkage frob -adaptive_patch -phase $HOME/$phase \
            -degibbs \
            -eddy -${{rpe_flag}} $HOME/$rpe -eddy_quad_off \
            -normalize \
            -scratch {params.preproc} -nocleanup \
            -n_cores {threads} -nthreads {threads}
        else
            designer "$dwi" "{output.mif}" \
            -denoise -shrinkage frob -adaptive_patch -rician \
            -degibbs \
            -eddy -${{rpe_flag}} $HOME/$rpe -eddy_quad_off \
            -normalize \
            -scratch {params.preproc} -nocleanup \
            -n_cores {threads} -nthreads {threads}
        fi
        
        cp {params.preproc}/sigma.nii {output.noisemap}
        rm -rf {params.preproc}
        """


rule convert_designer_mif_to_nii:
    input:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.mif"
    output:
        nii="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.nii.gz",
        json="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.json",
        bvec="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.bvec",
        bval="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.bval"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_convert_designer_mif_to_nii.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrconvert -force -stride -1,2,3,4 -json_export {output.json} -export_grad_fsl {output.bvec} {output.bval} {input} {output.nii}
        """


rule mean_b0:
    input:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.mif"
    output:
        b0=temp("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_b0.mif"),
        meanb0="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0.nii.gz"
    container:
        "docker://nyudiffusionmri/designer2:v2.0.15"
    resources: 
        mem_mb=500
    threads: 1
    log:
       "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0.log" 
    shell:
        """
        dwiextract -bzero {input} {output.b0}
        mrmath {output.b0} mean {output.meanb0} -axis 3
        """


rule b0_mask:
    input:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0.nii.gz"
    output:
        "data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brainmask.nii"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=8000
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brainmask.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} --no-csf -g || mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_meanb0:
    input:
        img="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0.nii.gz",
        mask="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brainmask.nii"
    output:
        temp("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brain.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.img} -mas {input.mask} {output}
        """


rule dki_tensor_dipy:
    input:
        img="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer.nii.gz",
        mask="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_meanb0_brainmask.nii"
    params:
        outprefix="data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_"
    output:
        directory("data/derivatives/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/dki/")
    conda:
        "../envs/dipy.yaml"
    resources:
        mem_mb=11000
    threads: 1
    log:
        "logs/{field_strength}/dwi/sub-{subject}/ses-{session}/acq-DWI{dwi_params}/sub-{subject}_ses-{session}_acq-DWI{dwi_params}_designer_dki.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mkdir -p {output}
        python workflow/scripts/dki_tensor_dipy.py {input.img} {input.mask} {params.outprefix}
        """


rule aggregate_dki_by_field_strength:
    input:
        aggregate_dki
    output:
        "data/derivatives/{field_strength}/dwi/dki.done"
    log:
        "logs/{field_strength}/dwi/dki.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """


rule aggregate_dki:
    input:
        expand("data/derivatives/{field_strength}/dwi/dki.done", field_strength=field_strength_list)
