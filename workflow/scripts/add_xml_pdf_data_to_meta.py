import json
import argparse
import pdfplumber
import re
from pathlib import Path
from lxml import etree

def echo_spacing_from_xml_pdf(json_path: str, protocol_path: str):
    json_path = Path(json_path)
    protocol_path = Path(protocol_path)
    with open(json_path, "r") as f:
         meta = json.load(f)
    if not isinstance(meta.get("EchoSpacing_ms"), float):
        protocol_name = meta["StudyDescription"].split(" ")[-1]
        xml_search_pattern = "*" + protocol_name + "*.xml"
        pdf_search_pattern = "*" + protocol_name + "*.pdf"
        xml_path_list = sorted(protocol_path.rglob(xml_search_pattern, case_sensitive=False))
        pdf_path_list = sorted(protocol_path.rglob(pdf_search_pattern, case_sensitive=False))
        acq_string = meta["ProtocolName"]
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
            echo_value = rx.findall( echo_spacing_unit )[0]
            meta["EchoSpacing_ms"] = float(echo_value)
            with json_path.open("w") as f:
                json.dump(meta, f, indent=4)
            if echo_value is None:
                raise TypeError
        except:
            try:
                pdf_path = pdf_path_list[0]
                echo_spacing_pattern = re.compile(r'Echo\s*Spacing\s*([0-9.]+)\s*(ms)?', re.IGNORECASE)
                inside_target_sequence = False
                with pdfplumber.open(pdf_path) as pdf:
                    for page_num, page in enumerate(pdf.pages):
                        text = page.extract_text()
                        if not text:
                            continue
                        lines = text.split("\n")
                        for line in lines:
                            if protocol_name.lower() in line.lower():
                                if acq_string.lower() in line.lower():
                                    inside_target_sequence = True
                                else:
                                    inside_target_sequence = False
                            if inside_target_sequence:
                                echo_match = echo_spacing_pattern.search(line)
                                if echo_match:
                                    echo_value = echo_match.group(1)
                                    meta["EchoSpacing_ms"] = float(echo_value)
                                    with json_path.open("w") as f:
                                        json.dump(meta, f, indent=4)
                    if echo_value is None:
                        raise TypeError

            except:
                print("Parsing of echo spacing from the XML and PDF scanner protocol failed, setting echo spacing to reasonable default")
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
    echo_spacing_from_xml_pdf(args.json_path, args.protocol_path)