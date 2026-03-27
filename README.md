# iSATA_Network
 
This repository contains a step-by-step pipeline for performing brain montage simulations and functional network analysis. It integrates ROAST (Realistic Volumetric Approach to Simulate Transcranial Electric Stimulation) with the i-SATA toolbox to map electric field distributions onto AAL-116 ROIs and 9 large-scale functional networks.

Key Metrics:

NwCD (Network Current Density): Aggregated raw electric field intensities for each functional network.

DNTE (Distributed Network Total Energy): A normalized index (0-1) providing a ranking of current intensity received by each network (in both hemispheres, and each  hemisphere)

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
Clone this repository mat codes final modularised and utility



Workflow Steps
Step 1: ROAST Simulation
Automates the simulation of electric fields using individual subject MRI.

Input: T1-weighted NIfTI file.

Output: Electric field distribution, 3D renders, and resampled NIfTI files.

Step 2: AC-PC Detection
Detects the Anterior Commissure (AC) and Posterior Commissure (PC) points required for MNI space mapping.

Automatic: Uses acpcdetect via the terminal.

Manual: Uses SATA_acpc_extract if coordinates are pre-identified.

Step 3 & 4: MNI Mapping & DTDI
Maps the E-field to the AAL-116 atlas regions and calculates the Dose Target Determination Index (DTDI).

Ranks brain regions based on target engagement.

Step 5: Network Analysis
Aggregates the AAL-116 data into 9 functional networks (Default Mode, Frontoparietal, etc.).

NwCD Figure: Vertical stack of Global, Left, and Right network intensities.

DNTE Figure: 2x2 grid showing normalized rankings (High-to-Low).

Folder Structure
Plaintext
project-root/
│
├── iSATA_Network_Ind_Main.m         # Main execution script
├── iSATA_MNI_Network.m     # Function for Step 5 Network Analysis
├── sample_data/            # Input MRI and roast results
└── output/                 # .fig, .mat, and .png results

Outputs
The pipeline generates two primary visual reports:

subID_NwCD.fig: Visualizes raw mean current densities sorted from highest to lowest engagement.

subID_DNTE.fig: Visualizes normalized distributed energy across networks and hemispheres.

Created By - Dr. Rajan Kashyap & Tanushree L Date -12 March, 2026- at NIMHANS, Bangalore
tanushreelogukavi@gmail.com
The code is distributed for the academic Purposes only
