import os
import glob
import click
import re
import subprocess
import matlab.engine

def run_acpc_batch(eng, subject_roast_dir): # Added 'eng' here
    # 1. Precise path for the ART tool inside WSL
    art_bin_linux = "/mnt/d/Tanu_iSATA/lib/Utilities/ART/bin/acpcdetect"
    
    # 2. Setup MATLAB paths (only needs to happen once, but safe here)
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    fieldtrip_path = os.path.join(base_dir, 'lib', 'Utilities', 'fieldtrip')
    sata_utils_path = os.path.join(base_dir, 'lib', 'Final_Modularised_Code', 'Utilities')
    
    eng.addpath(fieldtrip_path, nargout=0)
    eng.addpath(sata_utils_path, nargout=0)

    # 3. Search for the NIfTI file
    patterns = ['*1mm.nii', '*_SPM_MNI.nii', '*RAS.nii', '*T1w.nii', 'sub02_T1w.nii']
    target_file = None
    for p in patterns:
        found = glob.glob(os.path.join(subject_roast_dir, p))
        if found:
            target_file = found[0]
            break

    if not target_file:
        click.secho(f"  ❌ No MRI found in {subject_roast_dir}", fg='red')
        return

    # 4. Run FieldTrip Rewrite (Standardize Header)
    click.echo(f"  > Normalizing: {os.path.basename(target_file)}")
    eng.SATA_CBL_FT_Rewrite(subject_roast_dir, os.path.basename(target_file), nargout=0)

    # 5. Run ACPC Detect via WSL
    ft_out_file = os.path.join(subject_roast_dir, "ftOut.nii")
    l_path = ft_out_file.replace('\\', '/').replace('D:', '/mnt/d').replace('d:', '/mnt/d')
    
    click.echo("  > Running ART acpcdetect via WSL...")
    # Using -no_ppm to prevent the "Aborted" crash
    linux_cmd = f"export ARTHOME='/mnt/d/Tanu_iSATA/lib/Utilities/ART' && {art_bin_linux} -i '{l_path}' -no_ppm"
    
    subprocess.run(["wsl", "bash", "-c", linux_cmd], capture_output=True, text=True)

    # 6. Parse coordinates
    txt_path = os.path.join(subject_roast_dir, "ftOut_ACPC.txt")
    if os.path.exists(txt_path):
        with open(txt_path, 'r') as f:
            content = f.read()
            ac_match = re.search(r'AC.*voxel location:[\s\n]+([\d.-]+)\s+([\d.-]+)\s+([\d.-]+)', content, re.IGNORECASE)
            pc_match = re.search(r'PC.*voxel location:[\s\n]+([\d.-]+)\s+([\d.-]+)\s+([\d.-]+)', content, re.IGNORECASE)
            
            if ac_match and pc_match:
                ac_list = [float(ac_match.group(1)), float(ac_match.group(2)), float(ac_match.group(3))]
                pc_list = [float(pc_match.group(1)), float(pc_match.group(2)), float(pc_match.group(3))]
                
                eng.workspace['AC'] = matlab.double(ac_list)
                eng.workspace['PC'] = matlab.double(pc_list)
                save_path = os.path.join(subject_roast_dir, 'ACPC_coordinates.mat').replace('\\', '/')
                eng.eval(f"save('{save_path}', 'AC', 'PC');", nargout=0)
                click.secho(f"  ✅ Saved ACPC_coordinates.mat", fg='green')
