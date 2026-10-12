from dipy.core.gradients import gradient_table
from dipy.data import get_fnames
from dipy.io.gradients import read_bvals_bvecs
from dipy.io.image import load_nifti, save_nifti
import dipy.reconst.dki as dki
from dipy.reconst.weights_method import simple_cutoff, weights_method_wls_m_est

import argparse
import numpy as np
from pathlib import Path

def dki_tensor(preproc_nii: str, mask_nii: str, outprefix: str):
    #load the preprocessed dwi nii
    print("loading data...")
    data, affine = load_nifti(preproc_nii)
    #load bval and bvec files
    bval_path = Path(preproc_nii).with_suffix("").with_suffix(".bval")
    bvec_path = Path(preproc_nii).with_suffix("").with_suffix(".bvec")
    bvals, bvecs = read_bvals_bvecs(bval_path, bvec_path)
    # #scale bvals for constrained fitting
    # bvals = bvals * 0.001 #s/m^2 instead of usual s/mm^2
    #convert bvals and bvecs into GradientTable object needed for dipy data recon
    gtab = gradient_table(bvals, bvecs=bvecs)
    #only use bvalues less than or equal to 2500 to fit the kurtosis tensor
    bval_select = np.zeros_like(gtab.bvals)
    bval_select[bvals <= 2500] = 1
    data = data[..., bval_select == 1]
    gtab = gradient_table(bvals[bval_select == 1], bvecs=bvecs[bval_select == 1])
    #load the mask
    mask, affine = load_nifti(mask_nii)

    print("fitting the model...")
    #define the model and fitting method
    dkimodel = dki.DiffusionKurtosisModel(gtab, fit_method="RWLS", num_iter=6)
    #fit the model
    dkifit = dkimodel.fit(data, mask=mask)

    #save maps calculated from the DKI tensor
    print("saving the maps...")
    array_maps = ['fa', 'color_fa', 'md', 'rd', 'ad', 'kfa'] #attributes return an array
    func_maps = ['mk', 'rk', 'ak', 'mkt', 'rtk'] #attributes return a function, which returns an array
    for m in array_maps:
        print("   saving " + m + "...")
        save_nifti(outprefix + m + ".nii.gz", getattr(dkifit, m), affine)
    for m in func_maps: #use () after getattr to call function to generate array
        print("   saving " + m + "...")
        save_nifti(outprefix + m + ".nii.gz", getattr(dkifit, m)(), affine)
    print("done!")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        """
        Fit unconstrained DKI models with iterative robust weighted least squares as described in Coveney et al. 2025 and version 1.12.0 of the DIPY DKI tutorial.
        """)
    parser.add_argument('preproc_nii', type=str, help="Path to preprocessed DWIs")
    parser.add_argument('mask_nii', type=str, help="Path to mask")
    parser.add_argument('outprefix', type=str, help="Prefix for output images. Relative to current working directory.")
    args = parser.parse_args()
    dki_tensor(args.preproc_nii, args.mask_nii, args.outprefix)
