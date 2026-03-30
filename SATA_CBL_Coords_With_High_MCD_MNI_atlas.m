function [weighted_table, DTDI_table] = SATA_CBL_Coords_With_High_MCD_MNI_atlas(Montage, atlas_nii, atlas_mat, out_dir)
    % SATA_CBL_Coords_With_High_MCD_MNI_atlas: Maps E-field to AAL atlas regions.
%
% PURPOSE:
%   This function extracts electric field intensities from an individual head 
%   mesh, transforms them into MNI space using AC-PC-MSP landmarks, and 
%   samples them against the AAL atlas. It calculates the Average Current 
%   Density per region and the Distributed Target-specific Dose Intensity (DTDI)
%   to identify the top stimulated brain areas. [cite: 2026-03-21]
%
% INPUTS:
%   Montage   - Structure containing:
%               .Target.FaceVertexCData (E-field values)
%               .Target.Vertices (Mesh coordinates)
%               .ISATA (AC, PC, and MSP coordinates) [cite: 2026-03-21]
%               .sub_id (Subject identifier string)
%   atlas_nii - Path to the AAL atlas NIfTI file (.nii).
%   atlas_mat - Path to the AAL atlas label list (.mat).
%   out_dir   - Path to the directory where results and plots will be saved.
%
% OUTPUTS:
%   weighted_table - Table of Gyrus names and Average Current Density in 
%                    original atlas order.
%   DTDI_table     - Table of regions ranked by normalized DTDI values.
%   Files          - Saves '[sub_id]_MNI.mat', '[sub_id]_DTDI.mat', and 
%                    '[sub_id]_MNI_DTDI.png' to the output directory. [cite: 2026-03-21]
    % --- 1. DATA EXTRACTION & MNI TRANSFORMATION ---
    CD_array = Montage.Target.FaceVertexCData(:); 
    Vertices = Montage.Target.Vertices; 
    
    [h6, ~] = ft_headcoordinates(Montage.ISATA.AC, Montage.ISATA.PC, Montage.ISATA.MSP, 'spm');
    mni = SATA_CBL_cor2mni(Vertices, h6);
    MNI_Vert_Fix = fix(mni);

    % --- 2. VOXEL SAMPLING ---
    V = spm_vol(char(atlas_nii)); 
    inv_mat = inv(V.mat);
    vx = inv_mat * [MNI_Vert_Fix'; ones(1, size(MNI_Vert_Fix,1))];
    region_ids = round(spm_sample_vol(V, vx(1,:), vx(2,:), vx(3,:), 0))';

    % --- 3. LOAD AAL ATLAS ---
    label_data = load(atlas_mat);
    fnames = fieldnames(label_data);
    ROI = label_data.(fnames{1}); 
    num_aal_regions = length(ROI);

    % --- 4. CALCULATE MEAN CD (Actual Atlas Order) ---
    results = cell(num_aal_regions, 2); 
    for i = 1:num_aal_regions
        target_id = ROI(i).ID; 
        mask = (region_ids == target_id);
        
        results{i, 1} = ROI(i).Nom_L; % Gyrus Name
        if any(mask)
            results{i, 2} = mean(CD_array(mask)); % Average CD
        else
            results{i, 2} = 0;
        end
    end

    % Create Table (Actual Order - No Sorting)
    weighted_table = cell2table(results, 'VariableNames', {'Gyrus', 'Average_CD'});

    % --- 5. IDENTIFY SUBJECT NAME & SAVE MNI DATA IN OUT_DIR ---
    sub_name = 'Subject';
    if isfield(Montage, 'sub_id'), sub_name = Montage.sub_id; end
    
    % Use fullfile to ensure it saves in the output directory [cite: 2026-03-21]
    save(fullfile(out_dir, [sub_name, '_MNI.mat']), 'weighted_table');

    % --- 6. DTDI CALCULATION ---
    DTDI_input = weighted_table;
    DTDI_input.Properties.VariableNames{'Average_CD'} = 'weighted';
    DTDI_table = SATA_CBL_Get_Region_DTDI(DTDI_input);
    
    % Save DTDI table in output directory [cite: 2026-03-21]
    save(fullfile(out_dir, [sub_name, '_DTDI.mat']), 'DTDI_table');

    % --- 7. PLOTTING TOP 12 ---
    SATA_CBL_Plot_Top12_DTDIs(DTDI_table, sub_name, out_dir);
end

%% SUB-FUNCTION: DTDI Calculation
function DTDI = SATA_CBL_Get_Region_DTDI(TableIn)
    uniqueRegions = unique(TableIn.Gyrus, 'stable');
    maxCurrent = max(TableIn.weighted);
    minCurrent = min(TableIn.weighted);
    
    DTDI_struct = struct('Region', {}, 'Values', {});  
    
    for i = 1:numel(uniqueRegions)
        binvec = strcmp(uniqueRegions{i}, TableIn.Gyrus);
        currentTarget = TableIn.weighted(binvec);
        
        if maxCurrent > minCurrent
            dtdiValues = (currentTarget - minCurrent) / (maxCurrent - minCurrent);
        else
            dtdiValues = currentTarget * 0;
        end
        
        DTDI_struct(i).Region = uniqueRegions{i};
        DTDI_struct(i).Values = sort(dtdiValues, 'descend');
    end
    
    DTDI = struct2table(DTDI_struct);  
    [~, sortIdx] = sort(DTDI.Values, 'descend');
    DTDI = DTDI(sortIdx, :);
end

%% SUB-FUNCTION: Colorful Top 12 Plot (Updated for Out_Dir)
function SATA_CBL_Plot_Top12_DTDIs(DTDI_Table, sub_name, out_dir)
    num_plot = min(12, height(DTDI_Table));
    plotData = DTDI_Table(1:num_plot, :);
    col = jet(num_plot); 
    
    figure('Color', 'w', 'Name', ['Top 12 DTDI: ', sub_name]);
    hold on;
    for k = 1:num_plot
        h = bar(categorical(plotData.Region(k)), plotData.Values(k));
        set(h, 'FaceColor', col(k, :));
    end
    
    ylabel('Average current Density');
    xlabel('Gyrus');
    title(['Top 12 Stimulated Regions (MNI-DTDI): ', sub_name]);
    set(gca, 'TickLabelInterpreter', 'none', 'XTickLabelRotation', 45);
    grid on;
    hold off;
    
    % Save plot as PNG in the output directory
    saveas(gcf, fullfile(out_dir, [sub_name, '_MNI_DTDI.png']));
end