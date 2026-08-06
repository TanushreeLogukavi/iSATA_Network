#!/usr/bin/env python3
r"""
iSATA Python CLI Toolbox
Automates end-to-end ROAST -> ACPC -> MNI-DTDI -> DNTE analysis pipeline.
Supports ROAST 3.0 and ROAST 4.0 engines and all simulation options.

Usage Examples:
  Standard:
     py -3.11 isata.py -i "D:\data" -o "D:\results"
     py -3.11 isata.py run-all -i "D:\data" -o "D:\results"

  Frontal Stimulation:
     py -3.11 isata.py -i "D:\data" -o "D:\results" -a F3 -k Fp2 -c 1.5 -s "35 35 3"

  Padding:
     py -3.11 isata.py -i "D:\data" -o "D:\results" --p 40

  High-Resolution:
     py -3.11 isata.py -i "D:\data" -o "D:\results" -m fine

  For Lesioned/Atrophied Brains (Multiaxial Mode):
     py -3.11 isata.py -i "D:\data" -o "D:\results" -mx

  To verify Landmark Registration (Manual GUI):
     py -3.11 isata.py -i "D:\data" -o "D:\results" -mx -g

  If you have T2 images (Better Segmentation):
     py -3.11 isata.py -i "D:\data\sub1_T1.nii" -t2 "D:\data\sub1_T2.nii" -o "D:\results"

  To generate a Lead Field (For later targeting):
     py -3.11 isata.py -i "D:\data" -o "D:\results" -lf

  Step 2 : AC-PC Configuration:
     py -3.11 isata.py acpc -i "D:\results"

  Step 3 : i-SATA MNI:
     py -3.11 isata.py mni-dtdi -i "D:\results"

  Step 4 : i-SATA Network:
     py -3.11 isata.py dnte -i "D:\results"
"""

import os
import sys
import argparse

TOOL_DIR = os.path.dirname(os.path.abspath(__file__))
if TOOL_DIR not in sys.path:
    sys.path.insert(0, TOOL_DIR)

from matlab_runner import run_matlab_command
from acpc_runner import run_acpc_step

SATA_PATH = os.path.dirname(TOOL_DIR)

def build_roast_matlab_cmd(input_dir, output_dir, roast_ver="3.0", anode="CP5", cathode="Cz", current=2.0, size="50 50 3", pad=None, mesh="fine", multiaxial=False, gui=False, t2="", leadfield=False):
    pad_str = f"padding_input={pad};" if pad is not None else "padding_input=[];"
    mx_val = 1 if multiaxial else 0
    gui_val = 1 if gui else 0
    lf_val = 1 if leadfield else 0
    
    cmd = (
        f"warning('off', 'MATLAB:path:notFound'); "
        f"addpath(genpath('{SATA_PATH}')); "
        f"mri_input='{input_dir}'; output_base_dir='{output_dir}'; roast_ver_input='{roast_ver}'; "
        f"anode_input='{anode}'; cathode_input='{cathode}'; current_input={current}; size_input='{size}'; "
        f"{pad_str} resolution_input='{mesh}'; multiaxial_input={mx_val}; gui_input={gui_val}; "
        f"t2_input='{t2}'; leadfield_input={lf_val}; "
        f"iSATA_Stage1_ROAST_PreACPC;"
    )
    return cmd

def run_roast_phase(input_dir, output_dir, **kwargs):
    print("\n==================================================")
    print(f"PHASE 1: ROAST SIMULATION (Engine {kwargs.get('roast_ver', '3.0')})")
    print(f"Montage: {kwargs.get('anode', 'CP5')} ({kwargs.get('current', 2.0)}mA) -> {kwargs.get('cathode', 'Cz')} ({-kwargs.get('current', 2.0)}mA)")
    print("==================================================")
    matlab_cmd = build_roast_matlab_cmd(input_dir, output_dir, **kwargs)
    return run_matlab_command(matlab_cmd, cwd=SATA_PATH)

def run_acpc_phase(results_dir):
    print("\n==================================================")
    print("PHASE 2: AC-PC LANDMARK DETECTION (ART/WSL)")
    print("==================================================")
    return run_acpc_step(results_dir, SATA_PATH)

def run_mni_dtdi_phase(results_dir):
    print("\n==================================================")
    print("PHASE 3: MNI MAPPING & REGIONAL DTDI CALCULATION")
    print("==================================================")
    matlab_cmd = f"warning('off', 'MATLAB:path:notFound'); addpath(genpath('{SATA_PATH}')); mri_input='{results_dir}'; output_base_dir='{results_dir}'; iSATA_Stage2_PostACPC_MNI_DTDI;"
    return run_matlab_command(matlab_cmd, cwd=SATA_PATH)

def run_dnte_phase(results_dir):
    print("\n==================================================")
    print("PHASE 4: FUNCTIONAL NETWORK ANALYSIS (DNTE)")
    print("==================================================")
    matlab_cmd = f"warning('off', 'MATLAB:path:notFound'); addpath(genpath('{SATA_PATH}')); mri_input='{results_dir}'; output_base_dir='{results_dir}'; iSATA_Stage2_PostACPC_MNI_DTDI;"
    return run_matlab_command(matlab_cmd, cwd=SATA_PATH)

def add_roast_arguments(parser_obj, is_required=True):
    parser_obj.add_argument("-i", "--input", required=is_required, help="Input directory containing raw .nii files (or single .nii file)")
    parser_obj.add_argument("-o", "--output", required=is_required, help="Output results root directory")
    parser_obj.add_argument("-a", "--anode", default="CP5", help="Anode electrode tag (default: CP5)")
    parser_obj.add_argument("-k", "--cathode", default="Cz", help="Cathode electrode tag (default: Cz)")
    parser_obj.add_argument("-c", "--current", type=float, default=2.0, help="Current magnitude in mA (default: 2.0)")
    parser_obj.add_argument("-s", "--size", default="50 50 3", help="Electrode dimensions W H T in mm (default: '50 50 3')")
    parser_obj.add_argument("-p", "--p", "--pad", dest="pad", type=int, default=None, help="Zero padding around head volume")
    parser_obj.add_argument("-m", "--mesh", default="fine", choices=["fine", "coarse"], help="Mesh resolution (fine or coarse)")
    parser_obj.add_argument("-mx", "--multiaxial", action="store_true", help="Enable multiaxial mode for lesioned/atrophied brains")
    parser_obj.add_argument("-g", "--gui", action="store_true", help="Launch interactive GUI to verify landmark registration")
    parser_obj.add_argument("-t2", "--t2", default="", help="Path to T2 MRI volume for better segmentation")
    parser_obj.add_argument("-lf", "--leadfield", action="store_true", help="Generate lead field matrix for optimization")
    parser_obj.add_argument("--roast-ver", choices=["3.0", "4.0"], default="3.0", help="ROAST engine version (3.0 or 4.0)")

def main():
    parser = argparse.ArgumentParser(description="iSATA Automated Pipeline CLI Toolbox")
    
    # Top-level arguments optional so subcommands can handle their own -i and -o
    add_roast_arguments(parser, is_required=False)

    subparsers = parser.add_subparsers(dest="command", help="Pipeline Step Commands")

    # Subcommands
    parser_all = subparsers.add_parser("run-all", help="Run entire pipeline (ROAST -> ACPC -> MNI-DTDI -> DNTE)")
    add_roast_arguments(parser_all, is_required=True)

    parser_roast = subparsers.add_parser("roast", help="Step 1: Run ROAST Simulation (Phase 1)")
    add_roast_arguments(parser_roast, is_required=True)

    parser_acpc = subparsers.add_parser("acpc", help="Step 2: AC-PC Landmark Detection (Phase 2)")
    parser_acpc.add_argument("-i", "--input", required=True, help="Output results directory to process")

    parser_mni = subparsers.add_parser("mni-dtdi", help="Step 3: MNI Mapping & Regional DTDI Calculation (Phase 3)")
    parser_mni.add_argument("-i", "--input", required=True, help="Output results directory to process")

    parser_dnte = subparsers.add_parser("dnte", help="Step 4: Functional Network Analysis - DNTE (Phase 4)")
    parser_dnte.add_argument("-i", "--input", required=True, help="Output results directory to process")

    args = parser.parse_args()

    cmd = args.command
    if not cmd:
        if not args.input or not args.output:
            parser.error("the following arguments are required: -i/--input, -o/--output")
        cmd = "run-all"

    roast_kwargs = {
        "roast_ver": getattr(args, "roast_ver", "3.0"),
        "anode": getattr(args, "anode", "CP5"),
        "cathode": getattr(args, "cathode", "Cz"),
        "current": getattr(args, "current", 2.0),
        "size": getattr(args, "size", "50 50 3"),
        "pad": getattr(args, "pad", None),
        "mesh": getattr(args, "mesh", "fine"),
        "multiaxial": getattr(args, "multiaxial", False),
        "gui": getattr(args, "gui", False),
        "t2": getattr(args, "t2", ""),
        "leadfield": getattr(args, "leadfield", False)
    }

    if cmd in ["run-all", "roast"]:
        run_roast_phase(args.input, args.output, **roast_kwargs)
        if cmd == "run-all":
            run_acpc_phase(args.output)
            run_mni_dtdi_phase(args.output)
            run_dnte_phase(args.output)
    elif cmd == "acpc":
        run_acpc_phase(args.input)
    elif cmd == "mni-dtdi":
        run_mni_dtdi_phase(args.input)
    elif cmd == "dnte":
        run_dnte_phase(args.input)

if __name__ == "__main__":
    main()
