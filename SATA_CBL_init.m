function SATA_CBL_init
% SATA_CBL_init: Initializes paths for SATA, SPM12, FieldTrip, and ROAST (3.0 or 4.0).
global SATA_PATH TALAIRACH_PATH ROAST_PATH COMETS_PATH ROAST_VERSION

% Suppress stale path warning logs
warning('off', 'MATLAB:path:notFound');
warning('off', 'MATLAB:dispatcher:nameConflict');

% Remove FieldTrip compat folder from path to avoid shadowing built-in MATLAB string/graphics functions
p_str = path;
p_cell = split(p_str, pathsep);
for k = 1:length(p_cell)
    if contains(p_cell{k}, ['fieldtrip' filesep 'compat'])
        rmpath(p_cell{k});
    end
end

cur_path = cd;
if contains(cur_path, 'SATA')
    addpath(cur_path);
    SATA_PATH = cur_path;
    disp('Found! SATA is your current directory, adding to path...');
else
    temp_path = split(path,';');
    binary = contains(temp_path,'SATA');
    required = temp_path(binary);
    for x = 1:length(required)
        if contains(required{x}, 'SATA')
            SATA_PATH = required{x};
            disp('Found! SATA is already in your path!');
            break;
        end
    end
    if isempty(SATA_PATH)
        SATA_PATH = pwd;
        addpath(SATA_PATH);
    end
end

TALAIRACH_PATH = [SATA_PATH filesep 'Utilities' filesep 'Talairach'];
COMETS_PATH = [SATA_PATH filesep 'Comets'];

% Support both ROAST 3.0 and ROAST 4.0 dynamically
if ~isempty(ROAST_VERSION) && (strcmp(ROAST_VERSION, '4.0') || strcmp(ROAST_VERSION, '4'))
    ROAST_PATH = [SATA_PATH filesep 'roast-4.0'];
    fprintf('ROAST Version 4.0 selected: %s\n', ROAST_PATH);
else
    ROAST_PATH = [SATA_PATH filesep 'roast-3.0'];
    fprintf('ROAST Version 3.0 selected: %s\n', ROAST_PATH);
end

addpath(ROAST_PATH);
addpath([SATA_PATH filesep 'Final_Modularised_Code'], [SATA_PATH filesep 'Final_Modularised_Code' filesep 'Utilities']);
addpath([SATA_PATH filesep 'Utilities' filesep 'fieldtrip'], ...
        [SATA_PATH filesep 'Utilities' filesep 'fieldtrip' filesep 'fileio'], ...
        [SATA_PATH filesep 'Utilities' filesep 'fieldtrip' filesep 'utilities'], ...
        [SATA_PATH filesep 'Utilities' filesep 'spm12']);
disp('SATA initialised!');
end
