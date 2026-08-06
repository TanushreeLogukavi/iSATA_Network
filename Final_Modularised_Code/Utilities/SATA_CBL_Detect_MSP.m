function MSP = SATA_CBL_Detect_MSP(Coordinates, AC, PC)
%SATA_CBL_Detect_MSP(Coordinates, AC, PC)
%   
%   Purpose: Detect the Mid Sagittal Point
%
%   Inputs:
%       Coordinates         - Coordinates of the brain
%       AC                  - Coordinates of the Anterior Commissure point
%       PC                  - Coordinates of the Posterior Commissure point
%
%   Outputs:
%       MSP                 - Coordinates of the Mid Sagittal Point
%
%   Example of Use:
%
%   For any queries please contact clinicalbrainlab@gmail.com
temp = (AC(2)-PC(2))/10;
tempcoords = Coordinates(Coordinates(:,2)<(((AC(2)+PC(2))/2)+temp) & Coordinates(:,2)>(((AC(2)+PC(2))/2)-temp),:);

tempcoords3 = tempcoords(tempcoords(:,1)<(((AC(1)+PC(1))/2)+1) & tempcoords(:,1)>(((AC(1)+PC(1))/2)-1),:);

MSP = tempcoords3(tempcoords3(:,3)==max(tempcoords3(:,3)),:);


end

