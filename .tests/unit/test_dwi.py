import subprocess
import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
DWI_PARAMS = "3shb2ktraPA1p8p1s3"
SUBJECT = "test3Ta"
SESSION = "1"
FIELD_STRENGTH = "3T"



def _designer_target():
    return (
        f"data/derivatives/{FIELD_STRENGTH}/dwi/sub-{SUBJECT}/ses-{SESSION}/"
        f"acq-DWI{DWI_PARAMS}/sub-{SUBJECT}_ses-{SESSION}_acq-DWI{DWI_PARAMS}_designer.mif"
    )
HARNESS = '''
from pathlib import Path

bidspath = Path("data/rawdata/bids")
field_strength_list = ["3T"]

class FakeLayout:
    def get_subject(self, **kwargs):
        return ["test3Ta"]

    def get_session(self, **kwargs):
        return ["1"]

    def get_acquisition(self, **kwargs):
        return ["3shb2ktraPA1p8p1s3"]

layout_dict = {"3T": FakeLayout()}

include: "rules/DWI.smk"
'''


def _create_workdir(tmp_path):
    workdir = tmp_path / "workdir"
    workdir.mkdir()
    (workdir / "workflow" / "rules").mkdir(parents=True)
    (workdir / "workflow" / "rules" / "DWI.smk").write_text(
        (REPO_ROOT / "workflow" / "rules" / "DWI.smk").read_text(),
        encoding="utf-8",
    )
    (workdir / "workflow" / "Snakefile").write_text(HARNESS, encoding="utf-8")
    shutil.copytree(REPO_ROOT / ".tests" / "test_input", workdir / "test_input")
    shutil.copytree(REPO_ROOT / "workflow" / "scripts", workdir / "workflow" / "scripts")
    (workdir / "data" / "rawdata" / "bids" / FIELD_STRENGTH / SUBJECT / f"ses-{SESSION}" / "dwi").mkdir(parents=True)
    (workdir / "data" / "derivatives" / FIELD_STRENGTH / "dwi" / f"sub-{SUBJECT}" / f"ses-{SESSION}").mkdir(parents=True)
    _convert_real_dwi_inputs(workdir)
    return workdir


def _touch(workdir, relative_path):
    path = workdir / relative_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.touch()


def _dwi_mif(workdir, direction, part):
    return (
        f"data/derivatives/{FIELD_STRENGTH}/dwi/sub-{SUBJECT}/ses-{SESSION}/"
        f"acq-DWI{DWI_PARAMS}/sub-{SUBJECT}_ses-{SESSION}_acq-DWI{DWI_PARAMS}_"
        f"dir-{direction}_part-{part}_dwi.mif"
    )


def _dwi_nii(workdir, direction, part):
    return (
        f"data/rawdata/bids/{FIELD_STRENGTH}/sub-{SUBJECT}/ses-{SESSION}/dwi/"
        f"sub-{SUBJECT}_ses-{SESSION}_acq-{DWI_PARAMS}_dir-{direction}_part-{part}_dwi.nii.gz"
    )


def _assert_dwi_inputs(workdir):
    for direction in ("PA", "AP"):
        for part in ("mag", "phase"):
            input_path = workdir / _dwi_nii(workdir, direction, part)
            assert input_path.is_file()
            assert input_path.stat().st_size > 0


def _assert_concat_outputs(workdir):
    for direction in ("PA", "AP"):
        for part in ("mag", "phase"):
            output_path = workdir / _dwi_mif(workdir, direction, part)
            assert output_path.is_file()
            assert output_path.stat().st_size > 0


def _convert_real_dwi_inputs(workdir):
    source_series = {
        "PA": "00_0054_dwi-3sh-b2k-tra-pa-1p8-p1s3",
        "PA_phase": "00_0055_dwi-3sh-b2k-tra-pa-1p8-p1s3-pha",
        "AP": "00_0057_dwi-3sh-b2k-tra-ap-1p8-p1s3",
        "AP_phase": "00_0058_dwi-3sh-b2k-tra-ap-1p8-p1s3-pha",
    }
    output_dir = workdir / "data" / "rawdata" / "bids" / FIELD_STRENGTH / f"sub-{SUBJECT}" / f"ses-{SESSION}" / "dwi"
    output_dir.mkdir(parents=True, exist_ok=True)
    for key, series in source_series.items():
        direction, part = key.split("_") if "_" in key else (key, "mag")
        output_name = f"sub-{SUBJECT}_ses-{SESSION}_acq-{DWI_PARAMS}_dir-{direction}_part-{part}_dwi"
        source_dir = workdir / "test_input" / "dicoms" / SUBJECT / "20260728" / series
        subprocess.run(
            [
                "singularity",
                "exec",
                "--bind",
                f"{workdir}:/work",
                "--pwd",
                "/work",
                "oras://ghcr.io/donders-institute/bidscoin:4.6.2",
                "dcm2niix",
                "-b",
                "y",
                "-z",
                "y",
                "-f",
                output_name,
                "-o",
                "/work/" + str(output_dir.relative_to(workdir)),
                "/work/" + str(source_dir.relative_to(workdir)),
            ],
            cwd=workdir,
            check=True,
            stdout=subprocess.DEVNULL,
        )
        if part == "phase":
            generated_base = output_dir / f"{output_name}_ph"
            expected_base = output_dir / output_name
            for suffix in (".nii.gz", ".json", ".bvec", ".bval"):
                generated_file = generated_base.with_name(generated_base.name + suffix)
                expected_file = expected_base.with_name(expected_base.name + suffix)
                if generated_file.exists():
                    generated_file.rename(expected_file)


def _run(workdir, target, rule):
    command = [
        "python",
        "-m",
        "snakemake",
        target,
        "--snakefile",
        "workflow/Snakefile",
        "--force",
        "--cores",
        "1",
        "--allowed-rules",
        rule,
        "--software-deployment-method",
        "apptainer",
        "--directory",
        workdir,
    ]
    command.extend(["--notemp"])
    subprocess.run(command, cwd=workdir, check=True, text=True)


def _mif_target(workdir, direction, part):
    return _dwi_mif(workdir, direction, part)


def _prepare_designer(workdir):
    _run(workdir, _mif_target(workdir, "PA", "mag"), "concat_dwi_runs")
    _run(workdir, _designer_target(), "nyu_designer")


def test_concat_dwi_runs_expands_inputs(tmp_path):
    workdir = _create_workdir(tmp_path)

    _run(workdir, _mif_target(workdir, "PA", "mag"), "concat_dwi_runs")
    assert (workdir / _mif_target(workdir, "PA", "mag")).stat().st_size > 0


def test_nyu_designer_expands_inputs(tmp_path):
    workdir = _create_workdir(tmp_path)
    _assert_dwi_inputs(workdir)
    _run(workdir, _mif_target(workdir, "PA", "mag"), "concat_dwi_runs")
    _assert_concat_outputs(workdir)

    target = _designer_target()
    _run(workdir, target, "nyu_designer")
    assert (workdir / target).stat().st_size > 0


def test_convert_designer_mif_to_nii(tmp_path):
    workdir = _create_workdir(tmp_path)
    designer = _designer_target()
    _prepare_designer(workdir)
    target = designer.removesuffix(".mif") + ".nii.gz"
    _run(workdir, target, "convert_designer_mif_to_nii")
    assert (workdir / target).stat().st_size > 0


def test_mean_b0(tmp_path):
    workdir = _create_workdir(tmp_path)
    designer = _designer_target()
    _prepare_designer(workdir)
    target = designer.replace("_designer.mif", "_designer_meanb0.nii.gz")
    _run(workdir, target, "mean_b0")
    assert (workdir / target).stat().st_size > 0


def test_b0_mask(tmp_path):
    workdir = _create_workdir(tmp_path)
    meanb0 = (
        f"data/derivatives/{FIELD_STRENGTH}/dwi/sub-{SUBJECT}/ses-{SESSION}/"
        f"acq-DWI{DWI_PARAMS}/sub-{SUBJECT}_ses-{SESSION}_acq-DWI{DWI_PARAMS}_designer_meanb0.nii.gz"
    )
    _prepare_designer(workdir)
    _run(workdir, meanb0, "mean_b0")
    target = meanb0.removesuffix(".nii.gz") + "_brainmask.nii"
    _run(workdir, target, "b0_mask")
    assert (workdir / target).stat().st_size > 0


def test_apply_brainmask_meanb0(tmp_path):
    workdir = _create_workdir(tmp_path)
    base = f"data/derivatives/{FIELD_STRENGTH}/dwi/sub-{SUBJECT}/ses-{SESSION}/acq-DWI{DWI_PARAMS}/sub-{SUBJECT}_ses-{SESSION}_acq-DWI{DWI_PARAMS}_designer_meanb0"
    _prepare_designer(workdir)
    _run(workdir, base + ".nii.gz", "mean_b0")
    _run(workdir, base + "_brainmask.nii", "b0_mask")
    _run(workdir, base + "_brain.nii.gz", "apply_brainmask_meanb0")
    assert (workdir / (base + "_brain.nii.gz")).stat().st_size > 0


def test_dki_tensor_dipy(tmp_path):
    workdir = _create_workdir(tmp_path)
    base = f"data/derivatives/{FIELD_STRENGTH}/dwi/sub-{SUBJECT}/ses-{SESSION}/acq-DWI{DWI_PARAMS}/sub-{SUBJECT}_ses-{SESSION}_acq-DWI{DWI_PARAMS}_designer"
    _prepare_designer(workdir)
    _run(workdir, base + ".nii.gz", "convert_designer_mif_to_nii")
    _run(workdir, base + "_meanb0_brainmask.nii", "b0_mask")
    target = f"data/derivatives/{FIELD_STRENGTH}/dwi/sub-{SUBJECT}/ses-{SESSION}/acq-DWI{DWI_PARAMS}/dki"
    _run(workdir, target, "dki_tensor_dipy")


def test_aggregate_dki_by_field_strength(tmp_path):
    workdir = _create_workdir(tmp_path)
    dki = f"data/derivatives/{FIELD_STRENGTH}/dwi/sub-{SUBJECT}/ses-{SESSION}/acq-DWI{DWI_PARAMS}/dki"
    (workdir / dki).mkdir(parents=True)
    _run(workdir, f"data/derivatives/{FIELD_STRENGTH}/dwi/dki.done", "aggregate_dki_by_field_strength")
    assert (workdir / f"data/derivatives/{FIELD_STRENGTH}/dwi/dki.done").is_file()


def test_aggregate_dki_is_registered(tmp_path):
    workdir = _create_workdir(tmp_path)
    result = subprocess.run(
        [
            "python",
            "-m",
            "snakemake",
            "--list",
            "--snakefile",
            "workflow/Snakefile",
            "--directory",
            workdir,
        ],
        cwd=workdir,
        check=True,
        text=True,
        capture_output=True,
    )
    assert "aggregate_dki" in result.stdout
