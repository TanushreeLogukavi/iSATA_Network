# iSATA_Network
 
This repository contains a step-by-step pipeline for performing brain montage simulations and functional network analysis. It integrates ROAST (Realistic Volumetric Approach to Simulate Transcranial Electric Stimulation) with the i-SATA toolbox to map electric field distributions onto AAL-116 ROIs and 9 large-scale functional networks.

Key Metrics:

1. NwCD (Network Current Density): Aggregated raw electric field intensities for each functional network.

2. DNTE (Distributed Network Total Energy): A normalized index (0-1) providing a ranking of current intensity received by each network (in both hemispheres, and each  hemisphere)

🛠️ Requirements & Setup
1. Prerequisites
   
Matlab version (R2021a or later recommended).

ROAST Toolbox (v3.0 or v4.0) (https://www.parralab.org/roast/)

i-SATA Toolbox. (https://researchdata.ntu.edu.sg/dataset.xhtml?persistentId=doi:10.21979/N9/KWTCWK)

Note : The principles of 𝓲-SATA, installation and usage are detailed in the paper (Kashyap et al. 2020)

Python version

Python 3.11 (recommended)

2. Installation

Check iSATA Manual in the repository.

1. Instead of Sample_Script_ISATA.mat use iSATA_Network_Ind_Main.mat to run individual subject iSATA Network analysis
2. This script involves 5 steps as described in mannual i-SATA 2026.pdf (download from repository)
   

Folder Structure

iSATA_Network/
│
├── README.md
├── SATA_CBL_Retrieve_Coords                # Replace existing file in path "\SATA\Final_Modularised_Code\Utilities\SATA_CBL_Retrieve_Coords.m"
├── iSATA_Network_Ind_Main.m                # Main execution script
├── iSATA_MNI_Network		                    	# Function for Step 5 Network Analysis add to Final_Modularized_Code in SATA path
├── SATA_CBL_Coords_With_High_MCD_MNI_atlas # Function for Step 3 & 4 Network Analysisadd to Final_Modularized_Code in SATA path
├── aal_MNI_Network                         # Add to Atlas folder (download AAL116 https://github.com/Neurita/std_brains/tree/master/atlases/aal_SPM12)
├── sample_iSATA_Results                    # Input MRI and roast results png results    
└── tool 		                                	# Create iSATA_Python folder add this folder to installation         

Outputs
The pipeline generates two primary visual reports:

subID_NwCD.mat: Visualizes raw mean current densities sorted from highest to lowest engagement.

subID_DNTE.mat: Visualizes normalized distributed energy across networks and hemispheres.

Created By - Dr. Rajan Kashyap & Tanushree L Date -12 March, 2026- at NIMHANS, Bangalore
rajankashyap6@gmail.com
tanushreelogukavi@gmail.com
The code is distributed for the academic Purposes only
