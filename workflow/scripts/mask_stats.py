import argparse
import numpy as np
import nibabel as nib
import pandas as pd
import scipy.stats as stats
from pathlib import Path
from tqdm import tqdm

def filter_outliers(array, threshold=3): # 99.7% if normal, otherwise 88,8% if not (Bienaymé-Tchebychev)
    """
    Remove outliers outside of threshold * standard deviation (default is 3 standard deviations from the mean).
    """
    mean = np.mean(array)
    std_dev = np.std(array)

    # calculate the lower and upper bound
    lower_bound = mean - threshold * std_dev # 68; 95; 99.7
    upper_bound = mean + threshold * std_dev

    #Filter the values in the specified interval
    filtered_array = array[(array >= lower_bound) & (array <= upper_bound)]

    return filtered_array

def mask_stats(data_filepath, mask_filepath, mask_name, output_directory, field_strength, modality, subject, session, acq, contrast, remove_outliers=False):
    """
    Main function for generating the statistics dataframe and saving to pickle.
    """
    #load quantitative map and mask
    n_map = nib.load(data_filepath) # map
    n_mask = nib.load(mask_filepath) #mask

    a_map = n_map.get_fdata().astype(np.float32)
    a_mask = n_mask.get_fdata().astype(bool)

    data = a_map[a_mask] #mask data
    data = data[data != 0] #exclude 0s
    data = data[np.isfinite(data)] #clean up NaNs and infinite values

    if remove_outliers == True: 
        data = filter_outliers(data)
    else:
        data = data

    df_stats = pd.DataFrame(
            {
                'subject': [subject],
                'session': [session],
                'field_strength': [field_strength],
                'modality': [modality],
                'acquisition': [acq],
                'segmentation': [mask_name],
                'contrast': [contrast],
                'outliers_removed': [remove_outliers],
                'region': [mask_name],
                'data': [data],
                'mean': [np.mean(data)],
                'sd': [np.std(data)],
                'se': [stats.sem(data)],
                'median': [np.median(data)],
                'q1': [np.quantile(data, 0.25)],
                'q3': [np.quantile(data, 0.75)],
                'iqr': [np.quantile(data, 0.75) - np.quantile(data, 0.25)],
                'qcd': [100*(np.quantile(data, 0.75) - np.quantile(data, 0.25))/(np.quantile(data, 0.75) + np.quantile(data, 0.25))],
                'skew': [stats.skew(data)],
                'kurt': [stats.kurtosis(data)],
            }
        )
    
    #save to pickle
    outdir = Path(output_directory) #convert output directory from str to path to enable filename concatenation
    if remove_outliers == True:
        #save without including pandas index in the first column (avoids confusing this with ROI index from the LUT)
        df_stats.to_pickle(outdir / f"sub-{subject}_ses-{session}_acq-{acq}_mask-{mask_name}_ctr-{contrast}_nooutliers_stats.pickle" )
    else:
        df_stats.to_pickle(outdir / f"sub-{subject}_ses-{session}_acq-{acq}_mask-{mask_name}_ctr-{contrast}_stats.pickle" )

#build the CLI
if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        """
        Calculate statistics for a quantitative map based on its segmentation. 
        Stats are saved to pickle files in the specified output directory, using the specified subject, session, acquisition, and contrast in the filename.
        The name of the segmentation is also derived from the seg_filepath and saved in the filename.
        Subject, session, acquisition, contrast, and segmentation are also saved as columns in the pickle, for ease of concatenating files later.
        """)
    #CLI required positional arguments
    parser.add_argument('data_filepath', type=str, help="quantitative map filepath (must be .nii.gz file) . e.g. '/home/Documents/T1map_grappa2.nii.gz'")
    parser.add_argument('mask_filepath', type=str, help="Filepath for the mask to be applied to quantitative MRI maps (must be .nii.gz or mgz file). e.g. '/home/Documents/brain_mask.nii.gz'")
    parser.add_argument('mask_name', type=str, help="Mask name, i.e. brain_mask. For use in file naming and as a column in the pickle file.")
    parser.add_argument('output_directory', type=str, help="Filepath for the output directory")
    parser.add_argument('field_strength', type=str, help="Field strength, i.e. 3T, 7T, etc. For use in file naming and as a column in the pickle file.")
    parser.add_argument('modality', type=str, help="Modality name, i.e. ihMT, DWI, etc. For use in file naming and as a column in the pickle file.")
    parser.add_argument('subject', type=str, help="Subject name, for use in file naming and as a column in the pickle file.")
    parser.add_argument('session', type=str, help="Session name, for use in file naming and as a column in the pickle file.")
    parser.add_argument('acquisition', type=str, help="Acquisition name, for use in file naming and as a column in the pickle file.")
    parser.add_argument('contrast', type=str, help="Image contrast name (i.e. T1map, FA, etc.), for use in file naming and as a column in the pickle file.")
    #action="store_true" makes this flag boolean (args.remove_outliers is True when flag is called, False otherwise)
    #CLI optional flag argument
    parser.add_argument('-r', '--remove_outliers', action="store_true", help="When flag is applied, remove outliers more than 3 standard deviations from the mean. Without this flag, data remains unfiltered.")
    args = parser.parse_args()
    if args.remove_outliers:
        mask_stats(args.data_filepath, args.mask_filepath, args.mask_name, args.output_directory, args.field_strength, args.modality, args.subject, args.session, args.acquisition, args.contrast, remove_outliers=True)
    else:
        mask_stats(args.data_filepath, args.mask_filepath, args.mask_name, args.output_directory, args.field_strength, args.modality, args.subject, args.session, args.acquisition, args.contrast, remove_outliers=False)
