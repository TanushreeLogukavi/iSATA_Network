import os
import glob
import subprocess
import numpy as np
from scipy.io import savemat

def shutil_which(pgm):
    import shutil
    return shutil.which(pgm)

def detect_acpc_for_folder(subject_roast_dir, sata_path):
    """
    Runs acpcdetect on NIfTI files inside subject_roast_dir and saves ACPC_coordinates.mat
    """
    print(f"\n==================================================")
    print(f"Running Phase 2: AC-PC Detection for: {subject_roast_dir}")
    print(f"==================================================")
    
    art_path = os.path.join(sata_path, "Utilities", "ART")
    art_bin_win = os.path.join(art_path, "bin")
    
    # Locate candidate NIfTI scan (ftOut.nii, *1mm.nii, *RAS.nii, or *.nii)
    nii_candidates = glob.glob(os.path.join(subject_roast_dir, "ftOut.nii"))
    if not nii_candidates:
        nii_candidates = glob.glob(os.path.join(subject_roast_dir, "*1mm.nii"))
    if not nii_candidates:
        nii_candidates = glob.glob(os.path.join(subject_roast_dir, "*RAS.nii"))
    if not nii_candidates:
        nii_candidates = glob.glob(os.path.join(subject_roast_dir, "*.nii"))

    if not nii_candidates:
        print(f"[ERROR] No NIfTI file found in {subject_roast_dir}")
        return False

    nii_file = nii_candidates[0]
    print(f"Target NIfTI Volume: {nii_file}")

    # Build command for Windows native / WSL execution
    os.environ["ARTHOME"] = art_path
    if os.path.exists(art_bin_win):
        os.environ["PATH"] += os.pathsep + art_bin_win

    has_wsl = shutil_which("wsl") is not None
    
    if os.name == 'nt' and has_wsl:
        # Convert paths to WSL format: C:\path -> /mnt/c/path
        drive, path_tail = os.path.splitdrive(nii_file)
        clean_path_tail = path_tail.replace('\\', '/')
        wsl_nii_path = f"/mnt/{drive[0].lower()}{clean_path_tail}"
        
        drive_art, art_tail = os.path.splitdrive(art_path)
        clean_art_tail = art_tail.replace('\\', '/')
        wsl_art_path = f"/mnt/{drive_art[0].lower()}{clean_art_tail}"
        
        # WSL Terminal Execution: Set ARTHOME, update PATH, and run acpcdetect
        cmd = f'wsl export ARTHOME="{wsl_art_path}" ; export PATH="$ARTHOME/bin:$PATH" ; acpcdetect -i "{wsl_nii_path}"'
    else:
        cmd = f'acpcdetect -i "{nii_file}"'

    print(f"Executing ACPCDETECT: {cmd}")
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if res.stdout:
            print(res.stdout)
        if res.stderr:
            print(res.stderr)
            if "liblapack" in res.stderr.lower():
                print("\n[DEPENDENCY NOTE] If acpcdetect failed due to liblapack, run in WSL terminal:")
                print("                  sudo apt update && sudo apt install -y liblapack3\n")
    except Exception as e:
        print(f"[WARNING] ACPCDETECT process message: {e}")

    # Look for produced text file (*ACPC.txt)
    acpc_txt_files = glob.glob(os.path.join(subject_roast_dir, "*ACPC.txt"))
    if not acpc_txt_files:
        acpc_txt_files = glob.glob("*ACPC.txt")

    if not acpc_txt_files:
        if os.path.exists(os.path.join(subject_roast_dir, "ACPC_coordinates.mat")):
            print(f"[OK] Existing ACPC_coordinates.mat found in {subject_roast_dir}.")
            return True
        print(f"[WARNING] ACPC text file not generated. If missing liblapack3, run: sudo apt install liblapack3")
        return False

    acpc_txt = acpc_txt_files[0]
    print(f"Parsing coordinates from: {acpc_txt}")

    AC, PC = None, None
    with open(acpc_txt, 'r') as fid:
        lines = fid.readlines()
        for i, line in enumerate(lines):
            if "# AC (i,j,k) voxel location:" in line:
                AC = [float(x) for x in lines[i+1].strip().split()]
            elif "# PC (i,j,k) voxel location:" in line:
                PC = [float(x) for x in lines[i+1].strip().split()]

    if AC is None or PC is None:
        print(f"[ERROR] Could not extract AC/PC values from {acpc_txt}")
        return False

    print(f"Extracted AC Coordinates: {AC}")
    print(f"Extracted PC Coordinates: {PC}")

    mat_out = os.path.join(subject_roast_dir, "ACPC_coordinates.mat")
    savemat(mat_out, {'AC': np.array(AC), 'PC': np.array(PC)})
    print(f"[SUCCESS] Saved: {mat_out}")
    return True

def run_acpc_step(input_results_dir, sata_path):
    if not os.path.exists(input_results_dir):
        print(f"[ERROR] Input path does not exist: {input_results_dir}")
        return False

    dirs_to_process = []

    # Case 1: Direct file input (e.g. "D:\...\sub01_T1w\roast\ftOut.nii")
    if os.path.isfile(input_results_dir):
        dirs_to_process = [os.path.dirname(input_results_dir)]
    else:
        # Case 2: Recursive search for ftOut.nii files across all subject subfolders
        found_ftout = glob.glob(os.path.join(input_results_dir, "**", "ftOut.nii"), recursive=True)
        if found_ftout:
            dirs_to_process = sorted(list(set([os.path.dirname(f) for f in found_ftout])))
        else:
            # Fallback 1: Search for *1mm.nii files
            found_1mm = glob.glob(os.path.join(input_results_dir, "**", "*1mm.nii"), recursive=True)
            if found_1mm:
                dirs_to_process = sorted(list(set([os.path.dirname(f) for f in found_1mm])))
            else:
                # Fallback 2: Scan direct subdirectories
                subdirs = [os.path.join(input_results_dir, d) for d in os.listdir(input_results_dir) if os.path.isdir(os.path.join(input_results_dir, d))]
                for sd in subdirs:
                    roast_sub = os.path.join(sd, "roast")
                    if os.path.exists(roast_sub):
                        dirs_to_process.append(roast_sub)
                    else:
                        dirs_to_process.append(sd)

    if not dirs_to_process:
        dirs_to_process = [input_results_dir]

    print(f"=== Found {len(dirs_to_process)} subject directory(ies) for AC-PC Landmark Detection ===")
    success_count = 0
    for d in dirs_to_process:
        if detect_acpc_for_folder(d, sata_path):
            success_count += 1

    print(f"\nPhase 2 Complete. Processed {success_count}/{len(dirs_to_process)} subject directories successfully.")
    return success_count > 0
