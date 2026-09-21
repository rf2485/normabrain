import subprocess
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
TEST_INPUT = REPO_ROOT / ".tests" / "test_input"

QMT_RULES = [
    "concat_echos",
    "create_complex_images",
    "rician_bias_corr",
    "calculate_mag_from_complex",
    "calculate_phase_from_complex",
    "make_n_echos_equal",
    "concat_contrast_mag",
    "denoise_contrast_mag",
    "split_contrast_mag",
    "sos",
    "synthstrip_qMT",
    "apply_brainmask_qMT",
    "install_sct",
    "spineseg_qMT",
    "brain_and_spine_mask_qMT",
    "DenoiseImage_qMT",
    "N4BiasFieldCorrection_qMT",
    "register_qMT_to_t1w_ants",
    "apply_reg_qMT_to_t1w_ants",
    "mtr",
    "fit_JSPqMT_CLI",
    "apply_brainmask_T1map",
    "DenoiseImage_T1map",
    "N4BiasFieldCorrection_T1map",
    "aggregate_qMT_by_field_strength",
    "aggregate_qMT",
]

QSM_RULES = [
    "copy_raw_qsm",
    "copy_denoised_qsm",
    "copy_raw_t1w_json_qsm",
    "copy_uniden_qsm",
    "copy_mask_qsm",
    "qsmxt",
    "aggregate_qsmxt",
]

HARNESS = """
import os
from pathlib import Path

configfile: "config/snakemake_config.yaml"
bidspath = Path("data/rawdata/bids")
field_strength_list = ["3T"]

class FakeLayout:
    def get_subject(self, **kwargs):
        return ["test3Ta"]

    def get_session(self, **kwargs):
        return ["1"]

    def get_acquisition(self, **kwargs):
        return ["vibeMT"]

layout_dict = {"3T": FakeLayout()}

include: "rules/qMT.smk"
include: "rules/QSM.smk"
"""


def _create_workdir(tmp_path):
    workdir = tmp_path / "workdir"
    (workdir / "workflow" / "rules").mkdir(parents=True)
    (workdir / "config").mkdir()
    (workdir / "workflow" / "Snakefile").write_text(HARNESS, encoding="utf-8")
    for rule_file in ("qMT.smk", "QSM.smk"):
        (workdir / "workflow" / "rules" / rule_file).write_text(
            (REPO_ROOT / "workflow" / "rules" / rule_file).read_text(),
            encoding="utf-8",
        )
    (workdir / "config" / "snakemake_config.yaml").write_text(
        "qmt_sequence: vibeMT\n"
        "qmt_contrasts: 'mt0 mtw pdw t1w'\n"
        "segmentations: 'aparc+aseg mni_icbm152_nlin_asym_09c_wm90percent_lobes mni_icbm152_wm_lobes'\n",
        encoding="utf-8",
    )
    return workdir


def _registered_rules(workdir):
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
    return set(result.stdout.split())


@pytest.mark.parametrize("rule", QMT_RULES + QSM_RULES)
def test_qmt_qsm_rule_is_registered(tmp_path, rule):
    workdir = _create_workdir(tmp_path)
    assert rule in _registered_rules(workdir)


def test_test_input_contains_qmt_and_qsm_sources():
    source_root = TEST_INPUT / "dicoms" / "test3Ta" / "20260728"
    source_names = {path.name.lower() for path in source_root.iterdir() if path.is_dir()}
    assert any("vibemt" in name for name in source_names)
    assert any("t2s" in name or "t2-semc" in name for name in source_names)
