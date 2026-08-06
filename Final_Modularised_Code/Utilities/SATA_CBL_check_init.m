function PATHS = SATA_CBL_check_init
% SATA_CBL_check_init
%   
%   Pupose: Check if SATA_CBL_init has been called.
global SATA_PATH TALAIRACH_PATH ROAST_PATH COMETS_PATH;
if isempty(SATA_PATH)
    error('Please run the initialise command (SATA_CBL_init) after adding SATA to Path.');
end
PATHS = {SATA_PATH, TALAIRACH_PATH, ROAST_PATH, COMETS_PATH};
end