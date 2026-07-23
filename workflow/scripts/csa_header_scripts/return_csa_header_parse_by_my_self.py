### Hugo Dary, Aix Marseille Univ, CNRS, CRMBM, Marseille, France

import nibabel.nicom.csareader as csareader

import nibabel.nicom.ascconv as ascconv

from pydicom.tag import Tag

import pydicom

import os

import re

import sys

from csa_header_scripts._parse_Siemens_MrPhoenixProtocol import _parse_Siemens_MrPhoenixProtocol as _parse_Siemens_MrPhoenixProtocol
def return_csa(inputDirectory ):

    dataset =  []

    dicomFileNames = sorted( os.listdir( inputDirectory ) )

    for dicomFileName in dicomFileNames:

        dicomFilePath = os.path.join( inputDirectory, dicomFileName )

        dataset.append( dicomFilePath )

    cas = 0  
    firstFileInDs = pydicom.dcmread( dataset[0], force=True ) 
    if 'XA' not in firstFileInDs[int('00181020',16)].value:
        cas = 1
        # Read Siemens Series header (0x029,0x__20) "CSA Series Header"

        for tag_csa_series in ( '00291020','00291120','00291220', '00291010'):

            try:

                tag_csaSeriesHeader = firstFileInDs[int(tag_csa_series,16)].value

                csaSeriesHeader = csareader.read(tag_csaSeriesHeader)

                try:

                    #Parse MrPhoenixProtocol (elements that contain many parameters )

                    MrPhoenixProtocol = str(csaSeriesHeader['tags']['MrPhoenixProtocol']['items'][0])

                    mrprotocol =_parse_Siemens_MrPhoenixProtocol(MrPhoenixProtocol)

                except:

                    mrprotocol = 'tag_not_found'

                break

            except Exception as E:

                print(E, ' tag_not_found')

        return csaSeriesHeader, mrprotocol, cas
    elif 'XA' in firstFileInDs[int('00181020',16)].value:
        sds1=firstFileInDs.SharedFunctionalGroupsSequence[0][(0x0021, 0x10FE)][0]
        mrprot = sds1.get((0x0021, 0x1019))

        a = sds1[(0x0021, 0x1019)].value 
        # 3️⃣ Decode to a Python string
        txt = a.decode('latin1', errors='ignore')

        # 4️⃣ Extract the ASCCONV section with a regex
        m = re.search(r"### ASCCONV BEGIN(.*?)### ASCCONV END", txt, re.DOTALL)
        if not m:
            raise RuntimeError("Could not find ASCCONV block in the CSA text")

        ascc = m.group(1).strip()
        


        params = {}
        for line in ascc.splitlines():
            parts = line.split('=',1)
            if len(parts)==2:
                key = parts[0].strip()
                val = parts[1].strip().strip('"')
                params[key] = val
        
        

        cas = 2
        mrprotocol = ascc
        tags = list(params.keys())
        return params, mrprotocol, cas
    
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 return_csa_header_parse_by_my_self.py <path_to_dicom_folder>")
        sys.exit(1)

    inputDirectory = sys.argv[1]
    csa_header, mrprotocol, cas = return_csa(inputDirectory)

    print(csa_header)
    # print("CSA Header:", csa_header)
    # print("MrProtocol:", mrprotocol)
    # print("Case:", cas)
