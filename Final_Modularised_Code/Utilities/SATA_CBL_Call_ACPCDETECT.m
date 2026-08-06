function SATA_CBL_Call_ACPCDETECT(folder_path)
%UNTITLED Summary of this function goes here
%   
%   Purpose: Call acpcdetect software on the reuired MRI image
%
%   Inputs:
%           folder_path - path to the simulation folder
%                       
%   Outputs:
%           Output files from acpcdetect including a *ACPC.txt file.
%
%   Example of Use:
%
%   For any queries please contact clinicalbrainlab@gmail.com

SATA_CBL_check_init;
global SATA_PATH;

directoryIn = dir([folder_path filesep '*1mm.nii']);
if length(directoryIn) == 1
    file_out = SATA_CBL_FT_Rewrite(directoryIn.folder, directoryIn.name);
else
    directoryIn = dir([folder_path filesep '*RAS.nii']);
    if length(directoryIn) == 1
        file_out = SATA_CBL_FT_Rewrite(directoryIn.folder, directoryIn.name);
    else
        directoryIn = dir([folder_path filesep '*ras.nii']);
        file_out = SATA_CBL_FT_Rewrite(directoryIn.folder, directoryIn.name);
    end
end

system(['export ARTHOME=' SATA_PATH filesep 'Utilities' filesep 'ART' ' ; export PATH=$ARTHOME/bin:$PATH ; acpcdetect -i ' folder_path filesep 'ftOut.nii'])

end

