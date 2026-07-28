#requires BIDS data at data/rawdata/bids/{field_strength}
#requires B1map.smk
import json
import glob
from collections import Counter

wildcard_constraints:
    contrast = '|'.join([re.escape(x) for x in config["qmt_contrasts"].split()]),
    seq = config["qmt_sequence"],
    part = 'mag|phase'

bidspath = Path("data/rawdata/bids")

def get_echos(wildcards):
    #get the list of echo files and sort it
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}{wildcards.contrast}*{wildcards.qMT_params}*_echo-*_flip-*_mt-{wildcards.mt}_part-{wildcards.part}_MPM.nii.gz'))

def get_qMT_params(wildcards):
    json_path = sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}mtw*{wildcards.qMT_params}_echo-1_flip-*_mt-on_part-mag_MPM.json'))[0]
    with open(json_path, "r") as f:
        mtw_meta = json.load(f)
        mt_params = {
            'mtflip' : mtw_meta["FlipAngle"],
            'sat_pulse_ms' : mtw_meta['sat_pulse_ms'],
            'interdelay_ms' : mtw_meta['interdelay_ms'],
            'ro_pulse_ms' : mtw_meta['ro_pulse_ms'],
            'tr_ms' : mtw_meta['tr_ms'],
            'ro_fa_deg' : mtw_meta['ro_fa_deg'],
            'ro_pulse_shape' : mtw_meta['ro_pulse_shape'],
            'sat_pulse_fa_deg' : mtw_meta['sat_pulse_fa_deg'],
            'sat_pulse_offset_hz' : mtw_meta['sat_pulse_offset_hz'],
            'sat_pulse_shape' : mtw_meta['sat_pulse_shape']
        }
    return mt_params

def get_qMT_json(wildcards):
    return sorted(glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}mtw*{wildcards.qMT_params}_echo-1_flip-*_mt-on_part-mag_MPM.json'))[0]

def get_t1flip(wildcards):
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}t1w*{wildcards.qMT_params}_echo-1_flip-*_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        t1w_meta = json.load(f)
    return t1w_meta["FlipAngle"]

def get_pdflip(wildcards):
    json_path = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}pdw*{wildcards.qMT_params}_echo-1_flip-*_mt-off_part-mag_MPM.json')[0]
    with open(json_path, "r") as f:
        pdw_meta = json.load(f)
    return pdw_meta["FlipAngle"]

def t1wmag_preproc(wildcards):
    #get preprocessed magnitude image depending on if phase is available
    try:
        raw_phase = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}t1w*{wildcards.qMT_params}_echo-1_flip-*_mt-off_part-phase_MPM.nii.gz')[0]
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_echos4d_riciancorr.nii"
    except:
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_echos4d.nii"
    return mag_preproc

def mt0mag_preproc(wildcards):
    #get preprocessed magnitude image depending on if phase is available
    try:
        raw_phase = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}mt0*{wildcards.qMT_params}*_echo-1_flip-*_mt-off_part-phase_MPM.nii.gz')[0]
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_echos4d_riciancorr.nii"
    except:
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_echos4d.nii"
    return mag_preproc

def mtwmag_preproc(wildcards):
    #get preprocessed magnitude image depending on if phase is available
    try:
        raw_phase = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}mtw*{wildcards.qMT_params}_echo-1_flip-*_mt-on_part-phase_MPM.nii.gz')[0]
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mtw{qMT_params}_mt-on_part-mag_echos4d_riciancorr.nii"
    except:
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mtw{qMT_params}_mt-on_part-mag_echos4d.nii"
    return mag_preproc

def pdwmag_preproc(wildcards):
    #get preprocessed magnitude image depending on if phase is available
    try:
        raw_phase = glob.glob(f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.seq}pdw*{wildcards.qMT_params}_echo-1_flip-*_mt-off_part-phase_MPM.nii.gz')[0]
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}pdw{qMT_params}_mt-off_part-mag_echos4d_riciancorr.nii"
    except:
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}pdw{qMT_params}_mt-off_part-mag_echos4d.nii"
    return mag_preproc

def aggregate_qMT(wildcards):
    layout=layout_dict[wildcards.field_strength]
    qMT_list = []
    T1map_list = []
    MTRmap_list = []
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list((set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_tb1tfl))
    for subject in subjectlist:
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list((set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_tb1tfl))
        for session in sessionlist:
            mpm_acqlist = layout.get_acquisition(suffix="MPM", subject=subject, session=session)
            for mpm in mpm_acqlist:
                mpm = mpm.replace("6eco", "").replace("3eco", "").replace("sag", "").replace("mag", "").replace("pha", "").replace("DL", "")
                for contrast in config["qmt_contrasts"].split():
                    mpm = mpm.replace(contrast, "")
                T1map_list.append("data/derivatives/{field_strength}/qMT/sub-" + subject + "/ses-" + session + "/preproc/sub-" + subject + "_ses-" + session + "_acq-" + mpm + "_T1map_brain_denoised_n4.nii.gz")
                MTRmap_list.append("data/derivatives/{field_strength}/qMT/sub-" + subject + "/ses-" + session + "/sub-" + subject + "_ses-" + session + "_acq-" + mpm + "_MTRmap.nii.gz")
    counts_T1map = Counter(T1map_list)
    T1map_list = [reg for reg, count in counts_T1map.items() if count > 3]
    counts_MTRmap = Counter(MTRmap_list)
    MTRmap_list = [reg for reg, count in counts_MTRmap.items() if count > 3]
    qMT_list = T1map_list + MTRmap_list
    return qMT_list


rule concat_echos:
    input:
        echos = get_echos
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_echos4d.nii")
    resources: 
        mem_mb=2000
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
      "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_echos4d.log"  
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrcat {input.echos} {output}
        """


rule create_complex_images:
    input:
        mag="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-mag_echos4d.nii",
        phase="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-phase_echos4d.nii"
    output:
        mag_clipped=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-mag_echos4d_clippedtophase.nii"),
        out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-complex_echos4d.nii")
    resources: #limit memory by input size
        mem_mb=1500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
       "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-complex_echos4d.log" 
    shell: #first clip mag so that it has the same number of volumes as phase, then calculate complex image
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        phasesize="$(mrinfo -size {input.phase} | awk '{{print $4}}')"
        magsize="$(mrinfo -size {input.mag} | awk '{{print $4}}')"
        magstart="$((${{magsize}}-${{phasesize}}))"
        mrconvert {input.mag} {output.mag_clipped} -coord 3 ${{magstart}}:end
        mrcalc {output.mag_clipped} {input.phase} pi 4096 -div -mult -polar {output.out}
        """


rule rician_bias_corr:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-complex_echos4d.nii"
    output:
        denoised=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-complex_echos4d_riciancorr.nii"),
        noisemap="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_echos4d_riciannoisemap.nii"
    resources: #limit memory by input size
        mem_mb=2500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_echos4d_riciannoisemap.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        dwidenoise {input} {output.denoised} -noise {output.noisemap}
        """


rule calculate_mag_from_complex:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-complex_echos4d_riciancorr.nii"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-mag_echos4d_riciancorr.nii")
    resources:
        mem_mb=1500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-mag_echos4d_riciancorr.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrcalc {input} -abs {output}
        """


rule calculate_phase_from_complex:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-complex_echos4d_riciancorr.nii"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-phase_echos4d_riciancorr.nii")
    resources: #limit memory by input size
        mem_mb=1500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-phase_echos4d_riciancorr.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrcalc {input} -phase {output}
        """


rule make_n_echos_equal:
    #clip images so that they all have the same number of echos as the image with the least number of echos
    input:
        t1w_in=t1wmag_preproc,
        mt0_in=mt0mag_preproc,
        mtw_in=mtwmag_preproc,
        pdw_in=pdwmag_preproc
    output:
        t1w_out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_echos4d_clipped.nii"),
        mt0_out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_echos4d_clipped.nii"),
        mtw_out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mtw{qMT_params}_mt-on_part-mag_echos4d_clipped.nii"),
        pdw_out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}pdw{qMT_params}_mt-off_part-mag_echos4d_clipped.nii")
    resources:
        mem_mb=1000
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
       "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_make_n_echos_equal.log" 
    shell: #first find smallest number of echos, then clip the other images to this number of echos
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        t1wsize="$(mrinfo -size {input.t1w_in} | awk '{{print $4}}')"
        mt0size="$(mrinfo -size {input.mt0_in} | awk '{{print $4}}')"
        mtwsize="$(mrinfo -size {input.mtw_in} | awk '{{print $4}}')"
        pdwsize="$(mrinfo -size {input.pdw_in} | awk '{{print $4}}')"

        #find smallest number of echos
        sizes_array=($t1wsize $mt0size $mtwsize $pdwsize)
        min_echos=${{sizes_array[0]}}
        for i in "${{sizes_array[@]}}"; do
            (( i < min_echos )) && min_echos=$i
        done
        #get index for clipping to smallest number of echos
        end_idx="$((${{min_echos}}-1))"

        #clip images to smallest number of echos
        mrconvert {input.t1w_in} {output.t1w_out} -coord 3 0:${{end_idx}}
        mrconvert {input.mt0_in} {output.mt0_out} -coord 3 0:${{end_idx}}
        mrconvert {input.mtw_in} {output.mtw_out} -coord 3 0:${{end_idx}}
        mrconvert {input.pdw_in} {output.pdw_out} -coord 3 0:${{end_idx}}
        """


rule concat_contrast_mag:
    input:
        t1w="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_echos4d_clipped.nii",
        mt0="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_echos4d_clipped.nii",
        mtw="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mtw{qMT_params}_mt-on_part-mag_echos4d_clipped.nii",
        pdw="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}pdw{qMT_params}_mt-off_part-mag_echos4d_clipped.nii"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_part-mag_echoscontrast5d.nii")
    resources:
        mem_mb=2000
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_part-mag_echoscontrast5d.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrcat {input.t1w} {input.mt0} {input.mtw} {input.pdw} {output} -axis 4
        """


rule denoise_contrast_mag:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_part-mag_echoscontrast5d.nii"
    output:
        out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_part-mag_echoscontrast5d_denoise.nii"),
        noisemap="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_part-mag_noisemap.nii"
    resources: #limit memory by input size
        mem_mb=3000
    threads: 8
    conda:
        "../envs/tMPPCA.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_part-mag_noisemap.log"
    shell:
        """ 
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        python -c 'import nibabel
from tmppca import tmppca_cpp
        
data = nibabel.load("{input}")
denoised, sigma, P, snr_gain = tmppca_cpp.denoise_tmppca(data.get_fdata(), window=[5, 5, 5])
nibabel.save(nibabel.Nifti1Image(denoised, data.affine), "{output.out}")
nibabel.save(nibabel.Nifti1Image(sigma, data.affine), "{output.noisemap}")'
        """


rule split_contrast_mag:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_part-mag_echoscontrast5d_denoise.nii"
    output:
        t1w=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_echos4d_denoise.nii"),
        mt0=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_echos4d_denoise.nii"),
        mtw=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mtw{qMT_params}_mt-on_part-mag_echos4d_denoise.nii"),
        pdw=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}pdw{qMT_params}_mt-off_part-mag_echos4d_denoise.nii")
    resources:
        mem_mb=2000
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_split_contrast_mag.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrconvert {input} -coord 4 0 -axes 0,1,2,3 {output.t1w}
        mrconvert {input} -coord 4 1 -axes 0,1,2,3 {output.mt0}
        mrconvert {input} -coord 4 2 -axes 0,1,2,3 {output.mtw}
        mrconvert {input} -coord 4 3 -axes 0,1,2,3 {output.pdw}
        """


rule sos:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_echos4d_denoise.nii"
    output:
       "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos.nii.gz"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        python workflow/scripts/sos_images.py {input} {output}
        """


rule synthstrip_qMT:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos.nii.gz"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources: 
        mem_mb=9000
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_mask.log"
    shell: #try GPU first, then run CPU if GPU doesn't work
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        if command -v nvidia-smi; then
            export CUDA_VISIBLE_DEVICES=0
        fi
        mri_synthstrip -i {input} -m {output} -t {threads} -g --no-csf || \
        mri_synthstrip -i {input} -m {output} -t {threads} --no-csf
        """


rule apply_brainmask_qMT:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule install_sct:
    output:
        ".snakemake/scripts/install_sct.done"
    resources: 
        mem_mb=2000
    threads: 1
    log:
        "logs/install_sct_log.txt"
    shell: #Check if sct is already installed. If not, install version 7.2 
        """
        if ! command -v sct_deepseg; then
            #install for Mac or Linux, based on which OS is installed
            if [[ $(uname) == Darwin* ]]; then
                wget https://github.com/spinalcordtoolbox/spinalcordtoolbox/releases/download/7.2/install_sct-7.2_macos.sh
            else
                wget https://github.com/spinalcordtoolbox/spinalcordtoolbox/releases/download/7.2/install_sct-7.2_linux.sh
            fi
            mv install_sct-7.2_*.sh .snakemake/scripts/

            #if GPU is available, install GPU version, otherwise install CPU version
            if command -v nvidia-smi; then
                bash .snakemake/scripts/install_sct-7.2_*.sh -yicg
            else
                bash .snakemake/scripts/install_sct-7.2_*.sh -yic
            fi

            #move log to logs folder
            mv install_sct_log.txt {log}    
        fi
        touch .snakemake/scripts/install_sct.done #mark installation as done
        """


rule spineseg_qMT:
    input:
       img="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos.nii.gz",
       install_sct_done=".snakemake/scripts/install_sct.done"
    output: #these are the same image, the temp image is deleted after the rule is finished
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_seg.nii.gz"),
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_spine_mask.nii.gz"
    threads: 4
    resources: 
        mem_mb=9000
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_spine_mask.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        #use GPU if available
        if command -v nvidia-smi; then
            export SCT_USE_GPU=1
            export CUDA_VISIBLE_DEVICES=0
        fi
        
        sct_deepseg spinalcord -i {input.img}

        #rename output for clarity, snakemake will delete output[0] when finished
        cp {output[0]} {output[1]}
        """


rule brain_and_spine_mask_qMT:
    input:
       spine_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_spine_mask.nii.gz",
       brain_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        brain_spine_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_spine_mask.nii.gz"  
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_spine_mask.log"
    shell: #combine brain and spine masks, and fill holes
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.brain_mask} -add {input.spine_mask} -fillh26 -dilD -dilD -ero -ero -bin {output.brain_spine_mask}
        """


#rules for registration with ANTS

rule DenoiseImage_qMT:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_denoised.log"
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


rule N4BiasFieldCorrection_qMT:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_denoised_n4.log"
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


rule register_qMT_to_t1w_ants:
    input:
        ref = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_denoised_n4.nii.gz",
        moving = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_denoised_n4.nii.gz",
        ref_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_mask.nii.gz",
        moving_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    params:
        outprefix="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_reg2{seq}t1w{qMT_params}_"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_reg2{seq}t1w{qMT_params}_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=1500
    threads: 4
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_reg2{seq}t1w{qMT_params}.log"
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
        --transform Rigid[ 0.1 ] \
        --metric MI[ {input.ref}, {input.moving}, 1, 32 ] \
        -o {params.outprefix} \
        -x [ {input.ref_mask}, {input.moving_mask} ] 
        """


rule apply_reg_qMT_to_t1w_ants:
    input:
        moving = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos.nii.gz",
        ref = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos.nii.gz",
        reg = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_reg2{seq}t1w{qMT_params}_0GenericAffine.mat"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_reg2{seq}t1w{qMT_params}.nii.gz"
    resources: 
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
       "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{contrast}{qMT_params}_mt-{mt}_part-{part}_sos_reg2{seq}t1w{qMT_params}.log" 
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        antsApplyTransforms \
        --dimensionality 3 \
        --interpolation Linear \
        --output-data-type short \
        --verbose 1 \
        -i {input.moving} \
        -r {input.ref} \
        -t {input.reg} \
        -o {output}
        """


#rules for after registration

rule mtr:
    input:
        mt_off = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_sos_reg2{seq}t1w{qMT_params}.nii.gz",
        mt_on = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mtw{qMT_params}_mt-on_part-mag_sos_reg2{seq}t1w{qMT_params}.nii.gz"
    resources: #limit memory by input size
        mem_mb=500
    threads: 1
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_MTRmap.nii.gz"
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_MTRmap.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        ImageMath 3 {output} MTR {input.mt_off} {input.mt_on}
        """


rule fit_JSPqMT_CLI:
    input:
        mt_off = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mt0{qMT_params}_mt-off_part-mag_sos_reg2{seq}t1w{qMT_params}.nii.gz",
        mt_on = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}mtw{qMT_params}_mt-on_part-mag_sos_reg2{seq}t1w{qMT_params}.nii.gz",
        pdw = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}pdw{qMT_params}_mt-off_part-mag_sos_reg2{seq}t1w{qMT_params}.nii.gz",
        t1w = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos.nii.gz",
        b1map = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{seq}t1w{qMT_params}_smooth_norm.nii.gz",
        mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_spine_mask.nii.gz"
    params:
        mt_params = get_qMT_params,
        t1flip = get_t1flip,
        pdflip = get_pdflip
    output:
        mpfmap = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_MPFmap.nii.gz",
        t1map = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map.nii.gz",
        r1map = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_R1map.nii.gz"
    threads: 4
    resources:
        mem_mb=4000
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_maps.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        python workflow/scripts/luca_qMT/qmt/fit_JSPqMT_CLI.py \
        {input.mt_off},{input.mt_on} \
        {input.pdw},{input.t1w} \
        {output.mpfmap} \
        {output.t1map} \
        --R1f {output.r1map} \
        --MTw_TIMINGS {params.mt_params[sat_pulse_ms]},{params.mt_params[interdelay_ms]},{params.mt_params[ro_pulse_ms]},{params.mt_params[tr_ms]} \
        --VFA_TIMINGS {params.mt_params[ro_pulse_ms]},{params.mt_params[tr_ms]} \
        --VFA_PARX {params.pdflip},{params.t1flip},{params.mt_params[ro_pulse_shape]} \
        --MTw_PARX {params.mt_params[ro_fa_deg]},{params.mt_params[ro_pulse_shape]},{params.mt_params[sat_pulse_fa_deg]},{params.mt_params[sat_pulse_offset_hz]},{params.mt_params[sat_pulse_shape]} \
        --B1 {input.b1map} \
        --mask {input.mask} \
        --nworkers {threads} \
        --cpp_opt --use_GBM
        """

#rules for registering to MP2RAGE with ANTS

rule apply_brainmask_T1map:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map_brain.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_T1map:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map_brain_denoised.log"
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


rule N4BiasFieldCorrection_T1map:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}t1w{qMT_params}_mt-off_part-mag_sos_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/preproc/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map_brain_denoised_n4.nii.gz"
    conda:
        "../envs/qMT.yaml"
    resources: 
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/sub-{subject}_ses-{session}_acq-{seq}{qMT_params}_T1map_brain_denoised_n4.log"
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

rule aggregate_qMT_by_field_strength:
    input:
        aggregate_qMT
    output:
        "data/derivatives/{field_strength}/qMT/qMT.done"
    log:
        "logs/{field_strength}/qMT/qMT.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        touch {output}
        """

rule aggregate_qMT:
    input:
        expand("data/derivatives/{field_strength}/qMT/qMT.done", field_strength=field_strength_list)