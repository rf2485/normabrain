### Hugo Dary, Aix Marseille Univ, CNRS, CRMBM, Marseille, France

import nibabel.nicom.csareader as csareader

import nibabel.nicom.ascconv as ascconv

from pydicom.tag import Tag

import pydicom

import os

import re

import sys

from csa_header_scripts.return_csa_header_parse_by_my_self import return_csa as return_csa
def find_params(tag,inputDirectory):
    """
    Retourne un dict {clé: valeur} ne contenant que
    les entrées dont la clé inclut 'FlipAngle'.
    """
    params, mrprotocol, cas = return_csa(inputDirectory)
    return {k: params[k] for k in params if tag in k}

# Exemple d’utilisation
if __name__ == "__main__":
    import sys
    inputDirectory = sys.argv[1]
    researchedTag = str(sys.argv[2])  # sPrepPulses.lMTCMode # adFlipANgle[0]
    if not os.path.isdir(inputDirectory):
        print(f"Le répertoire {inputDirectory} n'existe pas.")
        sys.exit(1)
  
    fas = find_params(researchedTag, inputDirectory=inputDirectory)
    val = [float(val) for val in fas.values()]
    # print(val)
    print(fas)
    # print(f"Recherche de {researchedTag} dans les paramètres CSA :")
    
    



 