#!/usr/bin/env python3
"""
iSATA Environment & Setup Diagnostic Check Tool
Run: py -3.11 tool/cli.py
"""

import os
import sys
import shutil
import subprocess

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
if TOOL_DIR not in sys.path:
    sys.path.insert(0, TOOL_DIR)

from matlab_runner import find_matlab_executable
SATA_PATH = os.path.dirname(TOOL_DIR)

def check_python_environment():
    print("\n--- 1. Python Environment Check ---")
    print(f"Python Version: {sys.version.split()[0]} ({sys.executable})")
    
    required_packages = ["numpy", "scipy", "nibabel"]
    for pkg in required_packages:
        try:
            __import__(pkg)
            print(f"  [OK] Package '{pkg}' is installed.")
        except ImportError:
            print(f"  [MISSING] Package '{pkg}' is missing! Install via: pip install {pkg}")

def check_matlab_environment():
    print("\n--- 2. MATLAB Executable Check ---")
    matlab_exe = find_matlab_executable()
    if os.path.exists(matlab_exe) or shutil.which("matlab"):
        print(f"  [OK] MATLAB Executable Found: {matlab_exe}")
    else:
        print("  [WARNING] MATLAB executable not found on PATH or standard install paths.")

def check_sata_toolbox_components():
    print("\n--- 3. SATA Toolbox Components Check ---")
    print(f"SATA Toolbox Directory: {SATA_PATH}")
    
    essential_files = [
        "SATA_CBL_init.m",
        "iSATA_Stage1_ROAST_PreACPC.m",
        "iSATA_Stage2_PostACPC_MNI_DTDI.m",
        "ISATA_Montage.mat",
        "ACPC_coordinates.mat",
        os.path.join("Final_Modularised_Code", "SATA_CBL_Coords_With_High_MCD_MNI.m"),
        os.path.join("Final_Modularised_Code", "SATA_CBL_Get_Region_DTDI.m"),
        os.path.join("Utilities", "spm12"),
        os.path.join("Utilities", "ART")
    ]
    
    for item in essential_files:
        full_p = os.path.join(SATA_PATH, item)
        if os.path.exists(full_p):
            print(f"  [OK] Found: {item}")
        else:
            print(f"  [MISSING] Missing required file/folder: {item}")

    print("\n--- ROAST Solver Engines Check ---")
    roast_3 = os.path.join(SATA_PATH, "roast-3.0")
    roast_4 = os.path.join(SATA_PATH, "roast-4.0")
    
    if os.path.exists(roast_3):
        print(f"  [OK] ROAST 3.0 Engine Found: {roast_3}")
    else:
        print(f"  [MISSING] ROAST 3.0 Directory not found: {roast_3}")
        
    if os.path.exists(roast_4):
        print(f"  [OK] ROAST 4.0 Engine Found: {roast_4}")
    else:
        print(f"  [INFO] ROAST 4.0 Directory not found: {roast_4}")

def check_acpc_art_setup():
    print("\n--- 4. ART / ACPCDETECT Diagnostic Check ---")
    art_path = os.path.join(SATA_PATH, "Utilities", "ART")
    
    if os.path.exists(art_path):
        print(f"  [OK] ART Path exists: {art_path}")
    else:
        print(f"  [MISSING] ART Directory not found at: {art_path}")
        
    has_wsl = shutil.which("wsl") is not None
    if has_wsl:
        print("  [OK] Windows Subsystem for Linux (WSL) is available.")
        # Check liblapack3 dependency in WSL
        try:
            res = subprocess.run("wsl ldconfig -p", shell=True, capture_output=True, text=True)
            if "liblapack" in res.stdout.lower():
                print("  [OK] WSL dependency 'liblapack3' is installed and verified.")
            else:
                print("  [NOTE] 'liblapack3' not detected in WSL ldconfig. Run: sudo apt install -y liblapack3")
        except Exception:
            pass
    else:
        print("  [INFO] WSL not detected. Native Windows acpcdetect or Python fallback will be used.")

def main():
    print("==================================================")
    print("      iSATA TOOLBOX DIAGNOSTIC CHECK")
    print("==================================================")
    check_python_environment()
    check_matlab_environment()
    check_sata_toolbox_components()
    check_acpc_art_setup()
    print("\n==================================================")
    print("Diagnostic Complete. Ready to execute iSATA CLI commands.")
    print("==================================================")

if __name__ == "__main__":
    main()
