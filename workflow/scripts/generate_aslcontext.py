#!/usr/bin/env python3
"""Generate a BIDS ASL context TSV from sidecar or protocol metadata."""

from __future__ import annotations

import argparse
import csv
import json
import re
from pathlib import Path
from typing import Any, Sequence

import nibabel as nib

VALID_VOLUME_TYPES = {"control", "label", "m0scan", "noise"}
CONTEXT_KEYS = ("ASLContext", "aslcontext", "volume_type", "VolumeType")


def _as_volume_list(value: Any) -> list[str] | None:
    if isinstance(value, list) and all(isinstance(item, str) for item in value):
        return value
    if isinstance(value, dict):
        for key in ("volume_type", "VolumeType", "volumes", "values"):
            result = _as_volume_list(value.get(key))
            if result is not None:
                return result
    return None


def _validate_volume_types(volume_types: Sequence[str]) -> list[str]:
    normalized = [value.strip().lower() for value in volume_types]
    invalid = sorted(set(normalized) - VALID_VOLUME_TYPES)
    if invalid:
        allowed = ", ".join(sorted(VALID_VOLUME_TYPES))
        raise ValueError(
            f"Unsupported ASL volume type(s): {', '.join(invalid)}; "
            f"expected one of: {allowed}"
        )
    if not normalized:
        raise ValueError("At least one ASL volume type is required")
    return normalized


def _metadata_volume_types(metadata: dict[str, Any]) -> list[str] | None:
    for key in CONTEXT_KEYS:
        result = _as_volume_list(metadata.get(key))
        if result is not None:
            return result
    return None


def _volume_count(metadata: dict[str, Any], nifti: Path | None = None) -> int | None:
    for key in ("NumberOfVolumesIn4D", "NumberOfVolumes", "Volumes"):
        value = metadata.get(key)
        if isinstance(value, int) and value > 0:
            return value
    if nifti is not None:
        shape = nib.load(nifti).shape
        if len(shape) < 4:
            return 1
        return shape[3]
    return None


def _expand_pattern(pattern: Sequence[str], count: int) -> list[str]:
    if not pattern:
        raise ValueError("The ASL pattern must contain at least one volume type")
    if count <= 0:
        raise ValueError("The number of ASL volumes must be positive")
    return [pattern[index % len(pattern)] for index in range(count)]


def _metadata_pattern(metadata: dict[str, Any], count: int) -> list[str] | None:
    comments = metadata.get("ImageComments", "")
    if not isinstance(comments, str):
        return None

    tokens = re.findall(
        r"\b(control|label|m0[\s_-]*scan)\b", comments, flags=re.IGNORECASE
    )
    tokens = [
        "m0scan" if token.lower().replace("_", "").replace("-", "").replace(" ", "") == "m0scan"
        else token.lower()
        for token in tokens
    ]
    if len(tokens) == count:
        return tokens
    if "m0scan" in tokens and count > 1 and count % 2 == 1:
        return ["m0scan", "control", "label"]
    if {"control", "label"}.issubset(tokens):
        return ["control", "label"]
    return None


def generate_context(
    metadata: dict[str, Any],
    *,
    volume_types: Sequence[str] | None = None,
    pattern: Sequence[str] | None = None,
    m0_indexes: set[int] | None = None,
    nifti: Path | None = None,
) -> list[str]:
    """Return one validated BIDS volume_type value for each ASL volume."""
    count = _volume_count(metadata, nifti)
    if volume_types is None:
        volume_types = _metadata_volume_types(metadata)

    if volume_types is not None:
        result = _validate_volume_types(volume_types)
        if count is not None and len(result) != count:
            raise ValueError(
                f"ASL metadata contains {len(result)} volume labels, "
                f"but reports {count} volumes"
            )
    else:
        if count is None:
            raise ValueError(
                "Cannot determine the number of ASL volumes; provide "
                "a NIfTI input, NumberOfVolumesIn4D in the JSON, or "
                "--volume-types"
            )
        if pattern is None:
            pattern = _metadata_pattern(metadata, count)
        if pattern is None:
            raise ValueError(
                "No per-volume ASL labels were found; provide --pattern "
                "or --volume-types instead of guessing the ordering"
            )
        if pattern[0].strip().lower() == "m0scan":
            result = ["m0scan"] + _validate_volume_types(
                _expand_pattern(pattern[1:], count - 1)
            )
        else:
            result = _validate_volume_types(_expand_pattern(pattern, count))

    for index in m0_indexes or set():
        if index < 0 or index >= len(result):
            raise ValueError(
                f"M0 volume index {index} is outside the range "
                f"0..{len(result) - 1}"
            )
        result[index] = "m0scan"
    return result


def write_context(output: Path, volume_types: Sequence[str]) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        writer.writerow(["volume_type"])
        writer.writerows([[value] for value in volume_types])


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generate a BIDS *_aslcontext.tsv from an ASL JSON sidecar."
    )
    parser.add_argument("json_sidecar", type=Path, help="ASL JSON sidecar")
    parser.add_argument(
        "--nifti",
        type=Path,
        help="ASL NIfTI used to determine the number of volumes",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        help="Output TSV (default: replace the JSON suffix with _aslcontext.tsv)",
    )
    parser.add_argument(
        "--volume-types",
        help="Explicit comma-separated labels, one per volume",
    )
    parser.add_argument(
        "--pattern",
        help="Repeating comma-separated pattern, for example control,label",
    )
    parser.add_argument(
        "--m0-indexes",
        help="Zero-based comma-separated volume indexes to mark as m0scan",
    )
    return parser


def main() -> int:
    args = _parser().parse_args()
    try:
        with args.json_sidecar.open() as stream:
            metadata = json.load(stream)
        if not isinstance(metadata, dict):
            raise ValueError("The JSON sidecar must contain an object")

        explicit = (
            args.volume_types.split(",") if args.volume_types is not None else None
        )
        pattern = args.pattern.split(",") if args.pattern is not None else None
        m0_indexes = (
            {int(index) for index in args.m0_indexes.split(",")}
            if args.m0_indexes
            else set()
        )
        volume_types = generate_context(
            metadata,
            volume_types=explicit,
            pattern=pattern,
            m0_indexes=m0_indexes,
            nifti=args.nifti,
        )
        output = args.output or args.json_sidecar.with_name(
            f"{args.json_sidecar.stem.replace('_asl', '')}_aslcontext.tsv"
        )
        write_context(output, volume_types)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        raise SystemExit(f"error: {error}") from error
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
