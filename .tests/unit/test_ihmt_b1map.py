import subprocess
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
TEST_INPUT = REPO_ROOT / ".tests" / "test_input"

IHMT_RULES = [
    "add_xml_data_to_meta_ihmt",
    "denoise_ihmt",
    "degibbs_ihmt",
    "moco_ihmt",
    "split_contrast_ihmt",
    "calculate_ihmt_maps",
    "synthstrip_ihmt",
    "apply_brainmask_MTmap",
    "DenoiseImage_ihmt",
    "N4BiasFieldCorrection_ihmt",
    "b1corr_ihmt",
    "apply_brainmask_ihmt",
    "aggregate_ihmt_maps_by_field_strength",
    "aggregate_ihmt_maps",
]

B1MAP_RULES = [
    "synthstrip_b1anat",
    "apply_brainmask_b1anat",
    "DenoiseImage_b1anat",
    "N4BiasFieldCorrection_b1anat",
    "register_b1anat_to_mp2rage",
    "apply_reg_b1_to_mp2rage",
    "register_b1anat_to_qMT_t1w_ants",
    "apply_reg_b1map_to_qMT_t1w_ants",
    "register_b1anat_to_ihmt",
    "apply_reg_b1_to_ihmt",
    "copy_b1map_json_after_regtoMP2RAGE",
    "smooth_B1_qMT",
    "normalize_B1_to_target_flip_qMT",
    "smooth_B1_ihmt",
    "normalize_B1_to_target_flip_ihmt",
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
        return ["ihMTMCsag16isop3"]

layout_dict = {"3T": FakeLayout()}

include: "rules/B1map.smk"
include: "rules/ihMT.smk"
"""


def _create_workdir(tmp_path):
    workdir = tmp_path / "workdir"
    (workdir / "workflow" / "rules").mkdir(parents=True)
    (workdir / "config").mkdir()
    (workdir / "workflow" / "Snakefile").write_text(HARNESS, encoding="utf-8")
    for rule_file in ("B1map.smk", "ihMT.smk"):
        (workdir / "workflow" / "rules" / rule_file).write_text(
            (REPO_ROOT / "workflow" / "rules" / rule_file).read_text(),
            encoding="utf-8",
        )
    (workdir / "config" / "snakemake_config.yaml").write_text(
        "protocol_path: test_input/protocol_xml_pdf\n",
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


@pytest.mark.parametrize("rule", IHMT_RULES + B1MAP_RULES)
def test_rule_is_registered(tmp_path, rule):
    workdir = _create_workdir(tmp_path)
    assert rule in _registered_rules(workdir)


def test_test_input_contains_ihmt_and_b1map_sources():
    source_root = TEST_INPUT / "dicoms" / "test3Ta" / "20260728"
    source_names = {path.name for path in source_root.iterdir() if path.is_dir()}
    assert any("ihmt" in name.lower() for name in source_names)
    assert any("tfl-b1map" in name.lower() for name in source_names)
    assert (TEST_INPUT / "protocol_xml_pdf").is_dir()
