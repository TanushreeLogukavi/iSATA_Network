import matlab.engine
import os
import click

def run_mni_dtdi_batch(subject_roast_dir):
    """
    PURPOSE:
        Orchestrates the MNI spatial normalization and anatomical intensity analysis 
        (DTDI) for a subject. It handles environment setup, path conflict resolution, 
        and captures both internal diagnostic plots and final summary charts.

    INPUT:
        subject_roast_dir - String. Path to the subject's directory containing 
                            mesh files and ACPC coordinates.

    OUTPUT:
        1. 'MNI_DTDI_Full_Results.mat' - Contains 'mni_results' and 'dtdi_results'.
        2. 'MNI_Anatomical_Summary.png' - Bar chart of top 20 anatomical regions.
        3. Diagnostic PNGs - Saved automatically by the internal MATLAB function.
    """
    
    # Setup Paths
    sata_lib_path = r"D:\Tanu_iSATA\lib\Final_Modularised_Code"
    utils_path = r"D:\Tanu_iSATA\lib\Final_Modularised_Code\Utilities"
    spm_path = r"D:\Tanu_iSATA\lib\Utilities\spm12" 
    ft_compat_path = r"C:\Users\user\Downloads\SATA\Utilities\fieldtrip\compat"

    click.echo(f"  > Starting MATLAB for MNI Phase...")
    eng = matlab.engine.start_matlab()
    
    try:
        # 1. Add Environment Paths
        eng.addpath(sata_lib_path, nargout=0)
        eng.addpath(utils_path, nargout=0)
        eng.addpath(spm_path, nargout=0)
        
        # 2. Fix Path Conflicts (removes the 'flip' error source common in FieldTrip/SPM)
        # This ensures the correct 'flip' function is used during coordinate transforms
        eng.eval(f"warning off; if exist('{ft_compat_path}','dir'); rmpath(genpath('{ft_compat_path}')); end; warning on;", nargout=0)
        
        # 3. Initialize SATA
        eng.SATA_CBL_init(nargout=0)
        
        subj_name = os.path.basename(os.path.dirname(subject_roast_dir))
        click.echo(f"  > Processing {subj_name}...")
        
        # 4. Run Analysis
        # The MATLAB function 'SATA_mni_dtdi' now handles the 'popping' figures internally.
        mni_tab, dtdi_tab, fig_summary = eng.SATA_mni_dtdi(subject_roast_dir, nargout=3)

        # 5. Save Tables to .mat
        # We use forward slashes to ensure MATLAB's eval string handles the path correctly
        save_path = os.path.join(subject_roast_dir, 'MNI_DTDI_Full_Results.mat').replace('\\', '/')
        
        eng.workspace['mni_results'] = mni_tab
        eng.workspace['dtdi_results'] = dtdi_tab
        eng.eval(f"save('{save_path}', 'mni_results', 'dtdi_results');", nargout=0)
        
        # 6. Save Final Summary Figure
        sum_img = os.path.join(subject_roast_dir, 'MNI_Anatomical_Summary.png')
        eng.saveas(fig_summary, sum_img, nargout=0)
        eng.close(fig_summary, nargout=0)

        click.secho(f"  ✅ Complete! All plots and .mat data saved in {subj_name}/roast/", fg='green', bold=True)

    except Exception as e:
        click.secho(f"  ❌ Error: {str(e)}", fg='red')
    finally:
        eng.quit()
