function transformed_coords = SATA_CBL_Transform(Vertices, transformation_matrix)
%SATA_CBL_Transform(Vertices, transformation_matrix)
%   
%   Purpose: Transform the coordinates from a given system to the talairach
%   system
%
%   Inputs:
%       Vertices             - Coordinates to be transformed
%       tranformation_matrix - the tansformation matrix obtained from
%                              fieltrip
%
%   Outputs:
%       transformed_coords   - Coordinates after tranformation
%
%   Example of Use:
%
%   if you have any queries please contact clinicalbrainlab@gmail.com

SATA_CBL_check_init;
global SATA_PATH

% adding spm12 to path (required for CBL_cor2mni and CBL_mni2tal)
addpath([ SATA_PATH filesep 'Utilities' filesep 'spm12']);

% tranforming the coordinates
mni = SATA_CBL_cor2mni(Vertices, transformation_matrix);
mni = fix(mni);
MNI_Vert_1_Fix= fix(mni);

% output of transformation
transformed_coords = SATA_CBL_mni2tal(MNI_Vert_1_Fix);

end

