import click
import os
import glob
import roast_engine
import acpc
import mni_dtdi  # Phase 3 logic
import dnte      # Phase 4 logic

@click.group()
def isata():
    """i-SATA Research Suite: Computational Neuroscience Tools for PPA-FTD."""
    pass

# --- PHASE 1: ROAST (Renamed from main to roast) ---
@isata.command(name='roast')
@click.option('--input', '-i', help='Path to T1 .nii or directory', required=True)
@click.option('--t2', '-t2', help='Path to T2 .nii file (optional)', default=None)
@click.option('--output', '-o', help='Directory for results', required=True)
@click.option('--anode', '-a', default='CP5')
@click.option('--cathode', '-k', default='Cz')
@click.option('--current', '-c', default=2.0, type=float)
@click.option('--type', '-t', default='pad')
@click.option('--size', '-s', default='50 50 3')
@click.option('--cap', '-cap', default='1005')
@click.option('--multiaxial', '-mx', is_flag=True)
@click.option('--gui', '-g', is_flag=True)
@click.option('--leadfield', '-lf', is_flag=True)
@click.option('--padding', '-p', default=20, type=int)
@click.option('--resample', '-r', default='on')
def roast_cmd(input, t2, output, current, anode, cathode, type, size, cap, multiaxial, gui, leadfield, padding, resample):
    """Phase 1: Individualized E-field modeling using ROAST 4.0."""
    nii_files = []
    if os.path.isdir(input):
        nii_files = glob.glob(os.path.join(input, "*.nii"))
    elif os.path.isfile(input):
        nii_files = [input]

    elec_size_list = [float(x) for x in size.split()]

    for nii_path in nii_files:
        try:
            roast_engine.run_roast_phase(
                input_file=nii_path, t2_file=t2, output_dir=output, 
                current=current, anode=anode, cathode=cathode, 
                elec_type=type, elec_size=elec_size_list, cap_type=cap,
                use_mx=multiaxial, use_gui=gui, is_lf=leadfield, 
                padding=padding, resample=resample
            )
        except Exception as e:
            click.secho(f"Error: {str(e)}", fg='red')

# --- PHASE 2: ACPC ---
@isata.command(name='acpc')
@click.option('--input', '-i', help='Path to iSATA_Results folder', required=True)
def acpc_cmd(input):
    """Phase 2: Batch AC-PC Detection via WSL/ART."""
    
    # 1. Filter for valid subject folders
    subject_folders = [f.path for f in os.scandir(input) 
                       if f.is_dir() and not os.path.basename(f.path).startswith('c')]
    
    if not subject_folders:
        click.secho("❌ No subject folders found!", fg='red')
        return

    click.secho(f"🎯 Detecting AC-PC for {len(subject_folders)} subjects...", fg='yellow', bold=True)

    # 2. Start MATLAB Engine ONCE for the whole batch
    import matlab.engine
    click.echo("  > Initializing MATLAB Engine...")
    eng = matlab.engine.start_matlab()

    try:
        for folder in subject_folders:
            roast_dir = os.path.join(folder, 'roast')
            if os.path.exists(roast_dir):
                click.secho(f"\n--- Processing: {os.path.basename(folder)} ---", fg='cyan')
                # IMPORTANT: Pass BOTH the engine and the directory
                acpc.run_acpc_batch(eng, roast_dir) 
            else:
                click.echo(f"  ⚠️ Skipping: No 'roast' folder in {os.path.basename(folder)}")
    finally:
        click.echo("\n  > Closing MATLAB Engine...")
        eng.quit()
# --- PHASE 3: MNI-DTDI ---
@isata.command(name='mni-dtdi')
@click.option('--input', '-i', help='Path to iSATA_Results folder', required=True)
def mni_dtdi_cmd(input):
    """Phase 3: Map E-field to MNI and calculate Regional DTDI."""
    subject_folders = [f.path for f in os.scandir(input) if f.is_dir()]
    for folder in subject_folders:
        roast_dir = os.path.join(folder, 'roast')
        if os.path.exists(roast_dir):
            mni_dtdi.run_mni_dtdi_batch(roast_dir)

# --- PHASE 4: DNTE ---
@isata.command(name='dnte')
@click.option('--input', '-i', help='Path to iSATA_Results folder', required=True)
def dnte_cmd(input):
    """Phase 4: Functional Network Mapping (DNTE)."""
    subject_folders = [f.path for f in os.scandir(input) if f.is_dir()]
    for folder in subject_folders:
        roast_dir = os.path.join(folder, 'roast')
        if os.path.exists(roast_dir):
            dnte.run_dnte_batch(roast_dir)

# --- THE CRITICAL FIX: MOVE THIS TO THE VERY END ---
if __name__ == '__main__':
    isata()
