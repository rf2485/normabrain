import importlib.util
from pathlib import Path

import pytest


SCRIPT = Path(__file__).resolve().parents[2] / "workflow/scripts/generate_aslcontext.py"
SPEC = importlib.util.spec_from_file_location("generate_aslcontext", SCRIPT)
assert SPEC and SPEC.loader
module = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(module)


def test_generate_context_uses_per_volume_metadata():
    metadata = {
        "NumberOfVolumesIn4D": 3,
        "ASLContext": ["control", "label", "control"],
    }

    assert module.generate_context(metadata) == ["control", "label", "control"]


def test_generate_context_expands_explicit_pattern_and_marks_m0():
    metadata = {"NumberOfVolumesIn4D": 4}

    assert module.generate_context(
        metadata,
        pattern=["control", "label"],
        m0_indexes={0},
    ) == ["m0scan", "label", "control", "label"]


def test_generate_context_reads_control_and_label_from_image_comments():
    metadata = {
        "NumberOfVolumesIn4D": 4,
        "ImageComments": "volume types: control, label",
    }

    assert module.generate_context(metadata) == [
        "control",
        "label",
        "control",
        "label",
    ]


def test_generate_context_reads_explicit_comment_sequence():
    metadata = {
        "NumberOfVolumesIn4D": 3,
        "ImageComments": "m0_scan, control, label",
    }

    assert module.generate_context(metadata) == ["m0scan", "control", "label"]


def test_generate_context_rejects_guessing_without_labels():
    with pytest.raises(ValueError, match="provide --pattern"):
        module.generate_context({"NumberOfVolumesIn4D": 2})


def test_generate_context_rejects_mismatched_metadata():
    with pytest.raises(ValueError, match="contains 2 volume labels"):
        module.generate_context(
            {"NumberOfVolumesIn4D": 3},
            volume_types=["control", "label"],
        )
