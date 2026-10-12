import json
import argparse
from math import ceil, floor
from bidscoin import bcoin, bids, lsdirs
from pathlib import Path
from csa_header_scripts.return_csa_header_parse_by_my_self import return_csa

def add_csa_data_to_meta(bidspath: str):    
    #define search patterns for different sequence types
    perf_pattern = 'perf/*'
    tb1fl_pattern = 'fmap/*TB1*'
    vibemt_pattern = 'anat/*vibe*_MPM*'
    mp2rage_pattern = 'anat/*MP2RAGE*'  
    ihmt_pattern = 'anat/*ihmt*'
    #define bids directory
    bidsdir = Path(bidspath).resolve()
    #get list of subject folders
    subjects = lsdirs(bidsdir, 'sub-*')

    #setup logging for bidscoin commands (otherwise you will get errors)
    console = bcoin.setup_logging(bidsdir/'code'/'bidscoin'/'fixmeta.log')
    #load bidsmap
    bidsmap = bids.BidsMap(Path('bidsmap.yaml'), bidsdir/'code'/'bidscoin', checks=(False, False, False))
    #get list of plugins used in bidsmap
    plugins  = bidsmap.plugins
    #get provence, ie source of dicoms for each nifti file created with bidscoin
    provdata = bids.bidsprov(bidsdir)

    #loop through subjects
    for subject in subjects:
        #get list of session folders for subject
        sessions = lsdirs(subject, 'ses-*')
        
        #loop through sessions
        for session in sessions:
            #initialize sourcedir
            sourcedir = ''

            ihmt_targets = sorted([match for match in session.rglob(ihmt_pattern) if match.suffixes[0] in ('.tsv','.nii')])
            #loop through perfusion targets
            for target in ihmt_targets:
                print(target)
                #loop through map of provence data to nifiti/tsv bids files
                for source, row in provdata.iterrows():
                    #if the target pattern is in the name of the bids file, get the source dicom file path
                    if isinstance(row['targets'], str) and target.name.replace('_run-1', "") in row['targets']:
                        sourcedir = source
                #get datasource class from source dicom directory
                datasource = bids.get_datasource(Path(sourcedir), plugins)
                #get json sidecar file path for this target
                jsonfile = target.with_suffix('').with_suffix('.json')
                #pool metadata from source dicom and target json file
                jsondata = bids.poolmetadata(datasource, jsonfile, bids.Meta({}), ['.json'])
                #get csa data from source dicom
                csa_data, mrprotocol, cas = return_csa(sourcedir)
                if type(mrprotocol) is dict:
                    csa_data = mrprotocol
                
                #Parameters that are the same for all ihMT protocols
                if isinstance(csa_data.get('sWipMemBlock.alFree[2]'), str):
                    ContrastType = int(csa_data['sWipMemBlock.alFree[2]'])
                else:
                    ContrastType = 0
                jsondata["TurboFactor"] = float(csa_data["sFastImaging.lTurboFactor"])

                #parameters for 7T terra protocols
                if jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\ihMT_crmbm" or \
                    jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p0":
                    if ContrastType == 1:
                        jsondata['ContrastType'] = 'Frequency Alternated'
                    elif ContrastType == 2:
                        jsondata['ContrastType'] = 'Cosine Modulated'
                    jsondata['PulseDuration_us'] = float(csa_data['sWipMemBlock.alFree[3]'])
                    jsondata['PulseRepetitionTime_us'] = float(csa_data['sWipMemBlock.alFree[4]'])
                    jsondata['FrequencyOffset_hz'] = float(csa_data['sWipMemBlock.alFree[5]'])
                    jsondata['FlipAngle_deg'] = float(csa_data['sWipMemBlock.alFree[6]'])
                    jsondata['NumberPulses'] = int(csa_data['sWipMemBlock.alFree[7]'])
                    jsondata['NumberBursts'] = int(csa_data['sWipMemBlock.alFree[9]'])
                    jsondata['BurstRepetitionTime_us'] = float(csa_data['sWipMemBlock.alFree[8]'])
                    jsondata['TotalPrepDuration_us'] = float(csa_data['sWipMemBlock.alFree[10]'])
                    jsondata['TukeyShape'] = 0.2
                #parameters for 3T vida protocols
                elif jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v3MC" or \
                        jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4" or \
                        jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p1" or \
                        jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p2":
                    if ContrastType == 0:
                        jsondata['ContrastType'] = 'Frequency Alternated'
                    elif ContrastType == 1:
                        jsondata['ContrastType'] = 'Cosine Modulated'
                    elif ContrastType == 2:
                        jsondata['ContrastType'] = 'Frequency Alternated and Cosine Modulated'
                    elif ContrastType == 3:
                        jsondata['ContrastType'] = "BandPass (no single)"

                #DummyEchoes for version 3 protocols
                if jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\ihMT_crmbm" or \
                        jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v3MC":
                    jsondata["DummyEchoes"] = 0
                #DummyEchoes for version 4 protocol at 7T
                elif jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p0":
                    jsondata["DummyEchoes"] = int(csa_data['sWipMemBlock.alFree[19]'])
                #DummyEchoes for version 4 protocol at 3T
                elif jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4" or \
                        jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p1" or \
                        jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p2":
                    jsondata["DummyEchoes"] = float(csa_data["sWipMemBlock.alFree[32]"])

                #Parameters for version 3 protocol at 3T
                if jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v3MC":
                    jsondata['PulseDuration_us'] = float(csa_data['sWipMemBlock.alFree[24]'])
                    jsondata['PulseRepetitionTime_us'] = float(csa_data['sWipMemBlock.alFree[25]'])
                    jsondata['FrequencyOffset_hz'] = float(csa_data['sWipMemBlock.alFree[26]'])
                    jsondata['FlipAngle_deg'] = float(csa_data['sWipMemBlock.alFree[27]'])
                    jsondata['NumberPulses'] = int(csa_data['sWipMemBlock.alFree[28]'])
                    jsondata['NumberBursts'] = int(csa_data['sWipMemBlock.alFree[29]'])
                    jsondata['BurstRepetitionTime_us'] = float(csa_data['sWipMemBlock.alFree[5]'])
                    jsondata['TotalPrepDuration_us'] = float(csa_data['sWipMemBlock.alFree[7]'])
                    jsondata['TukeyShape'] = float(csa_data['sWipMemBlock.adFree[1]'])
                #Parameters for version 4 protocols at 3T
                elif jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4" or \
                        jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p1" or \
                        jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p2":
                    jsondata['PulseDuration_us'] = float(csa_data['sWipMemBlock.alFree[20]'])
                    jsondata['PulseRepetitionTime_us'] = float(csa_data['sWipMemBlock.alFree[21]'])
                    jsondata['FrequencyOffset_hz'] = float(csa_data['sWipMemBlock.alFree[22]'])
                    jsondata['FlipAngle_deg'] = float(csa_data['sWipMemBlock.alFree[23]'])
                    jsondata['NumberPulses'] = int(csa_data['sWipMemBlock.alFree[25]'])
                    jsondata['NumberBursts'] = int(csa_data['sWipMemBlock.alFree[26]'])
                    jsondata['BurstRepetitionTime_us'] = float(csa_data['sWipMemBlock.alFree[27]'])
                    jsondata['TotalPrepDuration_us'] = float(csa_data['sWipMemBlock.alFree[28]'])
                    jsondata['TukeyShape'] = float(csa_data['sWipMemBlock.alFree[24]']) / 100

                #Parameters for version 4.1 protocol at 3T
                if jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p1":
                    jsondata["EchoSpacing_ms"] = float(csa_data['sWipMemBlock.alFree[34]']) / 1000
                #Parameters for version 4.2 protocol at 3T
                if jsondata["PulseSequenceDetails"] == "%CustomerSeq%\\crmbm_ihMT_tfl_v4p2":
                    jsondata["EchoSpacing_ms"] = float(csa_data['sWipMemBlock.alFree[33]']) / 1000
                    
                #dump new json file to json sidecar
                with jsonfile.open('w') as jf:
                    json.dump(jsondata, jf, indent=4)

            #get list of perfusion target files that match the pattern
            perf_targets = sorted([match for match in session.rglob(perf_pattern) if match.suffixes[0] in ('.tsv','.nii')])
            #loop through perfusion targets
            for target in perf_targets:
                print(target)
                #loop through map of provence data to nifiti/tsv bids files
                for source, row in provdata.iterrows():
                    #if the target pattern is in the name of the bids file, get the source dicom file path
                    if isinstance(row['targets'], str) and target.name.replace('_run-1', "") in row['targets']:
                        sourcedir = source
                #get datasource class from source dicom directory
                datasource = bids.get_datasource(Path(sourcedir), plugins)
                #get json sidecar file path for this target
                jsonfile = target.with_suffix('').with_suffix('.json')
                #pool metadata from source dicom and target json file
                jsondata = bids.poolmetadata(datasource, jsonfile, bids.Meta({}), ['.json'])
                #get csa data from source dicom
                csa_data, mrprotocol, cas = return_csa(sourcedir)
                if type(mrprotocol) is dict:
                    csa_data = mrprotocol
                #convert string boolean values to actual booleans
                if jsondata['BackgroundSuppression'] == 'true' or jsondata['BackgroundSuppression'] == 'YES':
                    jsondata['BackgroundSuppression'] = True
                elif jsondata['BackgroundSuppression'] == 'false' or jsondata['BackgroundSuppression'] == 'NO':
                    jsondata['BackgroundSuppression'] = False
                if jsondata['VascularCrushing'] == 'true' or jsondata['VascularCrushing'] == 'YES':
                    jsondata['VascularCrushing'] = True
                elif jsondata['VascularCrushing'] == 'false' or jsondata['VascularCrushing'] == 'NO':
                    jsondata['VascularCrushing'] = False
                #dump new json file to json sidecar
                with jsonfile.open('w') as jf:
                    json.dump(jsondata, jf, indent=4)
            
            #get list of t1b1fl target files that match the pattern
            tb1fl_targets = sorted([match for match in session.rglob(tb1fl_pattern) if match.suffixes[0] in ('.tsv','.nii')])
            for target in tb1fl_targets:
                print(target)
                for source, row in provdata.iterrows():
                    if isinstance(row['targets'], str) and target.name.replace('_run-1', "") in row['targets']:
                        sourcedir = source
                datasource = bids.get_datasource(Path(sourcedir), plugins)
                jsonfile = target.with_suffix('').with_suffix('.json')
                jsondata = bids.poolmetadata(datasource, jsonfile, bids.Meta({}), ['.json'])
                csa_data, mrprotocol, cas = return_csa(sourcedir)
                if type(mrprotocol) is dict:
                    csa_data = mrprotocol
                #add Target_FA_deg field to json sidecar from csa data
                if isinstance(csa_data.get('sWipMemBlock.adFree[0]'), str):
                    jsondata['target_fa_deg'] = float(csa_data['sWipMemBlock.adFree[0]'])
                elif jsondata["MagneticFieldStrength"] == 7:
                    jsondata['target_fa_deg'] = 900
                with jsonfile.open('w') as jf:
                    json.dump(jsondata, jf, indent=4)

            #get list of vibemt target files that match the pattern
            vibemt_targets = sorted([match for match in session.rglob(vibemt_pattern) if match.suffixes[0] in ('.tsv','.nii')])
            for target in vibemt_targets:
                print(target)
                for source, row in provdata.iterrows():
                    if isinstance(row['targets'], str) and target.name.replace('_run-1', "") in row['targets']:
                        sourcedir = source
                datasource = bids.get_datasource(Path(sourcedir), plugins)
                jsonfile = target.with_suffix('').with_suffix('.json')
                jsondata = bids.poolmetadata(datasource, jsonfile, bids.Meta({}), ['.json'])
                csa_data, mrprotocol, cas = return_csa(sourcedir)
                if type(mrprotocol) is dict:
                    csa_data = mrprotocol
                # if MT state is stored as a string in the csa header, convert to int and add to json sidecar, otherwise set it to 0
                if isinstance(csa_data.get('sWipMemBlock.alFree[0]'), str):
                    jsondata['mt_state'] = int(csa_data['sWipMemBlock.alFree[0]'])
                else:
                    jsondata['mt_state'] = 0
                #add other relevant fields from csa header to json sidecar
                jsondata['sat_pulse_ms'] = float(csa_data['sWipMemBlock.adFree[2]'])
                jsondata['interdelay_ms'] = float(csa_data['sWipMemBlock.adFree[5]'])
                jsondata['ro_pulse_ms'] = float(csa_data['sWipMemBlock.alFree[7]']) / 1000
                jsondata['tr_ms'] = float(csa_data['alTR[0]']) / 1000
                jsondata['ro_fa_deg'] = float(csa_data['adFlipAngleDegree[0]'])
                #if RO pulse shape is coded in the csa header, convert it to int and store the value in ro_pulse_shape, otherwise set it to 0
                if isinstance(csa_data.get('sWipMemBlock.alFree[8]'), str):
                    ro_pulse_shape = int(csa_data['sWipMemBlock.alFree[8]'])
                else:
                    ro_pulse_shape = 0
                #convert ro_pulse_shape value to string and store in json sidecar 
                if ro_pulse_shape == 1:
                    jsondata['ro_pulse_shape'] = 'CSMT'
                elif ro_pulse_shape == 2:
                    jsondata['ro_pulse_shape'] = 'BP'
                else:
                    jsondata['ro_pulse_shape'] = 'Hann' #if not specified RO pulse shape is Hann
                #add saturation pulse parameters to json sidecar
                jsondata['sat_pulse_fa_deg'] = float(csa_data['sWipMemBlock.adFree[0]'])
                jsondata['sat_pulse_offset_hz'] = float(csa_data['sWipMemBlock.adFree[1]'])
                #if sat pulse shape is coded in the csa header, convert it to int and store the value in sat_pulse_shape, otherwise set it to 0
                if isinstance(csa_data.get('sWipMemBlock.alFree[1]'), str):
                    sat_pulse_shape = int(csa_data['sWipMemBlock.alFree[1]'])
                else:
                    sat_pulse_shape = 0
                #convert sat_pulse_shape value to string and store in json sidecar
                if sat_pulse_shape == 1:
                    jsondata['sat_pulse_shape'] = 'GaussHann-Sine'
                elif sat_pulse_shape == 2:
                    jsondata['sat_pulse_shape'] = 'Gauss-Sine'
                else:
                    jsondata['sat_pulse_shape'] = 'Hann-Sine' #if not specified sat pulse shape is Hann-Sine
                with jsonfile.open('w') as jf:
                    json.dump(jsondata, jf, indent=4)
        
            #loop through mp2rage targets
            mp2rage_targets = sorted([match for match in session.rglob(mp2rage_pattern) if match.suffixes[0] in ('.tsv','.nii')])
            for target in mp2rage_targets:
                print(target)
                for source, row in provdata.iterrows():
                    if isinstance(row['targets'], str) and target.name.replace('_run-1', "") in row['targets']:
                        sourcedir = source
                datasource = bids.get_datasource(Path(sourcedir), plugins)

                jsonfile = target.with_suffix('').with_suffix('.json')
                jsondata = bids.poolmetadata(datasource, jsonfile, bids.Meta({}), ['.json'])
                csa_data, mrprotocol, cas = return_csa(sourcedir)
                if type(mrprotocol) is dict:
                    csa_data = mrprotocol
                #add TR to json sidecar from csa data
                jsondata['tr_ms'] = float(csa_data['alTR[0]']) / 1000
                #add TI1 and TI2 to json sidecar from csa data if they are stored as strings
                if isinstance(csa_data.get('alTI[0]'), str):
                    jsondata['ti1_ms'] = float(csa_data['alTI[0]']) / 1000
                if isinstance(csa_data.get('alTI[1]'), str):
                    jsondata['ti2_ms'] = float(csa_data['alTI[1]']) / 1000
                
                #add readout flip angles to json sidecar from csa data
                jsondata['ro_fa1_deg'] = float(csa_data['adFlipAngleDegree[0]'])
                jsondata['ro_fa2_deg'] = float(csa_data['adFlipAngleDegree[1]'])
                #calculate number of shots before and after the inversion pulse based on sequence type
                if jsondata['PulseSequenceDetails'] == "%SiemensSeq%\\tfl" or jsondata['PulseSequenceDetails'] == "%CustomerSeq%\\wip_963_iVIBE_tfl":
                    jsondata['n_after'] = int(floor(float(csa_data['sKSpace.lPartitions']) / 2))
                    jsondata['n_before'] = int(csa_data['sFastImaging.lTurboFactor']) - jsondata['n_after']
                elif jsondata['PulseSequenceDetails'] == "%CustomerSeq%\\wip_csTFL_cstfl":
                    jsondata['n_after'] = int(floor(float(csa_data['sFastImaging.lTurboFactor']) / 2))
                    jsondata['n_before'] = int(ceil(float(csa_data['sFastImaging.lTurboFactor']) / 2))
                elif jsondata['PulseSequenceDetails'] == "%CustomerSeq%\\cstfl_wip925b":
                    jsondata['n_after'] = int(floor(float(csa_data['sWipMemBlock.alFree[2]']) / 2))
                    jsondata['n_before'] = int(ceil(float(csa_data['sWipMemBlock.alFree[2]']) / 2))
                #save number of shots before and after inversion pulse to NumberShots field in json sidecar, for BIDS compatibility
                jsondata['NumberShots'] = [jsondata['n_before'], jsondata['n_after']]
                with jsonfile.open('w') as jf:
                    json.dump(jsondata, jf, indent=4)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        """
        Read CSA header data from DICOM source directories and add relevant fields to BIDS sidecar JSON files.
        Assumes BIDS structure was generated with bidscoin and that provenance data is available.
        """)
    parser.add_argument('bidspath', type=str, help="Path to the BIDS directory")
    args = parser.parse_args()
    add_csa_data_to_meta(args.bidspath)