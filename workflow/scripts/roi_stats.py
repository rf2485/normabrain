# Original functions by Anita Masliah, Aix Marseille Univ, CNRS, CRMBM, Marseille, France
# Edited for use as a bash CLI by Ryn Flaherty, PhD, Aix Marseille Univ, CNRS, CRMBM, Marseille, France

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

def ROI_dict(ROI_lookuptable_filepath):
    """
    Read csv, tsv, or ASCII lookup tables where the first column is the ROI index and the second column is the ROI name.
    Lookup tables are paired with segmentations.
    """
    lut_path = Path(ROI_lookuptable_filepath)
    try: #try first to read the file, use the python engine to decide the format automatically (tsv or csv). Works for MNI.
        roi_df = pd.read_csv(lut_path, header=None, sep=None, engine='python')
    except: #if pd.read_csv doesn't work, use np.genfromtxt to extract first two columns. FreeSurfer LUTs need this.
        roi_df = pd.DataFrame(np.genfromtxt(lut_path, dtype=None, encoding=None, usecols=(0,1)))
    roi_dict = dict(zip(roi_df.iloc[:,1], roi_df.iloc[:,0]))
    return roi_dict

def ROI_stats(data_filepath, seg_filepath, ROI_lookuptable_filepath, output_directory, field_strength, modality, subject, session, acq, contrast, remove_outliers=False):
    """
    Main function for generating the statistics dataframe and saving to pickle.
    """
    # Load quantitative map and associated segmentation 
    n_map = nib.load(data_filepath) # map
    n_seg = nib.load(seg_filepath) # segmentation
    seg_name =  Path(ROI_lookuptable_filepath).with_suffix('').stem.replace("_lut", "")

    a_map = n_map.get_fdata().astype(np.float32)
    a_seg = n_seg.get_fdata().astype(np.uint16)

    ROI_ids = ROI_dict(ROI_lookuptable_filepath)
    # Get list of ROI names and labels from ROI_ids
    ROI_names=list(ROI_ids.keys()) # List of ROI names
    indices=list(ROI_ids.values()) # List of associated (numeric) indices

    # # Dictionnaries initialization
    l_region    = list()
    l_data      = list()
    l_mean      = list()
    l_sd        = list()
    l_se        = list()
    l_med       = list()
    l_q1        = list()
    l_q3        = list()
    l_iqr        = list()
    l_qcd        = list()
    l_skew      = list()
    l_kurt      = list()

    print("Extracting ROI values and statistics calculation ...")
    for n, index in tqdm(enumerate(indices)):

        if index in a_seg: #if the segmentation includes the ROI index as defined in the lookup table, make a mask of this ROI
            mask = np.isin(a_seg, index)  
        else: #otherwise skip the rest of the code in the loop and move on to the next index
            continue
        data = a_map[mask] # Add masked data to a dictionnary also associated with its ROI name.
        data = data[data != 0]

        if remove_outliers == True: 
            data = filter_outliers(data)
        else:
            data = data

        #append to dictionaries
        l_region.append(ROI_names[n]) 
        l_data.append(data.tolist())
        l_mean.append(np.mean(data))
        l_sd.append(np.std(data))
        l_se.append(stats.sem(data))
        l_med.append(np.median(data))
        l_q1.append(np.quantile(data, 0.25))
        l_q3.append(np.quantile(data, 0.75))
        l_iqr.append(np.quantile(data, 0.75) - np.quantile(data, 0.25))
        l_qcd.append(100*(np.quantile(data, 0.75) - np.quantile(data, 0.25))/(np.quantile(data, 0.75) + np.quantile(data, 0.25)))
        l_skew.append(stats.skew(data))
        l_kurt.append(stats.kurtosis(data))

    # create df with stats using dictionaries
    df_stats = pd.DataFrame(
        {
            'subject': [subject] * len(l_kurt),
            'session': [session] * len(l_kurt),
            'field_strength': [field_strength] * len(l_kurt),
            'modality': [modality] * len(l_kurt),
            'acquisition': [acq] * len(l_kurt),
            'segmentation': [seg_name] * len(l_kurt),
            'contrast': [contrast] * len(l_kurt),
            'outliers_removed': [remove_outliers] * len(l_kurt),
            'region': l_region,
            'data': l_data,
            'mean': l_mean,
            'sd': l_sd,
            'se': l_se,
            'median': l_med,
            'q1': l_q1,
            'q3': l_q3,
            'iqr': l_iqr,
            'qcd': l_qcd,
            'skew': l_skew,
            'kurt': l_kurt,
        }
    )

    #save to pickle
    outdir = Path(output_directory) #convert output directory from str to path to enable filename concatenation
    if remove_outliers == True:
        #save without including pandas index in the first column (avoids confusing this with ROI index from the LUT)
        df_stats.to_pickle(outdir / f"sub-{subject}_ses-{session}_acq-{acq}_seg-{seg_name}_ctr-{contrast}_nooutliers_stats.pickle" )
    else:
        df_stats.to_pickle(outdir / f"sub-{subject}_ses-{session}_acq-{acq}_seg-{seg_name}_ctr-{contrast}_stats.pickle" )


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
    parser.add_argument('seg_filepath', type=str, help="Filepath for the segmentation file to be applied to quantitative MRI maps (must be .nii.gz or mgz file). e.g. '/home/Documents/segmentation.nii.gz'")
    parser.add_argument('ROI_lookuptable_filepath', type=str, help="Filepath for an ASCII, pickle, or tsv file where the first column corresponds to the ROI index and the second column corresponds to the ROI name.")
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
        ROI_stats(args.data_filepath, args.seg_filepath, args.ROI_lookuptable_filepath, args.output_directory, args.field_strength, args.modality, args.subject, args.session, args.acquisition, args.contrast, remove_outliers=True)
    else:
        ROI_stats(args.data_filepath, args.seg_filepath, args.ROI_lookuptable_filepath, args.output_directory, args.field_strength, args.modality, args.subject, args.session, args.acquisition, args.contrast, remove_outliers=False)
