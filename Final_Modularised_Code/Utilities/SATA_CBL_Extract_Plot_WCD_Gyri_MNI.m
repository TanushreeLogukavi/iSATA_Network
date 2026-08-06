function weighted_table = SATA_CBL_Extract_Plot_WCD_Gyri_MNI(Vertices1,CD_array,tal_in,brain_region)
%SATA_CBL_Extract_Plot_Mean_Std_Gyri(CD_array,tal_in,brain_region)
%
%   Purpose:  extract the Weighted current density and plot them for
%             all gyri. Also plot the gyri on a scatter plot
%
%   Inputs:
%       tal_in          -     table of coordinates outputted from the
%                             talairach client
%       CD_array        -     input array of current density values
%       brain_region    -     Region of the brain to be
%       Vertices1       -     The overall coordinates after conversion to
%                             talairach's format
%
%   Outputs:
%       mean_std_table  -     table containg the weigthed current density
%                             of different gyri
%
%   if you have any queries please contact clinicalbrainlab@gmail.com

brain_parts=1;


% extracting unique values of the different GYRI
lev3_values = unique(table2array(tal_in(:,'label_col')));
lev3_values(ismember(lev3_values,'*')) = [];
lev3_values(ismember(lev3_values,'')) = [];

% number of unique gyri
l = length(lev3_values);

% initialising the Gyrus column
Gyrus=cell(l,1);

% initialising the weighted mean column
weighted = zeros(l,1);

center_of_mass_x = zeros(l,1);
center_of_mass_y = zeros(l,1);
center_of_mass_z = zeros(l,1);

% counter counting the number of columns that have been deleted
deled=0;

for x=1:l
    count = 0;
    records1=[];
    records2=[];

    % checking if the filters are valid for left hemisphere. if so return
    % the corresponding recordnumbers, else return empty array

    try
        evalc('records1 = SATA_CBL_Filter(tal_in,''RecordNumber'',{{''label_col'',lev3_values(x)}}).'';');
    catch
        count= count+1;
    end


    % if both sets of record numbers are empty, delete the corresponding
    % column
    if count==brain_parts
        Gyrus(x-deled)=[];
        weighted(x-deled)=[];
%         center_of_mass_x(x-deled) = [];
%         center_of_mass_y(x-deled) = [];
%         center_of_mass_z(x-deled) = [];
        deled=deled+1;
        continue
    end

    % if atleast one column is not empty make an approprite addition to the
    % arrays
    records = union(records1,records2);
    temp = CD_array(records);
    Gyrus{x-deled}=char(lev3_values(x));
    weighted(x-deled)=mean(temp);%length(temp)*
%     center_of_mass_x(x-deled) = mean(tal_in.ori_x(records));
%     center_of_mass_y(x-deled) = mean(tal_in.ori_y(records));
%     center_of_mass_z(x-deled) = mean(tal_in.ori_z(records));

end


% return -1 if there are no coordinates
if isempty(Gyrus)
    weighted_table = -1;
    return
end

% form the table
weighted_table = table(Gyrus,weighted);

% sorting accoring to descending
[~, weighted_order] = sort(weighted);
weighted_order = flip(weighted_order);
l = length(Gyrus);

% taking top 12
if l>12
    weighted_table = sortrows(weighted_table,'weighted','descend');
    Gyrus = weighted_table.Gyrus(1:12);
    l=12;
    weighted = weighted_table.weighted(1:12);       
end
disp(Gyrus);
% sorting accoring to descending
[~, weighted_order] = sort(weighted);
weighted_order = flip(weighted_order);

% getting gyri in correct order for plotting
Gyrus_2 =categorical(Gyrus,'Ordinal',false);
Gyrus = reordercats(Gyrus_2,Gyrus(weighted_order,:));

% plotting
figure('Name','figure1','Position',[100 150 720 480]);
hold on

% creating the colors for the plot
k = ceil(l/2);

b1 =zeros(k,1);
g1 =((1:k)./k).';
r1 = (ones(1,k)-(1:k)./k).';

g2 = (ones(1,l-k)-(1:l-k)./(l-k)).';
r2 = zeros(l-k,1);
b2 = ((1:l-k)./(l-k)).';

r= [r1;r2];
g= [g1;g2];
b=[b1;b2];

col = [r g b];

% plotting the bar graph
Gyrus_temp = Gyrus(weighted_order);

weighted_temp = weighted(weighted_order);

for k =1:l
    h = bar(Gyrus_temp(k),weighted_temp(k));
    set(h,'FaceColor',col(k,:));
end

ylabel('Average Current Density');
hold off

%% plotting the coordinates

figure('Name','figure2','Position',[900 150 540 384]);

coordinates= Vertices1;
scatter3(coordinates(:,1),coordinates(:,2), coordinates(:,3),30,...
    'MarkerEdgeColor',[.4 .4 .4],...
    'MarkerFaceColor',[0.8 0.8 0.8],'MarkerFaceAlpha',.2, 'MarkerEdgeAlpha',1);
hold on;

% assuming discrete brain region i.e. left/right is being used

Vertices2 = [];
cd = [];
store= cell(l,2);
count=0;

for k =1:l
    
    Gyrus_temp = string(Gyrus_temp);
    evalc('records1 = SATA_CBL_Filter(tal_in,''RecordNumber'',{{''label_col'',lev3_values(x)}}).'';');
    evalc('coords = SATA_CBL_Filter(tal_in,{''RecordNumber'',''X_col'',''Y_col'',''Z_col''},{{''label_col'',char(Gyrus_temp(k))}});');
    records = coords(:,1);
    [~,w] =size(coords);
    coords = coords(:,2:w);
    
    %count = count+length(coords);
    store(k,1)={coords};
    [le,~]=size(coords);
    store(k,2)={le};
    Vertices2 = [Vertices2;coords];
    cd = [cd; CD_array(records,:)];
%     scatter3(coords(:,1),coords(:,2),...
%         coords(:,3),'MarkerEdgeColor', col(k,:),'MarkerFaceColor',col(k,:));
    
    hold on;
end

% %% detecting outliers
% coords = Vertices2;
% x = coords(:,1);
% z = coords(:,3);
% y = coords(:,2);
% 
% xp = mean(x);
% yp = mean(y);
% zp = mean(z);
% 
% distances = ((x-xp).^2 + (y-yp).^2+ (z-zp).^2)./cd; 
% 
% binary_vector = isoutlier(distances,"mean");
% for k =1:l
%     sep = cell2mat(store(k,2));
%     cur_bin_vec = binary_vector(1:sep);
%     binary_vector = binary_vector(sep:end);
%     coords = cell2mat(store(k,1));
%     coords = coords(~cur_bin_vec,:);
%     scatter3(coords(:,1),coords(:,2),...
%         coords(:,3),'MarkerEdgeColor', col(k,:),'MarkerFaceColor',col(k,:));
%     hold on;
% end


for k =1:l
    coords = cell2mat(store(k,1));
    scatter3(coords(:,1),coords(:,2),...
        coords(:,3),'MarkerEdgeColor', col(k,:),'MarkerFaceColor',col(k,:));
    hold on;
end

%% final display
view ([-90 0 0])
colormap(col)
for k =1:length(weighted_temp)
    weighted_temp(k) = round(weighted_temp(k),2);
end

c = colorbar();
c.Ticks = (1:l)/l;
c.TickLabels = string(weighted_temp);
set( c, 'YDir', 'reverse' );

hold off;