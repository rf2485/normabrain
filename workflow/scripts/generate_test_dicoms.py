#this is here to document how the test data was generated, mostly so that the author RF can find it later
#it was written in collaboration with whatever AI agent is embedded in google these days,
#because I refuse to give these companies any money but DICOMS are complicated
#requires a conda environment with pydicom 3.0.2, dicognito 0.19.0, pylibjpeg 2.1.0, and pylibjpeg-openjped 2.5.3:
# conda install -c conda-forge pydicom
# pip install dicognito pylibjpeg pylibjpeg-openjpeg
# conda install -c conda-forge numpy

import argparse
import os
import glob
import dicognito.anonymizer
import numpy as np
import pydicom
import SimpleITK as sitk



def _spatial_frame_index(ds, pixel_array):
    """Return the midpoint frame for an axial spatial multiframe stack."""
    frame_groups = getattr(ds, "PerFrameFunctionalGroupsSequence", None)
    if not frame_groups or len(frame_groups) != pixel_array.shape[0]:
        return None

    positions = []
    orientation = None
    shared_groups = getattr(ds, "SharedFunctionalGroupsSequence", None)
    if shared_groups:
        shared_orientation = getattr(shared_groups[0], "PlaneOrientationSequence", None)
        if shared_orientation:
            orientation = np.asarray(shared_orientation[0].ImageOrientationPatient, dtype=float)

    for frame_group in frame_groups:
        plane_position = getattr(frame_group, "PlanePositionSequence", None)
        if not plane_position:
            return None
        positions.append(np.asarray(plane_position[0].ImagePositionPatient, dtype=float))

        if orientation is None:
            frame_orientation = getattr(frame_group, "PlaneOrientationSequence", None)
            if frame_orientation:
                orientation = np.asarray(frame_orientation[0].ImageOrientationPatient, dtype=float)

    if orientation is None:
        return None

    row_direction, column_direction = orientation[:3], orientation[3:]
    slice_normal = np.cross(row_direction, column_direction)
    if np.argmax(np.abs(slice_normal)) != 2:
        return None

    positions_along_slice_normal = np.dot(np.asarray(positions), slice_normal)
    sorted_positions = np.sort(positions_along_slice_normal)

    if np.any(np.diff(sorted_positions) <= 1e-3):
        return None

    return int(np.argsort(positions_along_slice_normal)[len(positions) // 2])


def _crop_to_nonzero_bbox(ds, pixels):
    """Crop rows and columns around all nonzero pixels without changing frames."""
    spatial_pixels = pixels if pixels.ndim == 2 else pixels.reshape((-1,) + pixels.shape[-2:])
    nonzero = np.any(spatial_pixels != 0, axis=0)
    row_indices, column_indices = np.where(nonzero)
    if not len(row_indices):
        return pixels

    row_start, row_end = row_indices.min(), row_indices.max() + 1
    column_start, column_end = column_indices.min(), column_indices.max() + 1
    pixels = pixels[..., row_start:row_end, column_start:column_end]

    old_pixel_spacing = getattr(ds, "PixelSpacing", None)
    if old_pixel_spacing and len(old_pixel_spacing) >= 2:
        row_spacing = float(old_pixel_spacing[0])
        column_spacing = float(old_pixel_spacing[1])
        ds.PixelSpacing = [row_spacing, column_spacing]
        if "ImagePositionPatient" in ds:
            orientation = getattr(ds, "ImageOrientationPatient", None)
            if orientation and len(orientation) >= 6:
                row_direction = np.asarray(orientation[:3], dtype=float)
                column_direction = np.asarray(orientation[3:6], dtype=float)
                position = np.asarray(ds.ImagePositionPatient, dtype=float)
                ds.ImagePositionPatient = (
                    position
                    + row_start * row_spacing * row_direction
                    + column_start * column_spacing * column_direction
                ).tolist()

    ds.Rows = pixels.shape[-2]
    ds.Columns = pixels.shape[-1]
    return pixels


def _keep_single_frame(ds, pixels, frame_id):
    """Keep one spatial frame and its matching enhanced-DICOM metadata."""
    pixels = pixels[frame_id:frame_id + 1, ...]
    ds.NumberOfFrames = 1

    frame_groups = getattr(ds, "PerFrameFunctionalGroupsSequence", None)
    if frame_groups and len(frame_groups) > frame_id:
        ds.PerFrameFunctionalGroupsSequence = [frame_groups[frame_id]]

    return pixels


def robust_directory_slice_extractor(input_dir: str, output_dir: str):
    """
    Scans a directory, isolates a midpoint row cross-section by masking adjacent rows,
    anonymizes metadata and writes the output using the source DICOM transfer
    syntax.
    """
    if not os.path.isdir(input_dir):
        raise NotADirectoryError(f"Provided path '{input_dir}' is not a valid directory.")
        
    anonymizer = dicognito.anonymizer.Anonymizer()
    
    protected_physics_tags = [
        (0x0018, 0x9087), (0x0018, 0x9089), (0x0019, 0x100c), (0x0019, 0x100e), (0x0043, 0x1039), (0x2001, 0x1003), 
        (0x0018, 0x0081), (0x0018, 0x0082), (0x0018, 0x0080), 
        (0x0018, 0x9250), (0x0018, 0x9251), (0x0018, 0x9252), (0x0043, 0x107f), (0x0021, 0x105c)              
    ]

    all_files = glob.glob(os.path.join(input_dir, "*"))
    raw_records = []
    
    for f in all_files:
        try:
            ds_meta = pydicom.dcmread(f, stop_before_pixels=True)
            num_frames = int(getattr(ds_meta, "NumberOfFrames", 1))
            raw_records.append({
                "filename": f,
                "basename": os.path.basename(f),
                "frames": num_frames,
                "meta": ds_meta
            })
        except (pydicom.errors.InvalidDicomError, TypeError, ValueError):
            continue

    if not raw_records:
        raise ValueError(f"No valid DICOM datasets detected inside: {input_dir}")

    os.makedirs(output_dir, exist_ok=True)
    is_multiframe_series = any(r["frames"] > 1 for r in raw_records)

    # =========================================================================
    # ROUTE 1: Multi-Frame Volumes (3D Stacks or 4D Volumes)
    # =========================================================================
    if is_multiframe_series:
        print(f"🧊 Detected folder containing {len(raw_records)} multi-frame file(s).")
        
        for r in raw_records:
            ds = pydicom.dcmread(r["filename"])
            pixels = ds.pixel_array.copy()
            total_rows = ds.Rows
            target_frame_idx = _spatial_frame_index(ds, pixels)

            if target_frame_idx is None:
                target_frame_idx = pixels.shape[0] // 2
            print(f"  ↳ Keeping axial frame {target_frame_idx} in {r['basename']}")
            pixels = _keep_single_frame(ds, pixels, target_frame_idx)
                
            pixels = _crop_to_nonzero_bbox(ds, pixels)
            ds.PixelData = pixels.tobytes()
            
            # Save physics headers and anonymize names
            saved_tags = {tag: ds[tag] for tag in protected_physics_tags if tag in ds}
            anonymizer.anonymize(ds)
            for tag, elem in saved_tags.items():
                ds[tag] = elem
            
            ds.save_as(os.path.join(output_dir, r["basename"]))

    # =========================================================================
    # ROUTE 2: Folder of Disjoint 2D Files
    # =========================================================================
    else:
        print(f"📁 Found 2D Slice Series ({len(raw_records)} discrete files). Masking and cropping...")
        
        for r in raw_records:
            ds = pydicom.dcmread(r["filename"])
            pixels = ds.pixel_array.copy()
            total_rows = ds.Rows
            target_row_idx = total_rows // 4
            
            pixels[:target_row_idx, :] = 0
            pixels[target_row_idx+1:, :] = 0
            
            pixels = _crop_to_nonzero_bbox(ds, pixels)
            ds.PixelData = pixels.tobytes()
            
            saved_tags = {tag: ds[tag] for tag in protected_physics_tags if tag in ds}
            anonymizer.anonymize(ds)
            for tag, elem in saved_tags.items():
                ds[tag] = elem
                
            ds.save_as(os.path.join(output_dir, r["basename"]))
            print(f"  ↳ Preserved and anonymized: {r['basename']}")
            
    print(f"✅ Tiny, orientation-preserved GitHub test assets created inside: {output_dir}\n")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        """
        Scans a directory of DICOM files, determines if they are 2D or Multi-frame (3D/4D),
        and isolates the spatial midpoint slice across all dynamic contrasts.
        These single slices are then anonymized and saved to a new directory for use in unit tests.
        """)
    parser.add_argument("input_dir", type=str, help="Path to directory including original DICOMS from the scanner.")
    parser.add_argument("output_dir", type=str, help="Path to output directory for anonymized single slice DICOMS.")
    args = parser.parse_args()
    robust_directory_slice_extractor(args.input_dir, args.output_dir)