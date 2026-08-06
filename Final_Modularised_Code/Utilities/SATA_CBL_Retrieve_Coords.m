function [Coordinates,Electric_Field] = SATA_CBL_Retrieve_Coords(e_pos_file,node,elem)
% SATA_CBL_Retrieve_Coords(e_pos_file,node,elem)
%
%   Purpose: retrieve the brain coordinates and electric field values
%   from a folder containing roast output.
%
%   Input:
%       e_pos_file  - path string OR dir struct to the *e.pos file
%       node        - node field from ROAST .mat file
%       elem        - elem field from ROAST .mat file

ind = elem(elem(:,5)==2,1:4);
ind = unique(ind(:));
Coordinates = node(ind,1:3);

if isstruct(e_pos_file)
    e_path = fullfile(e_pos_file.folder, e_pos_file.name);
else
    e_path = e_pos_file;
end

f = fopen(e_path);
if f == -1
    error('Could not open electric field file: %s', e_path);
end

e = textscan(f,'%d %f %f %f');
fclose(f);

a = e{1}; a(1)=[];
b = e{2}; b(1)=[];
c = e{3}; c(1)=[];
d = e{4}; d(1)=[];

e_data = [double(a) b c d];
e_data = e_data(ind,:);
Electric_Field = sqrt(e_data(:,4).^2 + e_data(:,2).^2 + e_data(:,3).^2);

end
