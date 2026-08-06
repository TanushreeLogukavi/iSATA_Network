function [AC,PC] = SATA_CBL_Read_ACPC(folder_path)
%SATA_CBL_Read_ACPC(folder_path)
%
%   Purpose: Read AC, PC Coordinates from the ACPC file in the given
%   folder path
%
%   Input:
%       folder_path  - path to the simulation folder
%
%   Output:
%       AC  - coordinates of the anterior commissure point
%       PC  - coordinates of the posterior commissure point
%
%   Example of Use: 
%        
%
%   if you have any queries please contact clinicalbrainlab@gmail.com
    ACPC_file = dir([folder_path filesep '*ACPC.txt']);
    f = fopen([folder_path filesep ACPC_file.name],'r');
    t = {};
    temp = fgets(f);
    while temp~=-1
        t = [t temp];
        temp = fgets(f);
    end

    AC = str2num(t{12});
    PC = str2num(t{15});
end

