%% iSATA Stage 2: Post-ACPC MNI Mapping, Network Engagement & DTDI Calculation
% Purpose: Processes post-ACPC mesh data, loads AC/PC coordinates, performs MNI 
%          coordinate mapping, samples against AAL atlas, and uses the Network Atlas 
%          (aal_MNI_V4_Network.mat) via iSATA_MNI_Network to compute NwCD and DNTE.
% Inputs supported:
%   - Individual Mode: Single .nii file path (e.g., 'D:\PPA_PARTICIPANT\isata\Ind_dose_T1\sub01_T1w.nii')
%   - Batch Mode: Directory path containing subject folders (e.g., 'D:\PPA_PARTICIPANT\isata\iSATA_results')
% Output:
%   - Processed_Results subfolder in subject directory containing:
%     1. [sub_name]_DNTE_Results.mat (Tables: DNTE_mni and DNTE_dtdi)
%     2. [sub_name]_NwCD.fig / [sub_name]_DNTE.fig (Interactive MATLAB figures)
%     3. [sub_name]_DNTE_Results_Plots.png (High-res publication image)

global SATA_PATH ROAST_PATH;

% Suppress stale path warnings
warning('off', 'MATLAB:path:notFound');
warning('off', 'MATLAB:dispatcher:nameConflict');

SATA_CBL_init;

%% ==================== 1. USER CONFIGURATION ====================
if ~exist('mri_input', 'var') || isempty(mri_input)
    mri_input = 'D:\PPA_PARTICIPANT\isata\Ind_dose_T1\sub01_T1w.nii'; 
end
if ~exist('output_base_dir', 'var') || isempty(output_base_dir)
    output_base_dir = 'D:\PPA_PARTICIPANT\isata\iSATA_results';
end

%% ==================== 2. AUTO-DETECT INPUT TYPE & SUBJECT DIRS ====================
subject_roast_dirs = {};
sub_names = {};

if isfile(mri_input)
    [parent_dir, fname, ~] = fileparts(mri_input);
    sub_name = fname;
    target_dir = fullfile(output_base_dir, sub_name, 'roast');
    if ~exist(target_dir, 'dir')
        target_dir = parent_dir;
    end
    subject_roast_dirs = {target_dir};
    sub_names = {sub_name};
    fprintf('=== INDIVIDUAL MODE DETECTED: Processing %s ===\n', sub_name);
elseif isfolder(mri_input)
    % Directory Input: Search for roast subfolders containing ACPC_coordinates.mat or ftOut.nii
    ftout_list = dir(fullfile(mri_input, '**', 'ftOut.nii'));
    if isempty(ftout_list)
        ftout_list = dir(fullfile(mri_input, '**', 'ACPC_coordinates.mat'));
    end
    if isempty(ftout_list)
        ftout_list = dir(fullfile(mri_input, '**', '*.nii'));
    end
    
    if isempty(ftout_list)
        error('No subject directories or NIfTI files found in: %s', mri_input);
    end
    
    seen_dirs = {};
    for k = 1:length(ftout_list)
        curr_dir = ftout_list(k).folder;
        if ~any(strcmp(seen_dirs, curr_dir))
            seen_dirs{end+1} = curr_dir;
            [parent_dir, folder_name, ~] = fileparts(curr_dir);
            if strcmp(folder_name, 'roast')
                [~, sname, ~] = fileparts(parent_dir);
            else
                sname = folder_name;
            end
            subject_roast_dirs{end+1} = curr_dir;
            sub_names{end+1} = sname;
        end
    end
    fprintf('=== BATCH MODE DETECTED: Found %d subject directory(ies) ===\n', length(subject_roast_dirs));
else
    error('Specified mri_input path does not exist: %s', mri_input);
end

%% ==================== 3. NETWORK ATLAS SELECTION ====================
net_atlas_file = which('aal_MNI_V4_Network.mat');
if isempty(net_atlas_file)
    net_atlas_file = fullfile(SATA_PATH, 'aal_MNI_V4_Network.mat');
end
if ~exist(net_atlas_file, 'file')
    net_atlas_file = fullfile(SATA_PATH, 'Final_Modularised_Code', 'aal_MNI_V4_Network.mat');
end

atlas_nii = fullfile(SATA_PATH, 'Utilities', 'spm12', 'toolbox', 'wfu_pickatlas', 'MNI_atlas_templates', 'aal_MNI_V4.nii');
atlas_mat = fullfile(SATA_PATH, 'Utilities', 'spm12', 'toolbox', 'wfu_pickatlas', 'MNI_atlas_templates', 'legacy', 'aal_MNI_V4_List.mat');

fprintf('Using Network Atlas: %s\n', net_atlas_file);

%% ==================== 4. STAGE 2 PROCESSING LOOP ====================
for i = 1:length(subject_roast_dirs)
    subject_roast_dir = subject_roast_dirs{i};
    sub_name = sub_names{i};
    
    [parent_subject_dir, folder_name, ~] = fileparts(subject_roast_dir);
    if strcmp(folder_name, 'roast')
        subject_parent_dir = parent_subject_dir;
    else
        subject_parent_dir = subject_roast_dir;
    end
    
    processed_output_dir = fullfile(subject_parent_dir, 'Processed_Results');
    if ~exist(processed_output_dir, 'dir')
        mkdir(processed_output_dir);
    end
    
    fprintf('\n--------------------------------------------------\n');
    fprintf('Stage 2 Processing [%d/%d]: %s\n', i, length(subject_roast_dirs), sub_name);
    fprintf('Folder: %s\n', subject_roast_dir);
    fprintf('--------------------------------------------------\n');
    
    % --- Step A: Load ACPC Coordinates ---
    acpc_mat_file = fullfile(subject_roast_dir, 'ACPC_coordinates.mat');
    if exist(acpc_mat_file, 'file')
        acpc_data = load(acpc_mat_file);
        AC = acpc_data.AC;
        PC = acpc_data.PC;
    else
        try
            [AC, PC] = SATA_CBL_Read_ACPC(subject_roast_dir);
        catch
            warning('ACPC coordinates not found for %s. Skipping subject.', sub_name);
            continue;
        end
    end
    
    % --- Step B: Load Mesh Data ---
    mat_files = dir(fullfile(subject_roast_dir, '*.mat'));
    node = []; elem = [];
    for x = 1:length(mat_files)
        file_to_check = fullfile(subject_roast_dir, mat_files(x).name);
        try
            data = load(file_to_check);
            if isfield(data, 'mesh')
                node = data.mesh.node; elem = data.elem; break;
            elseif isfield(data, 'node')
                node = data.node; elem = data.elem; break;
            end
        catch
            continue;
        end
    end
    if isempty(node)
        warning('Mesh data missing for %s. Skipping subject.', sub_name);
        continue;
    end
    
    % --- Step C: Retrieve Electric Field Vectors ---
    e_pos_files = dir(fullfile(subject_roast_dir, '*e.pos'));
    if isempty(e_pos_files)
        warning('Electric field file (*e.pos) missing for %s. Skipping subject.', sub_name);
        continue;
    end
    e_pos_file = fullfile(e_pos_files(1).folder, e_pos_files(1).name);
    [Coordinates, Electric_Field] = SATA_CBL_Retrieve_Coords(e_pos_file, node, elem);
    
    % --- Step D: Construct iSATA Structure ---
    ISATA_Montage = struct();
    ISATA_Montage.Target.FaceVertexCData = Electric_Field;
    ISATA_Montage.Target.Vertices = Coordinates;
    ISATA_Montage.ISATA.AC = AC;
    ISATA_Montage.ISATA.PC = PC;
    ISATA_Montage.ISATA.MSP = SATA_CBL_Detect_MSP(Coordinates, AC, PC);
    ISATA_Montage.sub_id = sub_name;
    
    % --- Step E: Check Step 3 (MNI-DTDI) Prerequisites & Execute if Needed ---
    mni_mat_file = fullfile(processed_output_dir, [sub_name, '_MNI.mat']);
    dtdi_mat_file = fullfile(processed_output_dir, [sub_name, '_DTDI.mat']);
    
    if exist(mni_mat_file, 'file') && exist(dtdi_mat_file, 'file')
        mni_data = load(mni_mat_file);
        dtdi_data = load(dtdi_mat_file);
        mni_table_all = mni_data.weighted_table;
        DTDI_all = dtdi_data.DTDI_table;
        fprintf('[OK] Step 3 MNI data found for %s. Proceeding to Step 4...\n', sub_name);
    else
        fprintf('[AUTO-RUN] Step 3 MNI Mapping & Regional DTDI not found. Automatically running Step 3 for %s...\n', sub_name);
        [mni_table_all, DTDI_all] = SATA_CBL_Coords_With_High_MCD_MNI_atlas(ISATA_Montage, atlas_nii, atlas_mat, processed_output_dir);
    end
    
    % --- Step F & G: Step 4 Functional Network Analysis (NwCD & DNTE) ---
    fprintf('Executing Step 4 (Functional Network Analysis - NwCD & DNTE) for %s...\n', sub_name);
    [DNTE_mni, DNTE_dtdi] = iSATA_MNI_Network(mni_table_all, net_atlas_file, sub_name, processed_output_dir);
    
    % --- Step H: Save Combined Results ---
    base_name = [sub_name, '_DNTE_Results'];
    try
        save(fullfile(processed_output_dir, [base_name, '.mat']), 'DNTE_mni', 'DNTE_dtdi', 'mni_table_all', 'DTDI_all');
        fprintf('Successfully saved Network Atlas results (.mat & figures) for %s in %s.\n', sub_name, processed_output_dir);
    catch ME
        warning('Export failed for %s: %s', sub_name, ME.message);
    end
end

fprintf('\n==================================================\n');
fprintf('Stage 2 Complete! Network Atlas calculation finished.\n');
fprintf('==================================================\n');
