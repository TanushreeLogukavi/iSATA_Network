function [dnte_m, dnte_d] = iSATA_MNI_Network(mni_tab, net_path, sub_id, out_dir)
% iSATA_MNI_Network: Maps current densities to functional networks.
%
% PURPOSE:
%   This function aggregates electric field intensities (current density) from 
%   individual AAL regions into large-scale functional brain networks
%   It calculates two distinct metrics:
%   1. NwCD: Raw Network Current Density[cite: 2].
%   2. DNTE: Distributed Network Total Energy (Normalized 0-1)[cite: 2].
%   The function distinguishes between normalization within each hemisphere 
%   (Left/Right columns) and normalization against the entire brain's 
%   network-hemisphere distribution (Comb_L/Comb_R columns).
%
% INPUTS:
%   mni_tab  - Table containing AAL gyrus names and their average current 
%              densities (the 'wt' table from Step 1).
%   net_path - Path to the '.mat' file containing the 1x116 AAL network 
%              mapping struct  refer to  (Hu et al., 2024)
%   sub_id   - String identifier for the subject (e.g., 'sub02').
%   out_dir  - Path to the directory where results and figures will be saved.
%
% OUTPUTS:
%   dnte_m   - Table of raw mean intensities (NwCD) for Global, Left, and Right networks[cite: 2].
%   dnte_d   - Table of normalized intensities (DNTE) with combined hemispheric rankings.
%   Files    - Saves '[sub_id]_NwCD_DNTE.fig' (interactive pop-up figure) to out_dir. 

    % 1. Load Network Mapping
    data = load(net_path);
    ROI_struct = data.(char(fieldnames(data))); 
    network_list = struct2table(ROI_struct); 
    
    % 2. Join MNI table with Network mapping
    combined = innerjoin(mni_tab, network_list, 'Keys', 'Gyrus'); 
    
    % 3. Hemisphere Splitting
    gyrus_names = string(combined.Gyrus);
    isLeft  = endsWith(gyrus_names, '_L');
    isRight = endsWith(gyrus_names, '_R');
    
    % 4. Aggregate Raw Intensities (NwCD)
    nw_global = groupsummary(combined, 'Network', 'mean', 'Average_CD'); 
    nw_left   = groupsummary(combined(isLeft,:), 'Network', 'mean', 'Average_CD');
    nw_right  = groupsummary(combined(isRight,:), 'Network', 'mean', 'Average_CD');
    
    % --- Step A: DNTE Normalization (0-1) ---
    dnte_d = table(nw_global.Network, 'VariableNames', {'Network'});
    
    % Helper function for 0-1 scaling
    scale01 = @(x) (x - min(x)) / (max(x) - min(x));
    
    dnte_d.Global = scale01(nw_global.mean_Average_CD);
    dnte_d.Left   = scale01(nw_left.mean_Average_CD);
    dnte_d.Right  = scale01(nw_right.mean_Average_CD);
    
    % Combined Ranking (L+R pooled)
    all_raw_vals = [nw_left.mean_Average_CD; nw_right.mean_Average_CD];
    all_norm_vals = scale01(all_raw_vals);
    
    % --- Step B: NwCD Table (Raw Data Storage) ---
    dnte_m = table(nw_global.Network, nw_global.mean_Average_CD, ...
                   nw_left.mean_Average_CD, nw_right.mean_Average_CD, ...
                   'VariableNames', {'Network', 'Global', 'Left', 'Right'}); 

    % --- FIGURE 1: NwCD RAW VALUES (3 VERTICAL PLOTS) ---
    fig1 = figure('Color', 'w', 'Name', 'NwCD Analysis', 'Units', 'normalized', 'Position', [0.05 0.05 0.4 0.9]);
    
    % Global NwCD
    subplot(3,1,1); 
    [valG, idxG] = sort(dnte_m.Global, 'descend');
    XG = categorical(dnte_m.Network(idxG)); XG = reordercats(XG, string(XG));
    bar(XG, valG, 'FaceColor', [0.2 0.4 0.6]);
    ylabel('Mean CD'); title('Global NwCD '); grid on;

    % Left NwCD
    subplot(3,1,2); 
    [valL, idxL] = sort(dnte_m.Left, 'descend');
    XL = categorical(dnte_m.Network(idxL)); XL = reordercats(XL, string(XL));
    bar(XL, valL, 'FaceColor', [0.8 0.2 0.2]);
    ylabel('Mean CD'); title('Left NwCD '); grid on;

    % Right NwCD
    subplot(3,1,3); 
    [valR, idxR] = sort(dnte_m.Right, 'descend');
    XR = categorical(dnte_m.Network(idxR)); XR = reordercats(XR, string(XR));
    bar(XR, valR, 'FaceColor', [0.2 0.6 0.2]);
    ylabel('Mean CD'); title('Right NwCD '); xtickangle(45); grid on;
    
    savefig(fig1, fullfile(out_dir, [sub_id '_NwCD.fig']));

    % --- FIGURE 2: DNTE NORMALIZED (4-PANEL GRID) ---
    fig2 = figure('Color', 'w', 'Name', 'DNTE Analysis', 'Units', 'normalized', 'Position', [0.5 0.05 0.4 0.9]);
    
    % Global DNTE
    subplot(2,2,1); 
    [dvalG, didxG] = sort(dnte_d.Global, 'descend');
    DXG = categorical(dnte_d.Network(didxG)); DXG = reordercats(DXG, string(DXG));
    bar(DXG, dvalG, 'FaceColor', [0.2 0.4 0.6], 'LineWidth', 1.2);
    title('Global DNTE'); grid on;

    % Left DNTE
    subplot(2,2,2); 
    [dvalL, didxL] = sort(dnte_d.Left, 'descend');
    DXL = categorical(dnte_d.Network(didxL)); DXL = reordercats(DXL, string(DXL));
    bar(DXL, dvalL, 'FaceColor', [0.8 0.2 0.2], 'LineWidth', 1.2);
    title('Left DNTE'); grid on;

    % Right DNTE
    subplot(2,2,3); 
    [dvalR, didxR] = sort(dnte_d.Right, 'descend');
    DXR = categorical(dnte_d.Network(didxR)); DXR = reordercats(DXR, string(DXR));
    bar(DXR, dvalR, 'FaceColor', [0.2 0.6 0.2], 'LineWidth', 1.2);
    title('Right DNTE'); xtickangle(45); grid on;

    % Combined L vs R DNTE
    subplot(2,2,4);
    all_labels = [strcat('L-', dnte_d.Network); strcat('R-', dnte_d.Network)];
    [sorted_vals, sort_idx] = sort(all_norm_vals, 'descend');
    DX_Comb = categorical(all_labels(sort_idx)); DX_Comb = reordercats(DX_Comb, string(DX_Comb));
    bar(DX_Comb, sorted_vals, 'FaceColor', [0.5 0.2 0.7], 'LineWidth', 1.2);
    title('L vs R Combined'); xtickangle(45); grid on;
    
    savefig(fig2, fullfile(out_dir, [sub_id '_DNTE.fig']));
end