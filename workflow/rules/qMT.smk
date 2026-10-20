#requires BIDS data at data/rawdata/bids/{field_strength}
#requires B1map.smk
import json
import glob
import os
from pathlib import Path
from bids import BIDSLayout

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

#constrain wildcards to avoid ambiguity
wildcard_constraints:
    flip_angle = r'flip-\d+',
    # qMT_params = r'[^/]+', #match one or more characters that are not a forward slash
    part = 'mag|phase'


def get_mpm_acquisitions(field_strength, subject, session):
    """Return complete MPM acquisition labels, including BIDS entities."""
    pattern = (
        f"data/rawdata/bids/{field_strength}/sub-{subject}/ses-{session}/anat/"
        f"sub-{subject}_ses-{session}_acq-*_echo-*_MPM.nii.gz"
    )
    return sorted({
        Path(path).name.split("_acq-", 1)[1].split("_echo-", 1)[0]
        for path in glob.glob(pattern)
    })

def get_off_flips(wildcards):
    """Return real flip angles for mt-off MPM images from metadata."""
    paths = sorted(glob.glob(
        f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/'
        f'ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_'
        f'acq-{wildcards.qMT_params}_echo-1_flip-*_mt-off_part-mag_MPM.json'
    ))
    if not paths:
        raise ValueError(
            f"No MT-off qMT metadata found for acquisition '{wildcards.qMT_params}'"
        )
    with open(paths[0], "r") as metadata_file:
        flips = {json.load(metadata_file)["FlipAngle"]}
    for path in paths[1:]:
        with open(path, "r") as metadata_file:
            flips.add(json.load(metadata_file)["FlipAngle"])
    if len(flips) < 2:
        raise ValueError(
            f"Expected distinct MT-off flip angles for acquisition "
            f"'{wildcards.qMT_params}', found {sorted(flips)}"
        )
    return sorted(flips)

def get_flip_values(wildcards):
    """Return flip angles for mt-on and mt-off MPM files from metadata."""
    mtw_path = sorted(glob.glob(
        f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/'
        f'ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_'
        f'acq-{wildcards.qMT_params}_echo-1_flip-*_mt-on_part-mag_MPM.json'
    ))
    if not mtw_path:
        raise ValueError(
            f"No MT-on qMT metadata found for acquisition '{wildcards.qMT_params}'"
        )
    values = set(get_off_flips(wildcards))
    with open(mtw_path[0], "r") as metadata_file:
        values.add(float(json.load(metadata_file)["FlipAngle"]))
    return sorted(values, reverse=True)

def flip_value(wildcards, flip_angle):
    """Return a flip angle value given a flip angle index like 'flip-1'"""
    if isinstance(flip_angle, str) and flip_angle.startswith("flip-"):
        index = int(flip_angle.removeprefix("flip-")) - 1
        values = get_flip_values(wildcards)
        if index < 0 or index >= len(values):
            raise ValueError(
                f"Unknown qMT flip label '{flip_angle}' for "
                f"acquisition '{wildcards.qMT_params}'"
            )
        return values[index]
    return float(flip_angle)

def flip_label(wildcards, flip_angle):
    """Return flip angle index given a flip angle value."""
    value = float(flip_angle)
    values = get_flip_values(wildcards)
    try:
        return f"flip-{values.index(value) + 1}"
    except ValueError as error:
        raise ValueError(
            f"Flip angle '{flip_angle}' is not present for "
            f"acquisition '{wildcards.qMT_params}'"
        ) from error

def qmt_files(wildcards, flip_angle, part=None, mt=None):
    """Return MPM file names given flip angle index like 'flip-1', part, and mt."""
    flip_angle = flip_value(wildcards, flip_angle)
    pattern = (
        f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/'
        f'ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_'
        f'acq-{wildcards.qMT_params}_echo-*_flip-*'
    )
    if mt is not None:
        pattern += f'_mt-{mt}'
    if part is not None:
        pattern += f'_part-{part}'
    pattern += '_MPM.nii.gz'

    matches = []
    for nifti_path in sorted(glob.glob(pattern)):
        json_path = Path(nifti_path[:-7] + ".json")
        with open(json_path, "r") as metadata_file:
            metadata = json.load(metadata_file)
        if float(metadata["FlipAngle"]) == float(flip_angle):
            matches.append(nifti_path)

    if not matches:
        raise ValueError(
            f"No qMT files found for acquisition '{wildcards.qMT_params}', "
            f"flip angle '{flip_angle}', part '{part}', mt '{mt}'"
        )
    return matches

def get_echos(wildcards):
    """Return all echos of a given flip angle like 'flip-1', part, and mt."""
    return qmt_files(
        wildcards,
        wildcards.flip_angle,
        part=wildcards.part,
        mt=wildcards.mt,
    )

def get_qmt_json_path(wildcards, flip_angle, mt):
    """Return json metadata file of a given flip angle like 'flip-1' and mt."""
    nifti_path = Path(qmt_files(wildcards, flip_angle, part="mag", mt=mt)[0])
    return nifti_path.with_suffix("").with_suffix(".json")

def get_mtwflip(wildcards):
    """Get flip angle index of MTw MPM image."""
    paths = sorted(glob.glob(
        f'data/rawdata/bids/{wildcards.field_strength}/sub-{wildcards.subject}/'
        f'ses-{wildcards.session}/anat/sub-{wildcards.subject}_ses-{wildcards.session}_'
        f'acq-{wildcards.qMT_params}_echo-1_flip-*_mt-on_part-mag_MPM.json'
    ))
    if not paths:
        raise ValueError(
            f"No MT-on qMT metadata found for acquisition "
            f"'{wildcards.qMT_params}'"
        )
    json_path = paths[0]
    with open(json_path, "r") as metadata_file:
        return flip_label(wildcards, json.load(metadata_file)["FlipAngle"])

def get_qMT_params(wildcards):
    """Return parameters from json of MTw MPM."""
    json_path = get_qmt_json_path(
        wildcards, flip_value(wildcards, get_mtwflip(wildcards)), "on"
    )
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

def get_t1flip(wildcards):
    """Return flip angle index 'flip-1' which indicates T1w MPM."""
    return "flip-1"

def get_pdflip(wildcards):
    """Return flip angle index 'flip-#last' which indicates PDw MPM."""
    return f"flip-{len(get_flip_values(wildcards))}"

def get_t1flip_value(wildcards):
    """Return value of flip angle for T1w MPM."""
    return flip_value(wildcards, get_t1flip(wildcards))

def get_pdflip_value(wildcards):
    """Return value of flip angle for PDw MPM."""
    return flip_value(wildcards, get_pdflip(wildcards))

def t1w_sos_preproc(wildcards, suffix):
    """Return file string for image after SoS"""
    return (
        f"data/derivatives/{wildcards.field_strength}/qMT/sub-{wildcards.subject}/"
        f"ses-{wildcards.session}/acq-{wildcards.qMT_params}/preproc/"
        f"sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.qMT_params}_"
        f"{get_t1flip(wildcards)}_mt-off_part-mag_sos{suffix}"
    )

def qmt_role_path(wildcards, role, suffix):
    """Return file name for given role and suffix where role = 't1w', 'mt0', 'mtw' or 'pdw'."""
    flip = {
        "t1w": get_t1flip(wildcards),
        "mt0": get_mtwflip(wildcards),
        "mtw": get_mtwflip(wildcards),
        "pdw": get_pdflip(wildcards),
    }[role]
    mt = "on" if role == "mtw" else "off"
    return (
        f"data/derivatives/{wildcards.field_strength}/qMT/sub-{wildcards.subject}/"
        f"ses-{wildcards.session}/acq-{wildcards.qMT_params}/preproc/"
        f"sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.qMT_params}_"
        f"{flip}_mt-{mt}_part-mag_{suffix}"
    )

def denoised_contrast_path(wildcards):
    """Return filename of denoised MPM image."""
    if wildcards.mt == "on":
        role = "mtw_mt-on"
    elif wildcards.flip_angle == get_mtwflip(wildcards):
        role = "mt0_mt-off"
    elif wildcards.flip_angle == get_t1flip(wildcards):
        role = "t1w_mt-off"
    elif wildcards.flip_angle == get_pdflip(wildcards):
        role = "pdw_mt-off"
    else:
        raise ValueError(
            f"Cannot classify qMT flip angle '{wildcards.flip_angle}' "
            f"for acquisition '{wildcards.qMT_params}'"
        )
    return (
        f"data/derivatives/{wildcards.field_strength}/qMT/sub-{wildcards.subject}/"
        f"ses-{wildcards.session}/acq-{wildcards.qMT_params}/preproc/"
        f"sub-{wildcards.subject}_ses-{wildcards.session}_acq-{wildcards.qMT_params}_"
        f"{role}_part-{wildcards.part}_echos4d_denoise.nii"
    )

def t1wmag_preproc(wildcards):
    """Get preprocessed T1w magnitude image depending on if phase is available."""
    try:
        raw_phase = qmt_files(
            wildcards, get_t1flip(wildcards),
            part="phase", mt="off"
        )[0]
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-off_part-mag_echos4d_riciancorr.nii.gz"
        mag_preproc = mag_preproc.replace("{flip_angle}", str(get_t1flip(wildcards)))
    except:
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-off_part-mag_echos4d.nii"
        mag_preproc = mag_preproc.replace("{flip_angle}", str(get_t1flip(wildcards)))
    return mag_preproc

def mt0mag_preproc(wildcards):
    """Get preprocessed MT0 magnitude image depending on if phase is available."""
    try:
        raw_phase = qmt_files(
            wildcards, get_mtwflip(wildcards),
            part="phase", mt="off"
        )[0]
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-off_part-mag_echos4d_riciancorr.nii.gz"
        mag_preproc = mag_preproc.replace("{flip_angle}", str(get_mtwflip(wildcards)))
    except:
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-off_part-mag_echos4d.nii"
        mag_preproc = mag_preproc.replace("{flip_angle}", str(get_pdflip(wildcards)))
    return mag_preproc

def mtwmag_preproc(wildcards):
    """Get preprocessed MTw magnitude image depending on if phase is available."""
    try:
        raw_phase = qmt_files(
            wildcards, get_mtwflip(wildcards),
            part="phase", mt="on"
        )[0]
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-on_part-mag_echos4d_riciancorr.nii.gz"
        mag_preproc = mag_preproc.replace("{flip_angle}", str(get_mtwflip(wildcards)))
    except:
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-on_part-mag_echos4d.nii"
        mag_preproc = mag_preproc.replace("{flip_angle}", str(get_mtwflip(wildcards)))
    return mag_preproc

def pdwmag_preproc(wildcards):
    """Get preprocessed PDw magnitude image depending on if phase is available."""
    try:
        raw_phase = qmt_files(
            wildcards, get_pdflip(wildcards),
            part="phase", mt="off"
        )[0]
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-off_part-mag_echos4d_riciancorr.nii.gz"
        mag_preproc = mag_preproc.replace("{flip_angle}", str(get_pdflip(wildcards)))
    except:
        mag_preproc = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-off_part-mag_echos4d.nii"
        mag_preproc = mag_preproc.replace("{flip_angle}", str(get_pdflip(wildcards)))
    return mag_preproc

def aggregate_qMT(wildcards):
    """Return list of expected outputs given raw MPM images in BIDS."""
    layout=layout_dict[wildcards.field_strength]
    qMT_list = []
    R1map_list = []
    MTRmap_list = []
    subjectlist_tb1tfl = layout.get_subject(suffix="TB1TFL")
    subjectlist_tb1rfm = layout.get_subject(suffix="TB1RFM")
    subjectlist_mpm = layout.get_subject(suffix="MPM")
    subjectlist = list(
        (set(subjectlist_tb1tfl) | set(subjectlist_tb1rfm)) & set(subjectlist_mpm)
    )
    for subject in subjectlist:
        sessionlist_tb1tfl = layout.get_session(suffix="TB1TFL", subject=subject)
        sessionlist_tb1rfm = layout.get_session(suffix="TB1RFM", subject=subject)
        sessionlist_mpm = layout.get_session(suffix="MPM", subject=subject)
        sessionlist = list(
            (set(sessionlist_tb1tfl) | set(sessionlist_tb1rfm)) & set(sessionlist_mpm)
        )
        for session in sessionlist:
            mpm_acqlist = get_mpm_acquisitions(
                wildcards.field_strength, subject, session
            )
            for mpm in mpm_acqlist:
                R1map_list.append("data/derivatives/{field_strength}/qMT/sub-" + subject + "/ses-" + session + "/acq-" + mpm + "/preproc/sub-" + subject + "_ses-" + session + "_acq-" + mpm + "_R1map_brain_denoised_n4.nii.gz")
                MTRmap_list.append("data/derivatives/{field_strength}/qMT/sub-" + subject + "/ses-" + session + "/acq-" + mpm + "/sub-" + subject + "_ses-" + session + "_acq-" + mpm + "_MTRmap.nii.gz")
    return sorted(set(R1map_list + MTRmap_list))


rule concat_echos:
    input:
        echos = get_echos
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_echos4d.nii")
    resources:
        mem_mb=2000
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
      "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_echos4d.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrcat {input.echos} {output} -nthreads {threads}
        """


rule create_complex_images:
    input:
        mag="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-mag_echos4d.nii",
        phase="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-phase_echos4d.nii"
    output:
        mag_clipped=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-mag_echos4d_clippedtophase.nii"),
        out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-complex_echos4d.nii")
    resources: #limit memory by input size
        mem_mb=1500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
       "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-complex_echos4d.log"
    shell: #first clip mag so that it has the same number of volumes as phase, then calculate complex image
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        phasesize="$(mrinfo -size {input.phase} | awk '{{print $4}}')"
        magsize="$(mrinfo -size {input.mag} | awk '{{print $4}}')"
        magstart="$((${{magsize}}-${{phasesize}}))"
        mrconvert {input.mag} {output.mag_clipped} -coord 3 ${{magstart}}:end -nthreads {threads}
        mrcalc {output.mag_clipped} {input.phase} pi 4096 -div -mult -polar {output.out} -nthreads {threads}
        """


rule rician_bias_corr:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-complex_echos4d.nii"
    output:
        denoised=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-complex_echos4d_riciancorr.nii"),
        noisemap=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_echos4d_riciannoisemap.nii")
    resources: #limit memory by input size
        mem_mb=2500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_echos4d_riciannoisemap.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        dwidenoise {input} {output.denoised} -noise {output.noisemap} -nthreads {threads}
        """


rule calculate_mag_from_complex:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-complex_echos4d_riciancorr.nii"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-mag_echos4d_riciancorr.nii.gz"
    resources:
        mem_mb=1500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-mag_echos4d_riciancorr.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrcalc {input} -abs {output}
        """


rule calculate_phase_from_complex:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-complex_echos4d_riciancorr.nii"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-phase_echos4d_riciancorr.nii.gz"
    resources: #limit memory by input size
        mem_mb=1500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-phase_echos4d_riciancorr.log"
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
        t1w_out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_t1w_mt-off_part-mag_echos4d_clipped.nii"),
        mt0_out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_mt0_mt-off_part-mag_echos4d_clipped.nii"),
        mtw_out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_mtw_mt-on_part-mag_echos4d_clipped.nii"),
        pdw_out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_pdw_mt-off_part-mag_echos4d_clipped.nii")
    resources:
        mem_mb=1000
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
       "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_make_n_echos_equal.log"
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
        mrconvert {input.t1w_in} {output.t1w_out} -coord 3 0:${{end_idx}} -nthreads {threads}
        mrconvert {input.mt0_in} {output.mt0_out} -coord 3 0:${{end_idx}} -nthreads {threads}
        mrconvert {input.mtw_in} {output.mtw_out} -coord 3 0:${{end_idx}} -nthreads {threads}
        mrconvert {input.pdw_in} {output.pdw_out} -coord 3 0:${{end_idx}} -nthreads {threads}
        """


rule concat_contrast_mag:
    input:
        t1w="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_t1w_mt-off_part-mag_echos4d_clipped.nii",
        mt0="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_mt0_mt-off_part-mag_echos4d_clipped.nii",
        mtw="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_mtw_mt-on_part-mag_echos4d_clipped.nii",
        pdw="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_pdw_mt-off_part-mag_echos4d_clipped.nii"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_part-mag_echoscontrast5d.nii")
    resources:
        mem_mb=2000
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_part-mag_echoscontrast5d.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        mrcat {input.t1w} {input.mt0} {input.mtw} {input.pdw} {output} -axis 4
        """


rule denoise_contrast_mag:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_part-mag_echoscontrast5d.nii"
    output:
        out=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_part-mag_echoscontrast5d_denoise.nii"),
        noisemap=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_part-mag_noisemap.nii")
    resources: #limit memory by input size
        mem_mb=3000
    threads: 8
    conda:
        "../envs/tMPPCA.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_part-mag_noisemap.log"
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
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_part-mag_echoscontrast5d_denoise.nii"
    output:
        t1w=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_t1w_mt-off_part-mag_echos4d_denoise.nii"),
        mt0=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_mt0_mt-off_part-mag_echos4d_denoise.nii"),
        mtw=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_mtw_mt-on_part-mag_echos4d_denoise.nii"),
        pdw=temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_pdw_mt-off_part-mag_echos4d_denoise.nii")
    resources:
        mem_mb=2000
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_split_contrast_mag.log"
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
        denoised_contrast_path
    output:
       temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos.nii.gz")
    resources:
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        python workflow/scripts/sos_images.py {input} {output}
        """

rule qMT_nan_to_0:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos.nii.gz",
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_nan.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources:
        mem_mb=500
    threads: 1
    log:
       "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_nan.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input} -nan {output}
        """


rule synthstrip_qMT:
    input:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_nan.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz")
    container:
        "docker://freesurfer/synthstrip:1.8-gpu"
    threads: 4
    resources:
        mem_mb=9000
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_mask.log"
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
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources:
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain.log"
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
       img="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos.nii.gz",
       install_sct_done=".snakemake/scripts/install_sct.done"
    output: #these are the same image, the temp image is deleted after the rule is finished
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_seg.nii.gz"),
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_spine_mask.nii.gz"),
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_seg.json"),
    threads: 4
    resources:
        mem_mb=9000
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_spine_mask.log"
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
       spine_mask = lambda wildcards: t1w_sos_preproc(
           wildcards, "_spine_mask.nii.gz"
       ),
       brain_mask = lambda wildcards: t1w_sos_preproc(
           wildcards, "_brain_mask.nii.gz"
       )
    output:
        spine_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_spine_mask.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_brain_mask.nii.gz",
        brain_spine_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_brain_spine_mask.nii.gz"
    conda:
        "../envs/fslmaths.yaml"
    resources:
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_brain_spine_mask.log"
    shell: #combine brain and spine masks, and fill holes
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.brain_mask} -add {input.spine_mask} -fillh26 -dilD -dilD -ero -ero -bin {output.brain_spine_mask}
        cp {input.spine_mask} {output.spine_mask}
        cp {input.brain_mask} {output.brain_mask}
        """


#rules for registration with ANTS

rule DenoiseImage_qMT:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_denoised.log"
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
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_denoised_n4.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources:
        mem_mb=1000
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_denoised_n4.log"
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
        ref = lambda wildcards: t1w_sos_preproc(
            wildcards, "_brain_denoised_n4.nii.gz"
        ),
        moving = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_denoised_n4.nii.gz",
        ref_mask = lambda wildcards: t1w_sos_preproc(
            wildcards, "_brain_mask.nii.gz"
        ),
        moving_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_brain_mask.nii.gz"
    params:
        outprefix="data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_reg2{qMT_params}_t1w_"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_reg2{qMT_params}_t1w_0GenericAffine.mat"
    conda:
        "../envs/qMT.yaml"
    resources:
        mem_mb=1500
    threads: 4
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_reg2{qMT_params}_t1w.log"
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
        moving = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos.nii.gz",
        ref = lambda wildcards: t1w_sos_preproc(
            wildcards, ".nii.gz"
        ),
        reg = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_reg2{qMT_params}_t1w_0GenericAffine.mat"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_reg2{qMT_params}_t1w.nii.gz"
    resources:
        mem_mb=500
    threads: 1
    conda:
        "../envs/qMT.yaml"
    log:
       "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_{flip_angle}_mt-{mt}_part-{part}_sos_reg2{qMT_params}_t1w.log"
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
        mt_off = lambda wildcards: qmt_role_path(
            wildcards, "mt0", f"sos_reg2{wildcards.qMT_params}_t1w.nii.gz"
        ),
        mt_on = lambda wildcards: qmt_role_path(
            wildcards, "mtw", f"sos_reg2{wildcards.qMT_params}_t1w.nii.gz"
        )
    resources: #limit memory by input size
        mem_mb=500
    threads: 1
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_MTRmap.nii.gz"
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_MTRmap.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console

        export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS={threads}

        ImageMath 3 {output} MTR {input.mt_off} {input.mt_on}
        ImageMath 3 {output} Finite {output}
        """


rule fit_JSPqMT_CLI:
    input:
        mt_off = lambda wildcards: qmt_role_path(
            wildcards, "mt0", f"sos_reg2{wildcards.qMT_params}_t1w.nii.gz"
        ),
        mt_on = lambda wildcards: qmt_role_path(
            wildcards, "mtw", f"sos_reg2{wildcards.qMT_params}_t1w.nii.gz"
        ),
        pdw = lambda wildcards: qmt_role_path(
            wildcards, "pdw", f"sos_reg2{wildcards.qMT_params}_t1w.nii.gz"
        ),
        t1w = lambda wildcards: t1w_sos_preproc(
            wildcards, ".nii.gz"
        ),
        b1map = "data/derivatives/{field_strength}/B1map/sub-{subject}/ses-{session}/reg2qMT/sub-{subject}_ses-{session}_acq-famp_reg2{qMT_params}_t1w_smooth_norm.nii.gz",
        mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_brain_spine_mask.nii.gz"
    params:
        mt_params = get_qMT_params,
        t1flip = get_t1flip_value,
        pdflip = get_pdflip_value
    output:
        mpfmap = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_MPFmap.nii.gz",
        t1map = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_T1map.nii.gz",
        r1map = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map.nii.gz"
    threads: 4
    resources:
        mem_mb=4000
    conda:
        "../envs/qMT.yaml"
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_maps.log"
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

rule apply_brainmask_R1map:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map.nii.gz",
        brain_mask = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain.nii.gz")
    conda:
        "../envs/fslmaths.yaml"
    resources:
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain.log"
    shell:
        """
        exec > >(tee {log}) 2>&1 #save output to log AND print to console
        export FSLOUTPUTTYPE='NIFTI_GZ'
        fslmaths {input.input_image} -mas {input.brain_mask} {output}
        """


rule DenoiseImage_R1map:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain.nii.gz",
        mask_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_brain_mask.nii.gz"
    output:
        temp("data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain_denoised.nii.gz")
    conda:
        "../envs/qMT.yaml"
    resources:
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain_denoised.log"
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


rule N4BiasFieldCorrection_R1map:
    input:
        input_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain_denoised.nii.gz",
        mask_image = "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/masks_segs/sub-{subject}_ses-{session}_acq-{qMT_params}_brain_mask.nii.gz"
    output:
        "data/derivatives/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain_denoised_n4.nii.gz"
    conda:
        "../envs/qMT.yaml"
    resources:
        mem_mb=500
    threads: 1
    log:
        "logs/{field_strength}/qMT/sub-{subject}/ses-{session}/acq-{qMT_params}/preproc/sub-{subject}_ses-{session}_acq-{qMT_params}_R1map_brain_denoised_n4.log"
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
        temp("data/derivatives/{field_strength}/qMT/qMT.done")
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