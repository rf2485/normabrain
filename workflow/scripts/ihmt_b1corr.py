import argparse
import json
import yaml
from ihmt import Tukey, Sequence, Signal, System, Simulator, Corrector, Duration, Frequency, Angle
from pathlib import Path
from nibabel import load, Nifti1Image


def ihmt_b1corr(ihmt_nifti: str, ihmt_json: str, b1map_nifti: str, b1map_json: str, mask_nifti: str, field_strength: str, map_type: str):
    #limit possible values of field_strength
    assert field_strength in ["3T", "7T", "custom"]
    #limit possible values of map_type
    assert map_type in ["MT0", "MTs_Positive", "MTs_Negative", "MTd_CM", "MTd_ALT", "MTs", "ihMT_CM", "ihMT_ALT", "BP", "MTsR_Positive", "MTsR_Negative", "MTsR", "MTdR_CM", "MTdR_ALT", "ihMTR_CM", "ihMTR_ALT", "BPR", "DO_ALT", "DO_CM", "ALL"]
    #make file strings Paths
    ihmt_nifti = Path(ihmt_nifti)
    ihmt_json = Path(ihmt_json)
    with open(ihmt_json, "r") as f:
        ihmt_meta = json.load(f)
    b1map_nifti = Path(b1map_nifti)
    b1map_json = Path(b1map_json)
    with open(b1map_json, "r") as f:
        b1map_meta = json.load(f)

    mask_nifti = Path(mask_nifti)

    #load system config file
    system_config_path = Path(__file__).with_name("ihmt_b1corr_system_config.yaml")
    with system_config_path.open("r") as f:
        system_config = yaml.safe_load(f)

    param_paths = dict(
        flipAngle = b1map_nifti,
        mask = mask_nifti
    )

    data_paths = {
        getattr(Signal, map_type): ihmt_nifti
    }

    param_maps = dict()
    data_maps = dict()

    affine, header = None, None

    for key, val in param_paths.items():
        param_maps[key] = load(val).get_fdata()

    param_maps['mask'] = param_maps['mask'].astype(bool)
    param_maps['flipAngle'] = param_maps['flipAngle'] * ihmt_meta["FlipAngle_deg"] * ihmt_meta["TxRefAmp"] / b1map_meta["TxRefAmp"]

    for key, val in data_paths.items():
        norm = 1
        # if key in [Signal.MTsR_Positive, Signal.MTsR_Negative, Signal.MTsR, Signal.MTdR_CM, Signal.MTdR_ALT, Signal.ihMTR_CM, Signal.ihMTR_ALT, Signal.BPR]:
        #     norm = 100
        if affine is None or header is None:
            tmp = load(val)
            affine = tmp.affine
            header = tmp.header
            data_maps[key] = norm * tmp.get_fdata()
        else:
            data_maps[key] = norm * load(val).get_fdata()

    #parameters need to be converted to seconds and degrees
    pulse = Tukey(
        shape = ihmt_meta["TukeyShape"],
        duration = Duration.from_micro(ihmt_meta["PulseDuration_us"]),
        offset = Frequency.from_hertz(ihmt_meta["FrequencyOffset_hz"]),
        flipAngle = Angle.from_degrees(ihmt_meta["FlipAngle_deg"]),
    )

    seq = Sequence(
        signal = Signal.from_str(map_type),
        pulse = pulse,
        N_pulsePerOffset=1,
        N_pulse = ihmt_meta["NumberPulses"],
        N_burst = ihmt_meta["NumberBursts"],
        N_adc = ihmt_meta["TurboFactor"] - ihmt_meta["DummyEchoes"],
        N_dummyADC = ihmt_meta["DummyEchoes"],
        dt_interPulse = Duration.from_micro(ihmt_meta["PulseRepetitionTime_us"]),
        TR_burst = Duration.from_micro(ihmt_meta["BurstRepetitionTime_us"]),
        dt_lastBurst = Duration.from_micro(ihmt_meta["TotalPrepDuration_us"]) - (Duration.from_micro(ihmt_meta["BurstRepetitionTime_us"]) * (ihmt_meta["NumberBursts"] - 1)),
        es = Duration.from_milli(ihmt_meta["EchoSpacing_ms"]),
        tr = Duration.from_seconds(ihmt_meta["RepetitionTime"]),
        readout_flipAngle = Angle.from_degrees(ihmt_meta["FlipAngle"]),
    )
    
    if field_strength == "7T":
        sys = System(
            pulse = pulse,
            **system_config['7T_system']
        )
    elif field_strength == "3T":
        sys = System(
            pulse = pulse,
            **system_config['3T_system']
        )
    else:
        sys = System(
            pulse = pulse,
            **system_config['custom_system']
        )
        
    sim = Simulator(
        system = sys,
        sequence = seq,
        export_readMatrix=False,
        output_vectorSlice=slice(1)
    )
    cor1D = Corrector.Simple(simulator=sim)
    # param_maps['flipAngle'] *= 1e-3 * pulse.flipAngle
    corData = cor1D.apply(parameter_maps=param_maps, data_maps=data_maps)

    # for value in [*list(corData.values()), *list(data_maps.values()), *list(param_maps.values())]:
    #     value.setflags(write=True)
    #     value[~param_maps['mask']] = 0
    #     value.setflags(write=False)

    for key, value in corData.items():
       Nifti1Image(value, affine, header).to_filename(data_paths[key].with_stem(data_paths[key].stem.replace(".nii", "") + "_b1corr.nii"))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        """
        Apply B1+ correction to ihMT derived maps and raw volumes. Must be a 3D volume with the map type specified.
        """
    )
    parser.add_argument("ihmt_nifti", type=str, help="Path to the ihMT map nifti.")
    parser.add_argument("ihmt_json", type=str, help="Path to the ihMT map json BIDS sidecar file.")
    parser.add_argument("b1map_nifti", type=str, help="Path to the B1+ flip angle map nifti, in the same space as the ihMT map, normalized by the B1+ target flip angle.")
    parser.add_argument("b1map_json", type=str, help="Path to the B1+ flip angle map json metadata BIDS sidecar.")
    parser.add_argument("mask_nifti", type=str, help="Path to the mask nifit, in the same space as the ihMT map.")
    parser.add_argument("field_strength", type=str, help="Field strength used to collect the MRI data. Must be one of '7T', '3T', or 'custom'. If 'custom', edit the system values in ihmt_b1corr_system_config.yaml under 'custom_system'.")
    parser.add_argument("map_type", type=str, help='ihMT derived map or raw volume type. Must be one of "MT0", "MTs_Positive", "MTs_Negative", "MTd_CM", "MTd_ALT", "MTs", "ihMT_CM", "ihMT_ALT", "BP", "MTsR_Positive", "MTsR_Negative", "MTsR", "MTdR_CM", "MTdR_ALT", "ihMTR_CM", "ihMTR_ALT", "BPR", "DO_CM", "DO_ALT", "ALL"')
    args = parser.parse_args()
    ihmt_b1corr(args.ihmt_nifti, args.ihmt_json, args.b1map_nifti, args.b1map_json, args.mask_nifti, args.field_strength, args.map_type)