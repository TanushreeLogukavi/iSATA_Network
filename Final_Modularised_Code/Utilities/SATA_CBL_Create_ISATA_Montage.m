function Montage_path = SATA_CBL_Create_ISATA_Montage(folder_path)
%SATA_CBL_Create_ISATA_Montage(folder_path)
%   
%   Purpose: Create a SATA compatible montage for a simulation on an
%   individual MRI image after calling acpcdetect.
%
%   Inputs:
%       folder_path - path to the simulation folder
%
%   Outputs:
%       Montage_path - path to the SATA compatible montage.
%
%   For any queries please contact clinicalbrainlab@gmail.com

[AC,PC] = SATA_CBL_Read_ACPC(folder_path);

a = dir([folder_path filesep '*.mat']);
for x = 1:length(a)
    if a(x).name(end-10)=="T" && ~isnan(str2double(a(x).name(end-11)))&& ~isnan(str2double(a(x).name(end-9)))
        load([folder_path filesep a(x).name])
    end
end
e_pos_file = dir([folder_path filesep '*e.pos']);

[Coordinates,Electric_Field] = SATA_CBL_Retrieve_Coords(e_pos_file,node,elem);
MSP = SATA_CBL_Detect_MSP(Coordinates, AC, PC);


ISATA_Montage = [];
ISATA_Montage.Target.FaceVertexCData = Electric_Field;
ISATA_Montage.Target.Vertices = Coordinates;
ISATA_Montage.ISATA.AC = AC;
ISATA_Montage.ISATA.PC = PC;
ISATA_Montage.ISATA.MSP = MSP;
disp([folder_path filesep 'ISATA_Montage'])
save(char([folder_path filesep 'ISATA_Montage']));

Montage_path = [folder_path filesep 'ISATA_Montage.mat'];

end

