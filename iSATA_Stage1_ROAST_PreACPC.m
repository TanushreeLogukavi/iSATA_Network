%% iSATA Stage 1: ROAST Simulation -> Pre-ACPC Preparation
% Purpose: Automate ROAST simulation (supports ROAST 3.0 and ROAST 4.0) and NIfTI header rewrite.
% Inputs supported:
%   - Individual Mode: Single .nii file path (e.g., 'D:\PPA_PARTICIPANT\isata\Ind_dose_T1\sub01_T1w.nii')
%   - Batch Mode: Directory path containing .nii files (e.g., 'D:\PPA_PARTICIPANT\isata\Ind_dose_T1\')
% Output:
%   - Subject-specific output folder: output_base_dir/[sub_name]/roast/
%   - Pre-ACPC standardized NIfTI (ftOut.nii), mesh (.mat), and field solution (*e.pos)

global SATA_PATH ROAST_PATH ROAST_VERSION;

% Optional: ROAST Version Selection ('3.0' or '4.0')
if ~exist('roast_ver_input', 'var') || isempty(roast_ver_input)
    roast_ver_input = '3.0';
end
ROAST_VERSION = roast_ver_input;

SATA_CBL_init;

%% ==================== 1. USER CONFIGURATION ====================
if ~exist('mri_input', 'var') || isempty(mri_input)
    mri_input = 'D:\PPA_PARTICIPANT\isata\Ind_dose_T1\sub01_T1w.nii'; 
end
if ~exist('output_base_dir', 'var') || isempty(output_base_dir)
    output_base_dir = 'D:\PPA_PARTICIPANT\isata\iSATA_results';
end

% Dose / Stimulation Parameters (defaults or passed from Python/MATLAB workspace)
if ~exist('anode_input', 'var') || isempty(anode_input), anode_input = 'CP5'; end
if ~exist('cathode_input', 'var') || isempty(cathode_input), cathode_input = 'Cz'; end
if ~exist('current_input', 'var') || isempty(current_input), current_input = 2; end
if ~exist('size_input', 'var') || isempty(size_input), size_input = [50 50 3]; end
if ~exist('padding_input', 'var') || isempty(padding_input), padding_input = []; end
if ~exist('resolution_input', 'var') || isempty(resolution_input), resolution_input = 'fine'; end
if ~exist('multiaxial_input', 'var'), multiaxial_input = 0; end
if ~exist('gui_input', 'var'), gui_input = 0; end
if ~exist('t2_input', 'var'), t2_input = ''; end
if ~exist('leadfield_input', 'var'), leadfield_input = 0; end

electrode_loc1   = anode_input;               % Anode location
anode_current    = current_input;             % Current in mA
electrode_loc2   = cathode_input;             % Cathode location
cathode_current  = -current_input;            % Current in mA
electrode_type   = 'pad';                     % Electrode shape

if ischar(size_input) || isstring(size_input)
    electrode_size = str2num(size_input);
else
    electrode_size = size_input;
end
cap_type         = '1005';                    % EEG cap layout system

% Construct ROAST option cell array dynamically
roast_opts = {'electype', electrode_type, 'elecsize', electrode_size, 'captype', cap_type, 'resampling', 'on'};

if ~isempty(padding_input)
    roast_opts = [roast_opts, {'padding', padding_input}];
end
if multiaxial_input
    roast_opts = [roast_opts, {'multiaxial', 'on'}];
end
if gui_input
    roast_opts = [roast_opts, {'gui', 'on'}];
end
if ~isempty(t2_input)
    roast_opts = [roast_opts, {'t2', t2_input}];
end
if leadfield_input
    roast_opts = [roast_opts, {'simulation', 'leadfield'}];
end

%% ==================== 2. AUTO-DETECT INPUT TYPE ====================
if isfolder(mri_input)
    all_nii = dir(fullfile(mri_input, '*.nii'));
    nii_files = [];
    for k = 1:length(all_nii)
        fname = all_nii(k).name;
        if ~startsWith(fname, 'c1') && ~startsWith(fname, 'c2') && ~startsWith(fname, 'c3') && ...
           ~startsWith(fname, 'c4') && ~startsWith(fname, 'c5') && ~startsWith(fname, 'c6') && ...
           ~contains(fname, 'mask') && ~contains(fname, 'ftOut') && ~endsWith(fname, '_e.nii') && ...
           ~endsWith(fname, '_emag.nii') && ~endsWith(fname, '_v.nii') && ~endsWith(fname, '_1mm.nii') && ...
           ~endsWith(fname, '_RAS.nii')
            nii_files = [nii_files; all_nii(k)];
        end
    end
    if isempty(nii_files)
        error('No primary .nii files found in batch directory: %s', mri_input);
    end
    fprintf('=== BATCH MODE DETECTED: Found %d primary .nii scan(s) ===\n', length(nii_files));
elseif isfile(mri_input)
    [parent_dir, fname, fext] = fileparts(mri_input);
    nii_files = struct('name', [fname, fext], 'folder', parent_dir);
    fprintf('=== INDIVIDUAL MODE DETECTED: Processing %s ===\n', fname);
else
    error('Specified mri_input path does not exist: %s', mri_input);
end

%% ==================== 3. STAGE 1 PROCESSING LOOP ====================
for i = 1:length(nii_files)
    nii_file_name = nii_files(i).name;
    [~, sub_name, ~] = fileparts(nii_file_name);
    full_input_path = fullfile(nii_files(i).folder, nii_file_name);
    
    subject_roast_dir = fullfile(output_base_dir, sub_name, 'roast');
    if ~exist(subject_roast_dir, 'dir')
        mkdir(subject_roast_dir);
    end
    
    fprintf('\n--------------------------------------------------\n');
    fprintf('Processing [%d/%d]: %s (ROAST Engine %s)\n', i, length(nii_files), sub_name, ROAST_VERSION);
    fprintf('Input:  %s\n', full_input_path);
    fprintf('Output: %s\n', subject_roast_dir);
    fprintf('--------------------------------------------------\n');
    
    % Check if complete ROAST simulation already exists
    has_ftout = exist(fullfile(subject_roast_dir, 'ftOut.nii'), 'file');
    e_pos_files = dir(fullfile(subject_roast_dir, '*e.pos'));
    has_epos = ~isempty(e_pos_files);
    
    if has_ftout && has_epos
        fprintf('[OK] Complete ROAST simulation already exists for %s in %s. Skipping Phase 1.\n', sub_name, subject_roast_dir);
        continue;
    end
    
    % Copy original MRI scan to subject roast directory
    target_nii = fullfile(subject_roast_dir, nii_file_name);
    if ~exist(target_nii, 'file')
        copyfile(full_input_path, target_nii);
    end
    
    % Ensure cap location files are available in subject_roast_dir
    cap_file = fullfile(ROAST_PATH, 'cap1005FullWithExtra.mat');
    if exist(cap_file, 'file') && ~exist(fullfile(subject_roast_dir, 'cap1005FullWithExtra.mat'), 'file')
        copyfile(cap_file, fullfile(subject_roast_dir, 'cap1005FullWithExtra.mat'));
    end
    
    % --- Step A: Run ROAST Simulation inside Subject Roast Folder ---
    original_folder = cd(subject_roast_dir);
    try
        roast(target_nii, {electrode_loc1, anode_current, electrode_loc2, cathode_current}, roast_opts{:});
        
        % Save generated figures
        all_figs = findobj('Type', 'figure');
        if ~isempty(all_figs)
            fig_save_name = fullfile(subject_roast_dir, [sub_name, '_plots.mat']);
            save(fig_save_name, 'all_figs');
            saveas(all_figs(1), fullfile(subject_roast_dir, [sub_name, '_3D_Render.png']));
            close(all_figs);
        end
    catch ME
        warning('ROAST failed for %s: %s', sub_name, ME.message);
        cd(original_folder);
        continue;
    end
    cd(original_folder);
    
    % --- Step B: FieldTrip Rewrite (Header Standardization Pre-ACPC) ---
    search_patterns = {'*1mm.nii', '*RAS.nii', '*ras.nii', '*.nii'};
    found_file = false;
    
    for p = 1:length(search_patterns)
        target = dir(fullfile(subject_roast_dir, search_patterns{p}));
        if ~isempty(target)
            fprintf('Standardizing NIfTI Header with FieldTrip: %s\n', target(1).name);
            file_out = SATA_CBL_FT_Rewrite(target(1).folder, target(1).name);
            
            [~, o_n, o_e] = fileparts(file_out);
            ft_file = [o_n, o_e];
            
            if exist(fullfile(subject_roast_dir, ft_file), 'file')
                fprintf('ftOut.nii generated cleanly in %s.\n', subject_roast_dir);
            end
            found_file = true;
            break;
        end
    end
    
    if ~found_file
        warning('Could not find NIfTI volume to rewrite for %s', sub_name);
    else
        fprintf('Stage 1 Complete for %s.\n', sub_name);
    end
end

fprintf('\n==================================================\n');
fprintf('Stage 1 Complete! Run Python ACPC detection next.\n');
fprintf('==================================================\n');
