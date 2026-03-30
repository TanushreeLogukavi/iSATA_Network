import matlab.engine
import os
import click

def run_dnte_batch(subject_roast_dir):
    """
    PURPOSE:
        Executes the Functional Network Intensity analysis (SATA_networks) for a subject
        via the MATLAB Engine. This maps MNI voxel data to network scales (0-1).

    INPUT:
        subject_roast_dir - String. Path to the subject's folder containing 
                            'MNI_DTDI_Final_Results.mat'.

    OUTPUT:
        1. 'DNTE_Network_Results.mat' - Contains 'dnte_mean' and 'dnte_dist' tables.
        2. 'DNTE_Network_Rankings.png' - 4-subplot visualization of network impacts.
    """
    
    # Paths to your MATLAB libraries
    sata_lib_path = r"D:\Tanu_iSATA\lib\Final_Modularised_Code"
    utils_path = r"D:\Tanu_iSATA\lib\Final_Modularised_Code\Utilities"
    
    # The result file generated from the previous MNI-DTDI phase
    mni_mat_path = os.path.join(subject_roast_dir, 'MNI_DTDI_Final_Results.mat')
    
    if not os.path.exists(mni_mat_path):
        click.secho(f"  ❌ Missing MNI results for this subject. Run 'mni-dtdi' first.", fg='red')
        return

    click.echo(f"  > Initializing MATLAB Engine...")
    eng = matlab.engine.start_matlab()
    
    try:
        # Add library folders to MATLAB path
        eng.addpath(sata_lib_path, nargout=0)
        eng.addpath(utils_path, nargout=0)
        
        click.echo(f"  > Loading MNI table and mapping to Functional Networks...")
        
        # 1. Load the mni_results table from the .mat file
        # MATLAB load() returns a struct/dict
        data = eng.load(mni_mat_path, nargout=1)
        if 'mni_results' not in data:
            raise KeyError("The variable 'mni_results' was not found in the .mat file.")
            
        mni_tab = data['mni_results']

        # 2. Run the Network Analysis (Min-Max Normalization 0-1)
        # [dnte_m, dnte_d, fig] = SATA_networks(mni_tab)
        dnte_m, dnte_d, fig_handle = eng.SATA_networks(mni_tab, nargout=3)

        # 3. Save Network Results
        # Replace backslashes for MATLAB string compatibility
        save_path = os.path.join(subject_roast_dir, 'DNTE_Network_Results.mat').replace('\\', '/')
        
        eng.workspace['dnte_mean'] = dnte_m
        eng.workspace['dnte_dist'] = dnte_d
        eng.eval(f"save('{save_path}', 'dnte_mean', 'dnte_dist');", nargout=0)

        # 4. Save the 4-subplot Visualization
        fig_path = os.path.join(subject_roast_dir, 'DNTE_Network_Rankings.png')
        eng.saveas(fig_handle, fig_path, nargout=0)
        eng.close(fig_handle, nargout=0)

        click.secho(f"  ✅ DNTE Analysis Complete. Results and Plot saved to subject folder.", fg='green')

    except Exception as e:
        click.secho(f"  ❌ MATLAB Error: {str(e)}", fg='red')
    finally:
        eng.quit()
