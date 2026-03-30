% PURPOSE: Parses the ART/acpcdetect output text file for voxel indices.
function [AC, PC] = SATA_acpc_extract(filepath)
    % Initialize outputs
    AC = []; PC = [];
    
    fid = fopen(filepath, 'r');
    if fid == -1
        warning('Could not open file: %s', filepath);
        return; % Exit function if file is missing
    end

    tline = fgetl(fid);
    while ischar(tline)
        % Search for AC Voxel Label
        if contains(tline, '# AC (i,j,k) voxel location:', 'IgnoreCase', true)
            tline = fgetl(fid); % Move to next line for data
            AC = sscanf(tline, '%f %f %f');
        
        % Search for PC Voxel Label
        elseif contains(tline, '# PC (i,j,k) voxel location:', 'IgnoreCase', true)
            tline = fgetl(fid); % Move to next line for data
            PC = sscanf(tline, '%f %f %f');
        end
        tline = fgetl(fid);
    end
    fclose(fid);
    
    % Ensure coordinates are horizontal (1x3) for ROAST/iSATA compatibility
    if ~isempty(AC), AC = AC(:)'; end
    if ~isempty(PC), PC = PC(:)'; end
    
    % Verification display
    if ~isempty(AC) && ~isempty(PC)
        disp('Extracted Coordinates:');
        disp(['AC: ', num2str(AC)]);
        disp(['PC: ', num2str(PC)]);
    end
end