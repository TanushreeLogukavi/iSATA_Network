# iSATA_Network
 
This repository contains a step-by-step pipeline for performing brain montage simulations and functional network analysis. It integrates ROAST (Realistic Volumetric Approach to Simulate Transcranial Electric Stimulation) with the i-SATA toolbox to map electric field distributions onto AAL-116 ROIs and 9 large-scale functional networks.

Key Metrics:

1. NwCD (Network Current Density): Aggregated raw electric field intensities for each functional network.

2. DNTE (Distributed Network Total Energy): A normalized index (0-1) providing a ranking of current intensity received by each network (in both hemispheres, and each  hemisphere)

🛠️ Requirements & Setup
1. Prerequisites
   
Matlab version


MATLAB (R2021a or later recommended).

ROAST Toolbox (v3.0 or v4.0) https://www.parralab.org/roast/

i-SATA Toolbox. 

Note : The principles of 𝓲-SATA, installation and usage are detailed in the paper (Kashyap et al. 2020)

Python version

Python 3.11 (recommended)

2. Installation

Check iSATA Manual in the repository

Folder Structure

iSATA_Network/
│
├── README.md
├── iSATA
├── iSATA_Network_Ind_Main.m         # Main execution script
├── iSATA_MNI_Network			# add to Final_Modularized_Code in SATA path
├── SATA_CBL_Coords_With_High_MCD_MNI_atlas # add to Final_Modularized_Code in SATA path
├── iSATA_MNI_Network.m     # Function for Step 5 Network Analysis
├── sample_iSATA_Results            # Input MRI and roast results png results    
└── tool 			# Create iSATA_Python folder add this folder to installation         

Outputs
The pipeline generates two primary visual reports:

subID_NwCD.fig: Visualizes raw mean current densities sorted from highest to lowest engagement.

subID_DNTE.fig: Visualizes normalized distributed energy across networks and hemispheres.

Created By - Dr. Rajan Kashyap & Tanushree L Date -12 March, 2026- at NIMHANS, Bangalore
tanushreelogukavi@gmail.com
The code is distributed for the academic Purposes only
