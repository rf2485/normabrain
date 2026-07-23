# Welcome to the NormaBRAIN Pipeline!

While this pipeline was designed for use with the NormaBRAIN protocol for Aix Marseille Univ at 3T and 7T, it is flexible enough to be used with any Siemens dataset which includes all or some of the modalities implemented. The NormaBRAIN pipeline automatically organizes and symlinks the input DICOMS by field strength, and then generates a BIDS database for each field strength. It then automatically determines which modalities are available for each subject and session, and runs the appropriate pre-processing modules. It's flexible enough to use during protocol development: scans of the same modality with differing acquisition parameters are saved and processed separately. Parameters for each scan are automatically read from the DICOM headers and scanner protocol XMLs. Give it a try with your dataset!

# Installation

This repository utilizes git submodules. To clone, use the command ```git clone --recurse-submodules project_url```

Requires: python3, conda, singularity, bash


Once the repository is cloned, it can be installed with the command ```conda env create -f workflow/envs/snakemake.yaml```. To use the pipeline, first activate the environment with ```conda activate snakemake```.

If installation from snakemake.yaml leads to conflicts, try running ```conda config --set channel_priority flexible``` first.

Some freesurfer tools require a freesurfer license. You can obtain a freesurfer license from https://surfer.nmr.mgh.harvard.edu/registration.html. Once you have obtained a license, save it to ```.snakemake/scripts/.license```

ihMT MoCo also requires a license agreement. Please sign the license agreement and download the code at https://crmbm.univ-amu.fr/resources/ihmt-moco/. Once you have obtained the code, save it to ```.snakemake/scripts/ihMT_MoCo.sh```


The first time the pipeline runs, all required singularity images and conda environments are constructed. This requires an internet connection. If Spinal Cord Toolbox is not present on the system, it is installed via the qMT.smk rule install_sct. 

Note: the Dockerfile used for ihMT MoCo, along with the conda environment yaml copied to the Docker container, is documented in ```workflow/envs/ihmt_moco/```. The dockerfile used for MP2PROC is documented in the submodule ```workflow/scripts/MP2PRoc```. The pipeline pulls these environments from Dockerhub user rflaherty3636 and converts them to singularity images using the same procedure as the other singularity images.

# Useage

Note that the first time you run the pipeline on your system will be slower, as the associated conda and singularity environments must be downloaded and constructed. 

In the same folder as the repository, run ```bash run_workflow.bash [OPTIONS]```. This will generate and run a snakemake command. To run the whole pipeline on all subjects using all available cores, run ```bash run_workflow.bash -i [path/to/DICOMS/folder] --protocol_path [path/to/protocol/xmls/folder] --all```.  Run ```bash run_workflow.bash -h``` for more information on required and optional flags, including GPU implementation and changing the default memory limits.

DICOMS are symlinked to ```data/rawdata/dicoms``` and BIDS repositories for each field strength are generated in ```data/rawdata/bids```. All analyses and intermediate files are saved to ```data/derivatives```. 

Users who wish to have more control over snakemake or output files can instead create their own snakemake commands. See https://snakemake.readthedocs.io/en/stable/ for documentation. This includes settings for working with SLURM and other cluster resource schedulers. Note that the BIDS repositories must be generated separately first for other modules to function (including BIDS generation completion as a requirement for rules in other modules will result in every subject being re-run whenever a new subject is added).
 
The template bidsmap used to organize raw DICOMS into BIDS can be edited at ```config/bidsmap_normabrain_template.yaml```. The dictionary for saving paramters from the Siemens CSA header ("private header") to json metadata for each scan is in ```scripts/add_csa_data_to_meta.py```.

Calling snakemake without a target rule or file, or running run_workflow.bash with the --all flag, will run the whole pipeline on all subjects as defined by "rule all" in ```workflow/Snakefile```. If you wish to only run a single subject or sub-pipeline, place the name of the target file at the end of your snakemake command. For example, to generate freesurfer segmentation and mean ROI statistics for just the ihMT LoSar acquisition for subject 002 session 1 at 3T, run ```snakemake --resources mem_mb=9300 --sdm conda apptainer --cores 8 "data/derivatives/3T/freesurfer/sub-002_ses-1_acq-ihMTLoSar/stats/ihmt_stats.done"```. Snakemake will automatically also run the required MP2RAGE and B1map modules, along with the ihMT module, for this field strength/subject/session/acquistion to generate the segmentations. You may direct snakemake to target any rules or output files defined in the smk files in ```workflow/rules```.
