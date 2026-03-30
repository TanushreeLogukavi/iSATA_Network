import matlab.engine
import os
import click
import shutil
import glob
from datetime import datetime

def run_roast_phase(input_file, t2_file, output_dir, current, anode, cathode, elec_type, elec_size, cap_type, use_mx, use_gui, is_lf, padding, resample):
    # 1. SETUP PATHS
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    lib_dir = os.path.join(base_dir, 'lib')
    spm_path = os.path.join(lib_dir, 'Utilities', 'spm12')
    roast_path = os.path.join(lib_dir, 'roast-4.0', 'roast-4.0')
    
    subject_name = os.path.splitext(os.path.basename(input_file))[0]
    unique_tag = f"iSATA_{subject_name}_{datetime.now().strftime('%H%M%S')}"
    final_dest = os.path.join(output_dir, subject_name, 'roast')
    
    if not os.path.exists(final_dest): os.makedirs(final_dest)

    eng = matlab.engine.start_matlab()
    
    try:
        # 2. MATLAB INIT
        eng.restoredefaultpath(nargout=0)
        eng.addpath(lib_dir, nargout=0)
        eng.addpath(spm_path, nargout=0)
        eng.addpath(roast_path, nargout=0)
        eng.setenv('PATH', f"{os.path.join(roast_path, 'bin', 'win')};{os.environ.get('PATH', '')}", nargout=0)
        
        eng.workspace['SATA_PATH'] = lib_dir
        eng.workspace['ROAST_PATH'] = roast_path
        eng.SATA_CBL_init(nargout=0)
        eng.cd(roast_path, nargout=0)

        # 3. BUILD RECIPE & PARAMS
        recipe = 'leadField' if is_lf else [anode, matlab.double([current]), cathode, matlab.double([-current])]
        
        params = {
            'electype': elec_type,
            'elecsize': matlab.double(elec_size),
            'captype': cap_type,
            'zeropadding': float(padding),
            'resampling': resample,
            'simulationTag': unique_tag,
            'multiaxial': 'on' if use_mx else 'off',
            'manualGui': 'on' if use_gui else 'off'
        }
        if t2_file: params['T2'] = t2_file

        click.secho(f"  Running ROAST for {subject_name}...", fg='yellow')
        
        # Call ROAST with dynamic arguments
        eng.roast(input_file, recipe, *[item for pair in params.items() for item in pair], nargout=0)

        # 4. EXPORT VISUALS
        save_path_clean = final_dest.replace('\\', '/')
        eng.eval("figs = findall(0, 'Type', 'figure');", nargout=0)
        eng.eval(f"""
        for i = 1:length(figs)
            try
                baseFigName = fullfile('{save_path_clean}', ['Visual_' num2str(i)]);
                savefig(figs(i), [baseFigName '.fig']);
                exportgraphics(figs(i), [baseFigName '.png'], 'Resolution', 300);
            catch, end
        end
        """, nargout=0)

        # 5. ORGANIZE DATA
        input_dir = os.path.dirname(input_file)
        for f in glob.glob(os.path.join(input_dir, f"{subject_name}*")):
            if f.lower() != input_file.lower():
                shutil.move(f, os.path.join(final_dest, os.path.basename(f)))

        click.secho(f"✅ Success!", fg='green')
        
    finally:
        eng.quit()
