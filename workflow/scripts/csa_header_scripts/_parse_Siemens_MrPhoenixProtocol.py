### Hugo Dary, Aix Marseille Univ, CNRS, CRMBM, Marseille, France

import nibabel.nicom.csareader as csareader

import nibabel.nicom.ascconv as ascconv

from pydicom.tag import Tag

import pydicom

import os

import re

import sys
def _parse_Siemens_MrPhoenixProtocol(MrPhoenixProtocol):

    """Returns a dictionary containing the name/value pairs inside the

    "ASCCONV" section of the MrProtocol or MrPhoenixProtocol elements

    of a Siemens CSA  Series Header tag.

    """

    # MrPhoenixProtocol is a large string (e.g. 32k) that lists a lot of

    # variables in a JSONish format.Parse everything inside

    # and return as a dictionary.

    start = MrPhoenixProtocol.find("### ASCCONV BEGIN")

    end = MrPhoenixProtocol.find("### ASCCONV END ###")

    start += len("### ASCCONV BEGIN")

    MrPhoenixProtocol = MrPhoenixProtocol[start:end]

    lines = MrPhoenixProtocol.split('\n')

    lines = [line for line in lines if line != ' ###']

    lines = [line for line in lines if line != '']

    # The two lines of code below turn the 'lines' list into a list of

    # (name, value) tuples in which name & value have been stripped and

    # all blank lines have been discarded.

    f = lambda pair: (pair[0].strip(), pair[1].strip())

    lines = [f(line.split('=')) for line in lines if line]

    return dict(lines)

if __name__ == "__main__": 
    if len(sys.argv) < 2:
        print("Usage: python3 parse_mrphoenixprotocol.py <path_to_csa_file>")
        sys.exit(1)

    csa_file_path = sys.argv[1]

    dict_MrPhoenixProtocol_ordoned = _parse_Siemens_MrPhoenixProtocol(csa_file_path)