import tempfile
import unittest
from pathlib import Path

from workflow.scripts.rename_qmt_acquisitions import normalized_name, planned_renames


class RenameQmtAcquisitionsTest(unittest.TestCase):
    def test_normalizes_sequence_contrast_and_echo_count(self):
        path = Path(
            "sub-01_ses-1_acq-vibeMTmtw3ecosag1isoc9ND"
            "_echo-1_flip-14_mt-on_part-mag_MPM.json"
        )
        self.assertEqual(
            normalized_name(path).name,
            "sub-01_ses-1_acq-sag1isoc9ND"
            "_echo-1_flip-14_mt-on_part-mag_MPM.json",
        )

    def test_normalizes_nifti_and_json_consistently(self):
        names = [
            "sub-01_ses-1_acq-vibeMTmtw3ecosag1isoc9"
            "_echo-1_flip-14_mt-on_part-mag_MPM.json",
            "sub-01_ses-1_acq-vibeMTmtw3ecosag1isoc9"
            "_echo-1_flip-14_mt-on_part-mag_MPM.nii.gz",
        ]
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            for name in names:
                (root / name).touch()

            renames = planned_renames(root)

            self.assertEqual(
                {destination.name for _, destination in renames},
                {
                    "sub-01_ses-1_acq-sag1isoc9"
                    "_echo-1_flip-1_mt-on_part-mag_MPM.json",
                    "sub-01_ses-1_acq-sag1isoc9"
                    "_echo-1_flip-1_mt-on_part-mag_MPM.nii.gz",
                },
            )

    def test_preserves_rec_entity_in_qmt_acquisition(self):
        path = Path(
            "sub-01_ses-1_acq-vibeMTmtw3ecosag1isoc9_rec-nd"
            "_echo-1_flip-14_mt-on_part-mag_MPM.json"
        )

        self.assertEqual(
            normalized_name(path).name,
            "sub-01_ses-1_acq-sag1isoc9_rec-nd"
            "_echo-1_flip-14_mt-on_part-mag_MPM.json",
        )

    def test_orders_flip_labels_from_t1w_to_pdw(self):
        names = [
            "sub-01_ses-1_acq-vibeMTt1w3ecosag1isoc9"
            "_echo-1_flip-33_mt-off_part-mag_MPM.json",
            "sub-01_ses-1_acq-vibeMTmtw3ecosag1isoc9"
            "_echo-1_flip-14_mt-on_part-mag_MPM.json",
            "sub-01_ses-1_acq-vibeMTpdw6ecosag1isoc9"
            "_echo-1_flip-6_mt-off_part-mag_MPM.json",
        ]
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            for name in names:
                (root / name).touch()

            renames = planned_renames(root)
            destinations = {destination.name for _, destination in renames}

            self.assertIn(
                "sub-01_ses-1_acq-sag1isoc9_echo-1_flip-1_mt-off_part-mag_MPM.json",
                destinations,
            )
            self.assertIn(
                "sub-01_ses-1_acq-sag1isoc9_echo-1_flip-2_mt-on_part-mag_MPM.json",
                destinations,
            )
            self.assertIn(
                "sub-01_ses-1_acq-sag1isoc9_echo-1_flip-3_mt-off_part-mag_MPM.json",
                destinations,
            )

    def test_rejects_collisions(self):
        names = [
            "sub-01_ses-1_acq-vibeMTmtw3ecosag1isoc9"
            "_echo-1_flip-14_mt-on_part-mag_MPM.json",
            "sub-01_ses-1_acq-othermtw3ecosag1isoc9"
            "_echo-1_flip-14_mt-on_part-mag_MPM.json",
        ]
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            for name in names:
                (root / name).touch()

            with self.assertRaises(ValueError):
                planned_renames(root)

    def test_allows_existing_destination_that_is_also_a_source(self):
        names = [
            "sub-01_ses-1_acq-vibeMTt1w3ecosag1isoc9"
            "_echo-1_flip-33_mt-off_part-mag_MPM.json",
            "sub-01_ses-1_acq-vibeMTmtw3ecosag1isoc9"
            "_echo-1_flip-14_mt-on_part-mag_MPM.json",
            "sub-01_ses-1_acq-vibeMTpdw6ecosag1isoc9"
            "_echo-1_flip-6_mt-off_part-mag_MPM.json",
        ]
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            for name in names:
                (root / name).touch()

            renames = planned_renames(root)

            self.assertEqual(len(renames), len(names))


if __name__ == "__main__":
    unittest.main()
