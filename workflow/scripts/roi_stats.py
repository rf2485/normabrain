# Original function by Anita Masliah, Aix Marseille Univ, CNRS, CRMBM, Marseille, France
# Edited for use as a bash CLI by Ryn Flaherty, PhD, Aix Marseille Univ, CNRS, CRMBM, Marseille, France

import numpy as np
import nibabel as nib
import nibabel.processing as nibp
import pandas as pd
import scipy.stats as stats
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

def ROI_stats(data_filepath, seg_filepath, ROI_ids, subject, session, acq, filter_on_off):
    """
    Calculate statistics for a quantitative map based on its segmentation. 
    Stats are returned in a pandas dataframe in order to facilitate plots.

    Inputs:
    - data_filepath (str):  quantitative map filepath (must be .nii.gz file) . e.g. "/home/Documents/T1map_grappa2.nii.gz"
    - seg_filepath (str): Filepath for the segmentation file to be applied to quantitative MRI maps (must be .nii.gz or mgz file). e.g. "/home/Documents/segmentation.nii.gz"
    - ROI_ids (dict): Contains names of ROIs as keys and their ids in a list as values. e.g., {"thalamus": [10, 49], "wm": [2, 41]}.
    
    Outputs:
    - df_stat (pandas.DataFrame): Contains name, mean, sd, median, q1, q2 as column, detailing statistics for ROIs.
    """

    # Load quantitative map and associated segmentation 
    n_map = nib.load(data_filepath) # map
    n_seg = nib.load(seg_filepath) # segmentation

    #n_map = nibp.resample_from_to(n_map, n_seg) # commented to get an error if not coregistered
    a_map = n_map.get_fdata().astype(np.float32)
    a_seg = n_seg.get_fdata().astype(np.uint16)

    # Get list of ROI names and labels from ROI_ids
    ROI_names=list(ROI_ids.keys()) # List of ROI names
    labels=list(ROI_ids.values()) # List of associated labels 

    # # Dictionnaries initialization
    # ROI_masks_dict=dict() # Key : ROI_name, Value : ROI_mask
    ROI_data_dict=dict() # Key : ROI_name, Value : map_masked
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
    for i, label in tqdm(enumerate(labels)):
        mask = np.isin(a_seg, label) # Extract mask for a ROI from your segmentation ( e.g. mask of "Thalamus" labelled by [10, 49]). 
        data = a_map[mask] # Add masked data to a dictionnary also associated with its ROI name.
        data = data[data != 0]

        if filter_on_off == "filter_on": 
            data = filter_outliers(data)
        else:
            data = data
        # create df with stats
        l_region.append(ROI_names[i])
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

    return pd.DataFrame(
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
            'session': [session] * len(labels),
            'subject': [subject] * len(labels),
            'study': [study] * len(labels),
        }
    )

