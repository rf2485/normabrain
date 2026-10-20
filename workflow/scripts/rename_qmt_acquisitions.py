"""Normalize qMT BIDS acquisition labels to acquisition parameters only."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


QMT_ACQUISITION = re.compile(
    r"(?P<prefix>.*_acq-)"
    r"(?P<sequence>.+?)"
    r"(?P<contrast>mt0|mtw|pdw|t1w)"
    r"(?P<echoes>\d+eco)"
    r"(?P<parameters>[^_]+)"
    r"(?P<rec>_rec-[^_]+)?"
    r"(?P<suffix>_echo-.*_MPM(?:\.json|\.nii\.gz))$"
)


def normalized_name(path: Path) -> Path | None:
    """Return the normalized path, or None when the file is not a qMT MPM file."""
    match = QMT_ACQUISITION.fullmatch(path.name)
    if match is None:
        if (
            re.search(r"_flip-\d+(?:\.\d+)?_", path.name)
            and "_MPM." in path.name
            and path.name.endswith((".json", ".nii.gz"))
        ):
            return path
        return None

    parameters = re.sub(r"[^A-Za-z0-9]+", "", match["parameters"])
    if not parameters:
        raise ValueError(f"Could not derive acquisition parameters from {path}")

    return path.with_name(
        f"{match['prefix']}{parameters}{match['rec'] or ''}{match['suffix']}"
    )


def flip_angle(path: Path) -> float | None:
    """Return the physical flip angle encoded in a qMT filename."""
    match = re.search(r"_flip-(?P<flip>\d+(?:\.\d+)?)_", path.name)
    return None if match is None else float(match["flip"])


def with_flip_label(path: Path, label: str) -> Path:
    """Replace a physical qMT flip angle in a normalized filename."""
    return path.with_name(
        re.sub(r"_flip-\d+(?:\.\d+)?_", f"_{label}_", path.name)
    )


def planned_renames(bids_root: Path) -> list[tuple[Path, Path]]:
    """Build and validate the complete qMT rename plan."""
    candidates: list[tuple[Path, Path, float]] = []
    for path in sorted(bids_root.rglob("*")):
        if not path.is_file():
            continue
        destination = normalized_name(path)
        physical_flip = flip_angle(path)
        if destination is None or physical_flip is None:
            continue
        candidates.append((path, destination, physical_flip))

    flip_groups: dict[str, set[float]] = {}
    for path, destination, physical_flip in candidates:
        group = str(destination.with_name(
            re.sub(r"_echo-.*$", "", destination.name)
        ))
        flip_groups.setdefault(group, set()).add(physical_flip)

    labels = {
        group: {
            value: f"flip-{index}"
            for index, value in enumerate(sorted(values, reverse=True), start=1)
        }
        for group, values in flip_groups.items()
    }

    renames: list[tuple[Path, Path]] = []
    destinations: dict[Path, Path] = {}
    source_paths = {path for path, _, _ in candidates}

    for path, normalized, physical_flip in candidates:
        group = str(normalized.with_name(
            re.sub(r"_echo-.*$", "", normalized.name)
        ))
        destination = with_flip_label(
            normalized, labels[group][physical_flip]
        )
        if destination == path:
            continue

        previous = destinations.get(destination)
        if previous is not None:
            raise ValueError(
                f"Multiple files would be renamed to {destination}: "
                f"{previous} and {path}"
            )
        destinations[destination] = path
        if destination.exists() and destination not in source_paths:
            raise FileExistsError(
                f"Refusing to overwrite existing file {destination} "
                f"while renaming {path}"
            )
        renames.append((path, destination))

    return renames


def apply_renames(renames: list[tuple[Path, Path]]) -> None:
    """Apply a validated rename plan through temporary names."""
    temporary: list[tuple[Path, Path]] = []
    for index, (source, destination) in enumerate(renames):
        temporary_path = source.with_name(f".qmt-rename-{index}-{source.name}")
        source.rename(temporary_path)
        temporary.append((temporary_path, destination))

    for source, destination in temporary:
        source.rename(destination)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Remove qMT sequence, contrast, and echo-count tokens from "
            "BIDS acq labels."
        )
    )
    parser.add_argument(
        "bids_root",
        type=Path,
        help="BIDS field-strength directory, for example data/rawdata/bids/3T",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the rename plan without changing files.",
    )
    args = parser.parse_args()

    if not args.bids_root.is_dir():
        parser.error(f"BIDS root does not exist or is not a directory: {args.bids_root}")

    renames = planned_renames(args.bids_root)
    for source, destination in renames:
        print(f"{source} -> {destination}")

    if not args.dry_run:
        apply_renames(renames)
    print(f"{'Planned' if args.dry_run else 'Renamed'} {len(renames)} files")


if __name__ == "__main__":
    main()
