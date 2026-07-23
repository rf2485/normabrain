import json
import argparse
import re
from pathlib import Path
from lxml import etree

def echo_spacing_from_xml(json_path: str, protocol_path: str):
    json_path = Path(json_path)
    protocol_path = Path(protocol_path)
    with open(json_path, "r") as f:
         meta = json.load(f)
    if not isinstance(meta.get("EchoSpacing_ms"), float):
        protocol_name = meta["StudyDescription"].split(" ")[-1]
        xml_search_pattern = "*" + protocol_name + "*.xml"
        xml_path_list = sorted(protocol_path.rglob(xml_search_pattern, case_sensitive=False))
        acq_string = meta["SeriesDescription"]
        try:
            xml_path = xml_path_list[0]
            xml_tree = etree.parse(xml_path)
            xml_root = xml_tree.getroot()
            search_string_1 = ".//SubStep[ProtHeaderInfo[HeaderProtPath[contains(text(), '"
            search_string_2 = "')]]]/Card/ProtParameter[Label[contains(text(), 'Echo Spacing'\
    )]]/ValueAndUnit"
            search_string = search_string_1 + acq_string + search_string_2
            echo_spacing_unit = xml_root.xpath(search_string)[0].text
            numeric_const_pattern = r'[-+]? (?: (?: \d* \. \d+ ) | (?: \d+ \.? ) )(?: [Ee] [+\
    -]? \d+ ) ?'
            rx = re.compile(numeric_const_pattern, re.VERBOSE)
            meta["EchoSpacing_ms"] = float(rx.findall( echo_spacing_unit )[0])
            with json_path.open("w") as f:
                json.dump(meta, f, indent=4)
        except:
            print("Parsing of echo spacing from the XML scanner protocol failed, setting echo spacing to reasonable default")
            if "ihmt" in acq_string.lower():
                meta["EchoSpacing_ms"] = 5.82
            elif "mp2r" in acq_string.lower():
                meta["EchoSpacing_ms"] = 7.4
            with json_path.open("w") as f:
                json.dump(meta, f, indent=4)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description=
        """
        Read the XML scanner protocol from the provided folder and add relevant fields to the provided BIDS image json file.
        Assumes the XML file name contains the StudyDescription as specified in the provided json file.
        """
    )
    parser.add_argument("json_path", type=str, help="Path to an image's BIDS JSON sidecar file.")
    parser.add_argument("protocol_path", type=str, help="Path to the folder containing the scanning protocol XML file")
    args = parser.parse_args()
    echo_spacing_from_xml(args.json_path, args.protocol_path)