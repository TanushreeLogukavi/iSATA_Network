function [Coordinates,Electric_Field] = SATA_CBL_Retrieve_Coords(e_pos_file,node,elem)
%SATA_CBL_Retrieve_Coords(e_pos_file,node,elem)
%
%   Purpose: retrieve the brain coordinates and electric field values
%   from a folder containing roast output.
%
%   Input:
%       e_pos_file  - path to the simulation folder
%       node        - node field from ROAST .mat file
%       elem        - elem field from ROAST .mat file
%
%   Output:
%       coordinatesYouNeed  - coordinates of the brain
%       Electric_field      - norm values of the coordinates corresponding
%                             to the coordinates of th brain.
%
%   if you have any queries please contact clinicalbrainlab@gmail.com
    

ind = elem(elem(:,5)==2,1:4);
ind = unique(ind(:));
Coordinates = node(ind,1:3);

f = fopen([e_pos_file.folder filesep e_pos_file.name]);
e = textscan(f,'%d %f %f %f');
a = e{1};
a(1)=[];
b = e{2};
b(1)=[];
c = e{3};
c(1)=[];
d = e{4};
d(1)=[];
e = [double(a) b c d];
e = e(ind,:);
Electric_Field = sqrt(e(:,4).^2 + e(:,2).^2+ e(:,3).^2);

end

