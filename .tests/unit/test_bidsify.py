import shutil
import subprocess
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
TEST_INPUT = REPO_ROOT / ".tests" / "test_input"
SNAKEFILE = REPO_ROOT / "workflow" / "Snakefile"
BIDSCOIN_CONTAINER = "oras://ghcr.io/donders-institute/bidscoin:4.6.2"


def _create_workdir(tmp_path):
    workdir = tmp_path / "workdir"
    workdir.mkdir()

    shutil.copytree(TEST_INPUT, workdir / "test_input")
    shutil.copytree(REPO_ROOT / "workflow" / "scripts", workdir / "workflow" / "scripts")
    shutil.copytree(REPO_ROOT / "config", workdir / "config")

    snakemake_config = workdir / "config" / "snakemake_config.yaml"
    snakemake_config.write_text(
        "input_dicoms_path: test_input/dicoms\n"
        "protocol_path: test_input/protocol_xml_pdf\n"
        "subject_list_dicom: test3Ta\n"
        "segmentations: ''\n"
        "qmt_sequence: vibeMT\n"
        "qmt_contrasts: 'mt0 mtw pdw t1w'\n",
        encoding="utf-8",
    )
    return workdir


def _run_target(workdir, target, rule):
    subprocess.run(
        [
            "python",
            "-m",
            "snakemake",
            target,
            "--snakefile",
            SNAKEFILE,
            "--force",
            "--notemp",
            "--show-failed-logs",
            "--cores",
            "1",
            "--allowed-rules",
            rule,
            "--configfile",
            "config/snakemake_config.yaml",
            "--software-deployment-method",
            "apptainer",
            "--directory",
            workdir,
        ],
        cwd=REPO_ROOT,
        check=True,
    )


def test_symlink_dicoms_by_field_strength(tmp_path):
    workdir = _create_workdir(tmp_path)

    _run_target(workdir, "data/rawdata/dicoms", "symlink_dicoms_by_field_strength")

    output = workdir / "data" / "rawdata" / "dicoms" / "3T"
    assert output.is_dir()
    session = output / "sub-test3Ta" / "ses-1"
    assert session.is_dir()
    assert any(path.is_symlink() for path in session.iterdir())


def test_bidsmapper(tmp_path):
    workdir = _create_workdir(tmp_path)

    _run_target(
        workdir,
        "data/rawdata/bids/3T/code/bidscoin/bidsmap.yaml",
        "bidsmapper",
    )

    bidsmap = workdir / "data" / "rawdata" / "bids" / "3T" / "code" / "bidscoin" / "bidsmap.yaml"
    assert bidsmap.is_file()
    assert bidsmap.stat().st_size > 0


def test_bidscoiner(tmp_path):
    workdir = _create_workdir(tmp_path)

    _run_target(
        workdir,
        "data/rawdata/bids/3T/participants.tsv",
        "bidscoiner",
    )

    participants = workdir / "data" / "rawdata" / "bids" / "3T" / "participants.tsv"
    assert participants.is_file()
    assert (participants.parent / "sub-test3Ta").is_dir()


@pytest.mark.parametrize(
    "target,rule",
    [
        (
            "data/rawdata/bids/3T/code/bidscoin/fixmeta.log",
            "add_csa_data_to_meta",
        ),
        ("data/rawdata/bidsify.done", "gather_add_csa_data_to_meta"),
    ],
)
def test_downstream_bidsify_rules(tmp_path, target, rule):
    workdir = _create_workdir(tmp_path)

    _run_target(workdir, target, rule)

    assert (workdir / target).is_file()
