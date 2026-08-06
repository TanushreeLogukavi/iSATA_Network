function weighted_table = SATA_CBL_Coords_With_High_MCD_MNI(Montage)
%SATA_CBL_coords_with_high_mcd(Montage,brain_region,threshold,fid1,fid2,fid3,method)
%
%   Purpose: Plot the top 12 weighted current densities as a bar plot and 
%   their corresponding coordinates as a scatterplot.
%
%   Input:
%       Montage         -   montage data output from comets/roast
%       brain_region    -   region of the brain to be checked
%       threshold  -   threshold to be applied to current density array
%                       from Montage
%       (Optional - used while tranforming the head)
%       pt1             -   fiducial pt1(ac/NAS)
%       pt2             -   fiducial pt2(pc/LPA)
%       pt3             -   fiducial pt3(mid sagital/RPA)
%       method          -   method used for conversion in fieldtrip
%
%   Example of Use:
%       load (“SATA\examples\CP5_CZ_5_5.mat”);
%       SATA_CBL_avg_CD_per_Lobe(CP5_CZ_5_5, "Cerebrum", 0.5);
%       SATA_CBL_avg_CD_per_Lobe(CP5_CZ_5_5, "Cerebellum", 0.5);
%
%   For any queries please contact clinicalbrainlab@gmail.com
global SATA_PATH
% extracting the Current density values and the vertices
CD_array = Montage.Target.FaceVertexCData;
Vertices = Montage.Target.Vertices;
threshold = 1;

% thresholding coordinates
[thresholded_coords,CD_array] = SATA_CBL_Coords_Above_Threshold(CD_array,Vertices,threshold);

% feildtrip function
[h6, ~] = ft_headcoordinates(Montage.ISATA.AC, Montage.ISATA.PC, Montage.ISATA.MSP, 'spm');

% adding spm12 to path (required for CBL_cor2mni and CBL_mni2tal)
addpath([ SATA_PATH filesep 'Utilities' filesep 'spm12']);

% tranforming the coordinates
mni = SATA_CBL_cor2mni(Vertices, h6);
mni = fix(mni);
MNI_Vert_1_Fix= fix(mni);


table_out = se_TabList(MNI_Vert_1_Fix(:,1),MNI_Vert_1_Fix(:,2),MNI_Vert_1_Fix(:,3));
%% 
table_out.RecordNumber = (1:1:height(table_out))';

table_out.ori_x = thresholded_coords(:,1);
table_out.ori_y = thresholded_coords(:,2);
table_out.ori_z = thresholded_coords(:,3);


%% 
% measuring CD values and plotting for all gyri in a given brain region
weighted_table = SATA_CBL_Extract_Plot_WCD_Gyri_MNI(MNI_Vert_1_Fix,CD_array,table_out,'');
end

