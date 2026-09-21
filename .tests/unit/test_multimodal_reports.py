import subprocess
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
TEST_INPUT = REPO_ROOT / ".tests" / "test_input"

MULTIMODAL_RULES = [
    "register_ihmt_to_freesurfer_bbregister",
    "apply_reg_ihmt_to_freesurfer_bbregister",
    "gather_ihmt_to_freesurfer_bbregister",
    "apply_aparc_aseg_to_ihmt_bbregister",
    "warp_ihmt_to_mni152",
    "apply_warp_mni_atlases_to_ihmt",
    "ihmt_roi_stats",
    "ihmt_roi_stats_agg_segs",
    "ihmt_roi_stats_agg_subjs",
    "aggregate_ihmt_stats",
    "aggregate_multimodal_ihmt_mp2rage",
    "register_qMT_to_MP2RAGE_ants",
    "apply_reg_qMT_to_MP2RAGE_ants",
    "gather_qMT_to_MP2RAGE_ants",
    "apply_reg_seg_to_qMT_ants",
    "qMT_stats",
    "qMT_tsv",
    "apply_reg_MP2RAGE_to_qMT_ants",
    "gather_MP2RAGE_to_qMT_ants",
    "aggregate_multimodal_qMT_mp2rage",
    "register_DWI_to_MP2RAGE_bbregister",
    "apply_reg_DWI_to_MP2RAGE_bbregister",
    "gather_DWI_to_MP2RAGE_bbregister",
    "apply_reg_seg_to_dwi_bbregister",
    "dwi_stats",
    "dwi_tsv",
    "apply_reg_MP2RAGE_to_dwi_bbregister",
    "gather_MP2RAGE_to_dwi_bbregister",
    "aggregate_multimodal_dwi_mp2rage",
]

REPORT_RULES = [
    "filter_data",
    "ihmt_b1corr_test_retest",
    "view_ihmt_stats_datavzrd",
]

HARNESS = """
import re
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
        return ["ihMTMCsag16isop3"]

layout_dict = {"3T": FakeLayout()}

include: "rules/multimodal_registration_segmentation.smk"
include: "rules/generate_reports.smk"
"""


def _create_workdir(tmp_path):
    workdir = tmp_path / "workdir"
    (workdir / "workflow" / "rules").mkdir(parents=True)
    (workdir / "config").mkdir()
    (workdir / "workflow" / "Snakefile").write_text(HARNESS, encoding="utf-8")
    for rule_file in ("multimodal_registration_segmentation.smk", "generate_reports.smk"):
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


@pytest.mark.parametrize("rule", MULTIMODAL_RULES + REPORT_RULES)
def test_multimodal_report_rule_is_registered(tmp_path, rule):
    workdir = _create_workdir(tmp_path)
    assert rule in _registered_rules(workdir)


def test_test_input_contains_multimodal_sources():
    source_root = TEST_INPUT / "dicoms" / "test3Ta" / "20260728"
    source_names = {path.name.lower() for path in source_root.iterdir() if path.is_dir()}
    assert any("mp2rage" in name for name in source_names)
    assert any("ihmt" in name for name in source_names)
    assert any("vibemt" in name for name in source_names)
    assert any("dwi" in name for name in source_names)
    assert any("b1map" in name or "tfl" in name for name in source_names)
