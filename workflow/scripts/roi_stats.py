# Original function by Anita Masliah, Aix Marseille Univ, CNRS, CRMBM, Marseille, France
# Edited for use as a bash CLI by Ryn Flaherty, PhD, Aix Marseille Univ, CNRS, CRMBM, Marseille, France

import argparse
import numpy as np
import nibabel as nib
import nibabel.processing as nibp
import pandas as pd
import scipy.stats as stats
from pathlib import Path
from tqdm import tqdm

def filter_outliers(array, threshold=3): # 99,7% si normale, aumoins 88,8% sinon (Bienaymé-Tchebychev)
    mean = np.mean(array)
    std_dev = np.std(array)

    # Calculer les bornes inférieure et supérieure
    lower_bound = mean - threshold * std_dev # regle 68; 95; 99,7
    upper_bound = mean + threshold * std_dev

    # Filtrer les valeurs dans l'intervalle spécifié
    filtered_array = array[(array >= lower_bound) & (array <= upper_bound)]

    return filtered_array

def ROI_dict(ROI_lookuptable_filepath):
    lut_path = Path(ROI_lookuptable_filepath)
    try:
        roi_df = pd.read_csv(lut_path, header=None, sep=None, engine='python')
    except:
        roi_df = pd.DataFrame(np.genfromtxt(lut_path, dtype=None, encoding=None, usecols=(0,1)))
    roi_dict = dict(zip(roi_df.iloc[:,1], roi_df.iloc[:,0]))
    return roi_dict

def ROI_stats(data_filepath, seg_filepath, ROI_lookuptable_filepath, output_directory, subject, session, acq, remove_outliers=False):
    """
    Calculate statistics for a quantitative map based on its segmentation. 
    Stats are returned in a pandas dataframe in order to facilitate plots.

    Inputs:
    - data_filepath (str):  quantitative map filepath (must be .nii.gz file) . e.g. "/home/Documents/T1map_grappa2.nii.gz"
    - seg_filepath (str): Filepath for the segmentation file to be applied to quantitative MRI maps (must be .nii.gz or mgz file). e.g. "/home/Documents/segmentation.nii.gz"
    - ROI_ids (str): ASCII, csv, or tsv file where the first column corresponds to the ROI index and the second column corresponds to the ROI label.
    
    Outputs:
    - df_stat (pandas.DataFrame): Contains name, mean, sd, median, q1, q2 as column, detailing statistics for ROIs.
    """

    # Load quantitative map and associated segmentation 
    n_map = nib.load(data_filepath) # map
    n_seg = nib.load(seg_filepath) # segmentation
    seg_name =  Path(seg_filepath).with_suffix('').stem.replace("_resliced", "")
    if remove_outliers == True:
        seg_name = seg_name + "_nooutliers"

    #n_map = nibp.resample_from_to(n_map, n_seg) # commented to get an error if not coregistered
    a_map = n_map.get_fdata().astype(np.float32)
    a_seg = n_seg.get_fdata().astype(np.uint16)

    ROI_ids = ROI_dict(ROI_lookuptable_filepath)
    # Get list of ROI names and labels from ROI_ids
    ROI_names=list(ROI_ids.keys()) # List of ROI names
    indices=list(ROI_ids.values()) # List of associated (numeric) indices

    # # Dictionnaries initialization
    # ROI_masks_dict=dict() # Key : ROI_name, Value : ROI_mask
    # ROI_data_dict=dict() # Key : ROI_name, Value : map_masked
    # df_stat=pd.DataFrame()

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
        # create df with stats
        l_region.append(ROI_names[n])
        l_data.append(data)
        l_mean.append(np.mean(data))
        l_sd.append(np.std(data))
        l_se.append(np.std(data)/np.sqrt(len(data)))
        l_med.append(np.median(data))
        l_q1.append(np.quantile(data, 0.25))
        l_q3.append(np.quantile(data, 0.75))
        l_iqr.append(np.quantile(data, 0.75) - np.quantile(data, 0.25))
        l_qcd.append(100*(np.quantile(data, 0.75) - np.quantile(data, 0.25))/(np.quantile(data, 0.75) + np.quantile(data, 0.25)))
        l_skew.append(stats.skew(data))
        l_kurt.append(stats.kurtosis(data))

    df_stats = pd.DataFrame(
        {
            'region': l_region,
            'data': l_data,
            'means': l_mean,
            'sd': l_sd,
            'se': l_se,
            'median': l_med,
            'q1': l_q1,
            'q3': l_q3,
            'iqr': l_iqr,
            'qcd': l_qcd,
            'skew': l_skew,
            'kurt': l_kurt,
            'session': [session] * len(l_kurt),
            'subject': [subject] * len(l_kurt),
            'acquisition': [acq] * len(l_kurt),
            'segmentation': seg_name * len(l_kurt)
        }
    )
    outdir = Path(output_directory)
    df_stats.to_pickle(outdir / f"sub-{subject}_ses-{session}_acq-{acq}_seg-{seg_name}_stats.pkl" )

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        """
        Calculate statistics for a quantitative map based on its segmentation. 
        Stats are saved to pkl files in the specified output directory, using the specified subject, session and acquisition in the filename and .
        """)
    parser.add_argument('data_filepath', type=str, help="quantitative map filepath (must be .nii.gz file) . e.g. '/home/Documents/T1map_grappa2.nii.gz'")
    parser.add_argument('seg_filepath', type=str, help="Filepath for the segmentation file to be applied to quantitative MRI maps (must be .nii.gz or mgz file). e.g. '/home/Documents/segmentation.nii.gz'")
    parser.add_argument('ROI_lookuptable_filepath', type=str, help="Filepath for an ASCII, csv, or tsv file where the first column corresponds to the ROI index and the second column corresponds to the ROI name.")
    parser.add_argument('output_directory', type=str, help="Filepath for the output directory")
    parser.add_argument('subject', type=str, help="Subject name, for use in file naming and as a column in the pkl file.")
    parser.add_argument('session', type=str, help="Session name, for use in file naming and as a column in the pkl file.")
    parser.add_argument('acquisition', type=str, help="Acquisition name, for use in file naming and as a column in the pkl file.")
    parser.add_argument('-r', '--remove_outliers', action="store_true", help="When flag is applied, remove outliers more than 3 standard deviations from the mean. Without this flag, data remains unfiltered.")
    args = parser.parse_args()
    if args.remove_outliers:
        ROI_stats(args.data_filepath, args.seg_filepath, args.ROI_lookuptable_filepath, args.output_directory, args.subject, args.session, args.acquisition, remove_outliers=True)
    else:
        ROI_stats(args.data_filepath, args.seg_filepath, args.ROI_lookuptable_filepath, args.output_directory, args.subject, args.session, args.acquisition, remove_outliers=False)
