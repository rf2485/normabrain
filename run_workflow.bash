#!/bin/bash

#default variable values
input_dicoms_path=""
protocol_path=""
subject_list_dicom="*"
qmt_sequence="vibeMT"
qmt_contrasts='mt0 mtw pdw t1w'
segmentations='aparc+aseg'
mem_mb=0
cores=0
all=false
bids=false
mp2rage=false
ihmt=false
qmt=false
dwi=false
qsm=false
reg_seg=false
use_gpu=false
dag=false
dry_run=false
config="config/snakemake_config.yaml"

trim_whitespace() {
    local value=$1

    value=${value#"${value%%[![:space:]]*}"}
    value=${value%"${value##*[![:space:]]}"}
    printf '%s' "$value"
}

load_config() {
    local config_file=$1
    local config_line
    local config_key
    local config_value

    while IFS= read -r config_line; do
        config_line=$(trim_whitespace "$config_line")

        case $config_line in
            ''|'#'*)
                continue
                ;;
        esac

        config_key=${config_line%%:*}
        config_value=${config_line#*:}

        config_key=$(trim_whitespace "$config_key")
        config_value=$(trim_whitespace "$config_value")
        config_value=${config_value%\"}
        config_value=${config_value#\"}
        config_value=${config_value%\'}
        config_value=${config_value#\'}

        case $config_key in
            input_dicoms_path)
                input_dicoms_path=$config_value
                ;;
            protocol_path)
                protocol_path=$config_value
                ;;
            subject_list_dicom)
                subject_list_dicom=$config_value
                ;;
            qmt_sequence)
                qmt_sequence=$config_value
                ;;
            qmt_contrasts)
                qmt_contrasts=$config_value
                ;;
            segmentations)
                segmentations=$config_value
                ;;
            
        esac
    done < "$config_file"
}

usage() { #function to display script help
    echo "Usage: bash $0 [OPTIONS]"
    echo "Options:"
    echo "-h, --help        Display this help message and exit."
    echo "REQUIRED flags ===="
    echo "-i, --input_dicoms_path   Path to the folder containing the input DICOMS. No default."
    echo "--protocol_path           Path to the folder containing the scanning protocol xml files. No default. Necessary for setting the MP2RAGE and ihMT echo spacing. If no xml files are found in the provided folder, sensible defaults for echo spacing are set."
    echo "--subject_list_dicom      Space-separated list of subject DICOM folder names to include in the analysis. The default is all subjects in the input folder."
    echo "--qmt_sequence            The base name of the qMT sequence used in the ProtocolName. The default is 'vibeMT'"
    echo "--qmt_contrasts           Space-separated list of contrasts collected for the qMT sequence as described in the ProtocolName. The default is 'mt0 mtw pdw t1w'"
    echo "--segmentations           Space-separated list of segmentations to apply for generating stats. Default is aparc+aseg from FreeSurfer."
    echo "--mem_mb                  Memory available for the pipeline, in MB. The default is min(max(2*input_size_mb, 1000), 8000) i.e. twice the input DICOMS folder size but no less than 1 GB and no more than 8 GB."
    echo "-c, --cores               CPU cores used for the pipeline. The default is all available CPU cores."
    echo "REQUIRED: Choose at least one of the below flags ===="
    echo "--all                     Run all modules of the pipeline."
    echo "--bids                    Run the bids module."
    echo "--mp2rage                 Run the MP2RAGE module."
    echo "--ihmt                    Run the ihMT module."
    echo "--qmt                     Run the qMT module."
    echo "--dwi                     Run the DWI module."
    echo "--qsm                     Run the QSM module."
    echo "--reg_seg                 Run the multimodal registration to MP2RAGE and segmentation module."
    echo "OPTIONAL flags ===="
    echo "-g, --gpu                 Use GPU." 
    echo "-d, --dag                 Produce DAG of pipeline instead of running the pipeline."
    echo "-n, --dry_run             Display what would be done without executing the pipeline."
    echo "--config                  Path to configuration file, from which command arguments may be read instead. The default is config/snakemake_config.yaml"       
}

has_argument() { #function from https://medium.com/@wujido20/handling-flags-in-bash-scripts-4b06b4d0ed04
    [[ "$1" == *=* && -n ${1#*=} || ! -z "$2" && "$2" != -* ]];
}

extract_argument() { #function from https://medium.com/@wujido20/handling-flags-in-bash-scripts-4b06b4d0ed04
  echo "${2:-${1#*=}}"
}

handle_options() { #function for handling options when this script is called
    while [ $# -gt 0 ]; do #while number of arguments to the script is greater than 0
        case $1 in
            -h | --help)
                usage
                exit 0
                ;;
            -i | --input_dicoms_path*)
                if ! has_argument \"$@\"; then
                    echo "ERROR: Input DICOMS folder not specified." >&2
                    exit 1
                fi

                input_dicoms_path=$(extract_argument \"$@\")

                shift
                ;;
            --protocol_path*)
                if ! has_argument \"$@\"; then
                    echo "ERROR: XML protocol folder not specified." >&2
                    exit 1
                fi

                protocol_path=$(extract_argument \"$@\")

                shift
                ;;
            --subject_list_dicom*)
                if ! has_argument \"$@\"; then
                    echo "ERROR: Subject list not specified." >&2
                    exit 1
                fi

                subject_list_dicom=$(extract_argument \"$@\")

                shift
                ;;
            --qmt_sequence*)
                if ! has_argument \"$@\"; then
                    echo "ERROR: qMT sequence not specified." >&2
                    exit 1
                fi

                qmt_sequence=$(extract_argument \"$@\")

                shift
                ;;
            --qmt_contrasts*)
                if ! has_argument \"$@\"; then
                    echo "ERROR: qMT contrasts not specified." >&2
                    exit 1
                fi

                qmt_contrasts=$(extract_argument \"$@\")

                shift
                ;;
            --segmentations*)
                if ! has_argument \"$@\"; then
                    echo "ERROR: segmentation(s) not specified." >&2
                    exit 1
                fi

                segmentations=$(extract_argument \"$@\")

                shift
                ;;
            --mem_mb*)
                if ! has_argument \"$@\"; then
                    echo "ERROR: Memory not specified." >&2
                    exit 1
                fi

                mem_mb=$(extract_argument \"$@\")

                shift
                ;;
            -c | --cores*)
                if ! has_argument \"$@\"; then
                    echo "ERROR: Cores not specified." >&2
                    exit 1
                fi

                cores=$(extract_argument \"$@\")

                shift
                ;;
            --all)
                all=true
                ;;
            --bids)
                bids=true
                ;;
            --mp2rage)
                mp2rage=true
                ;;
            --ihmt)
                ihmt=true
                ;;
            --qmt)
                qmt=true
                ;;
            --dwi)
                dwi=true
                ;;
            --qsm)
                qsm=true
                ;;
            --reg_seg)
                reg_seg=true
                ;;
            -g | --gpu)
                use_gpu=true
                ;;
            -d | --dag)
                dag=true
                ;;
            -n | --dry_run)
                dry_run=true
                ;;
            --config*)
                if ! has_argument \"$@\"; then
                    echo "ERROR: Path to configuration file not specified" >&2
                    exit 1
                fi

                config=$(extract_argument \"$@\")

                shift
                ;;
            *)
                echo "Invalid option: $1" >&2
                exit 1
                ;;
        esac
        shift
    done
}

handle_options "$@"

#config may override default variable values defined above
load_config "$config"

handle_options "$@"

#create command string based on arguments from flags in handle_options
config_args=(
    --config
    "input_dicoms_path=${input_dicoms_path}"
    "protocol_path=${protocol_path}"
    "subject_list_dicom=${subject_list_dicom}"
    "qmt_sequence=${qmt_sequence}"
    "qmt_contrasts=${qmt_contrasts}"
    "segmentations=${segmentations}"
)
config_string=" --config input_dicoms_path='${input_dicoms_path}' protocol_path='${protocol_path}' subject_list_dicom='${subject_list_dicom}' qmt_sequence='${qmt_sequence}' qmt_contrasts='${qmt_contrasts}' segmentations='${segmentations}'"
first_pass_args=(--sdm conda --rerun-incomplete)
first_pass_string=" --sdm conda --rerun-incomplete"
main_args=(--sdm conda apptainer --rerun-incomplete)
main_string=" --sdm conda apptainer --rerun-incomplete"
target_args=()
target_string=""
dag_mode=false

if [ "$all" = false ] && [ "$reg_seg" = false ] && [ "$bids" = false ] && [ "$mp2rage" = false ] && [ "$ihmt" = false ] && [ "$qmt" = false ] && [ "$dwi" = false ] && [ "$qsm" = false ]; then
    echo "ERROR: Invalid command. Must use at least one of --all --bids --mp2rage --ihmt --qmt --dwi --qsm --reg_seg" >&2
    exit 1
fi

if ! [ -n "$input_dicoms_path" ]; then
    echo "ERROR: Path to input DICOMS must be specified either via -i or --input_dicoms_path flags, or by setting input_dicoms_path in config/snakemake_config.yaml" >&2
    exit 1
fi

if ! [ -n "$protocol_path" ]; then
    echo "ERROR: Path to the folder containing the scanning protocol xml files must be specified either via --protocol_path flag, or by setting protocol_path in config/snakemake_config.yaml" >&2
    exit 1
fi

if ! [ -n "$subject_list_dicom" ]; then
    subject_list_dicom="*"
fi

if [ "$mem_mb" -eq 0 ]; then
    :
else
    main_args+=(--resources "mem_mb=${mem_mb}")
    main_string+=" --resources mem_mb=${mem_mb}"
fi

if [ "$cores" -eq 0 ]; then
    main_args+=(--cores all)
    main_string+=" --cores all"
    first_pass_args+=(--cores all)
    first_pass_string+=" --cores all"
else
    main_args+=(--cores "$cores")
    main_string+=" --cores ${cores}"
    first_pass_args+=(--cores "$cores")
    first_pass_string+=" --cores ${cores}"
fi

if [ "$reg_seg" = true ]; then #--reg_seg with no other flags functions the same as --all
    target_args=()
    target_string=""
fi

if [ "$bids" = true ]; then
    target_args+=(gather_add_csa_data_to_meta)
    target_string+=" gather_add_csa_data_to_meta"
fi

if [ "$mp2rage" = true ]; then
    target_args+=(aggregate_mp2rage)
    target_string+=" aggregate_mp2rage"
fi

if [ "$ihmt" = true ]; then
    target_args+=(aggregate_ihmt_maps)
    target_string+=" aggregate_ihmt_maps"
fi

if [ "$ihmt" = true ] && [ "$reg_seg" = true ]; then
    target_args+=(aggregate_multimodal_ihmt_mp2rage)
    target_string+=" aggregate_multimodal_ihmt_mp2rage"
fi

if [ "$qmt" = true ]; then
    target_args+=(aggregate_qMT)
    target_string+=" aggregate_qMT"
fi

if [ "$qmt" = true ] && [ "$reg_seg" = true ]; then
    target_args+=(aggregate_multimodal_qMT_mp2rage)
    target_string+=" aggregate_multimodal_qMT_mp2rage"
fi

if [ "$dwi" = true ]; then
    target_args+=(aggregate_dki)
    target_string+=" aggregate_dki"
fi

if [ "$dwi" = true ] && [ "$reg_seg" = true ]; then
    target_args+=(aggregate_multimodal_dwi_mp2rage)
    target_string+=" aggregate_multimodal_dwi_mp2rage"
fi

if [ "$qsm" = true ]; then
    target_args+=(aggregate_qsmxt)
    target_string+=" aggregate_qsmxt"
fi

if [ "$use_gpu" = true ]; then
    main_args+=(--singularity-args "--nv -e")
    main_string+=" --singularity-args '--nv -e'"
else
    main_args+=(--singularity-args " -e")
    main_string+=" --singularity-args ' -e'"
fi

#change most strings to blank if running dag
if [ "$dag" = true ]; then
    dag_mode=true
    main_args=()
    main_string=""
fi

if [ "$dry_run" = true ]; then
    main_args+=(--dry-run)
    main_string+=" --dry-run"
    first_pass_args+=(--dry-run)
    first_pass_string+=" --dry-run"
fi

if [ "$all" = true ]; then
    target_args=()
    target_string=""
fi


#always run bids first
echo "Running bidsify module first, as the rest of the pipeline depends on this."
echo "Running snakemake command: snakemake ${config_string} ${first_pass_string} gather_add_csa_data_to_meta"
if [ "$dag_mode" = true ]; then
    echo "saving DAG to bids_dag.svg, not running the pipeline"
    snakemake "${config_args[@]}" "${first_pass_args[@]}" --dag dot gather_add_csa_data_to_meta | sed -n '/digraph/,/}/p' | dot -Tsvg > bids_dag.svg
else
    snakemake "${config_args[@]}" "${first_pass_args[@]}" gather_add_csa_data_to_meta
fi

if [ "$reg_seg" = true ] || [ "$mp2rage" = true ] || [ "$ihmt" = true ] || [ "$qmt" = true ] || [ "$qsm" = true ] || [ "$dwi" = true ] || [ "$all" = true ]; then
    echo "Running snakemake command: snakemake ${config_string} ${main_string} ${target_string}"
    if [ "$dag_mode" = true ]; then
        echo "saving DAG to pipeline_dag.svg, not running the pipeline"
        snakemake "${config_args[@]}" "${main_args[@]}" --dag dot "${target_args[@]}" | sed -n '/digraph/,/}/p' | dot -Tsvg > pipeline_dag.svg
    else
        snakemake "${config_args[@]}" "${main_args[@]}" "${target_args[@]}"
    fi
fi