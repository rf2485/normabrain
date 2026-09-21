import subprocess
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
TEST_INPUT = REPO_ROOT / ".tests" / "test_input"

MP2RAGE_RULES = [
    "add_xml_data_to_meta_mp2rage",
    "json_for_uncorr_T1map",
    "create_uncorr_T1map",
    "synthstrip_T1map",
    "apply_brainmask_T1map_mp2rage",
    "DenoiseImage_T1map_mp2rage",
    "N4BiasFieldCorrection_T1map_mp2rage",
    "json_for_mp2proc",
    "run_mp2proc",
    "apply_brainmask_mp2rage",
    "MPRAGEise",
    "crop_mp2rage_256",
    "recon_all",
    "register_mp2rage_acqs",
    "apply_reg_first_mp2rage_acq",
    "aparc_aseg_to_subject_mp2rage",
    "copy_aparc_aseg_lut",
    "download_mni_icbm152_nlin_sym_09c_minc2",
    "wm_lobes_nii_to_nii_gz",
    "wm90percent_lobes",
    "warp_subject_mp2rage_to_mni152",
    "apply_warp_mni_atlases_to_subject_mp2rage",
    "mp2rage_roi_stats",
    "mp2rage_roi_stats_agg_segs",
    "mp2rage_roi_stats_agg_subjs",
    "aggregate_mp2rage_stats",
    "aggregate_mp2rage_coreg",
    "aggregate_mp2rage",
]

HARNESS = """
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
        return ["mp2ragewipsag1isoc6DL5340us"]

layout_dict = {"3T": FakeLayout()}

include: "rules/B1map.smk"
include: "rules/MP2RAGE.smk"
"""


def _create_workdir(tmp_path):
    workdir = tmp_path / "workdir"
    (workdir / "workflow" / "rules").mkdir(parents=True)
    (workdir / "config").mkdir()
    (workdir / "workflow" / "Snakefile").write_text(HARNESS, encoding="utf-8")
    for rule_file in ("B1map.smk", "MP2RAGE.smk"):
        (workdir / "workflow" / "rules" / rule_file).write_text(
            (REPO_ROOT / "workflow" / "rules" / rule_file).read_text(),
            encoding="utf-8",
        )
    (workdir / "config" / "snakemake_config.yaml").write_text(
        "protocol_path: test_input/protocol_xml_pdf\n"
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


@pytest.mark.parametrize("rule", MP2RAGE_RULES)
def test_mp2rage_rule_is_registered(tmp_path, rule):
    workdir = _create_workdir(tmp_path)
    assert rule in _registered_rules(workdir)


def test_test_input_contains_mp2rage_and_b1map_sources():
    source_root = TEST_INPUT / "dicoms" / "test3Ta" / "20260728"
    source_names = {path.name.lower() for path in source_root.iterdir() if path.is_dir()}
    assert any("mp2rage" in name for name in source_names)
    assert any("b1map" in name or "tfl" in name for name in source_names)
    assert (TEST_INPUT / "protocol_xml_pdf").is_dir()
