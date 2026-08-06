function Montage_Path = SATA_CBL_ISATA_Preprocess(folder_path)
%SATA_CBL_ISATA_Preprocess(folder_path)
%   
%   Purpose: Create a SATA compatible montage for a simulation on an
%   individual MRI image.
%
%   Inputs:
%       folder_path - path to the simulation folder
%
%   Outputs:
%       Montage_path - path to the SATA compatible montage.
%
%
%   For any queries please contact clinicalbrainlab@gmail.com
SATA_CBL_Call_ACPCDETECT(folder_path);
Montage_Path = SATA_CBL_Create_ISATA_Montage(folder_path);

end

