function table_out = se_TabList(X,Y,Z)

global st;
global MAP;
global SPM;
global xSPM;
global CLUSTER;
global SATA_PATH;
global TALAIRACH_PATH;
SATA_CBL_check_init;

addpath([SATA_PATH filesep 'Utilities' filesep 'spm12' filesep 'toolbox' filesep 'Anatomy'], '-end');

MapName = [SATA_PATH filesep 'Utilities' filesep 'spm12' filesep 'toolbox' filesep 'Anatomy' filesep 'Anatomy_v22c_MPM.mat'];
se_getMap('anat',MapName);

X_col = ones(length(X),1);
Y_col = ones(length(X),1);
Z_col = ones(length(X),1);
label_col = cell(length(X),1);
counter = 1;

Orig = 2;
if Orig == 1
    XYZmm = [X Y Z]';
else
    XYZmm = [X Y-4 Z+5]';
end
descDa = 0;

xyz = inv(MAP(1).MaxMap.mat) * [XYZmm; ones(1,size(XYZmm,2))] ;


for PM = 1:size(MAP,2)
    ProbMax(1:size(xyz,2),PM+1) = spm_sample_vol(MAP(PM).PMap,xyz(1,:),xyz(2,:),xyz(3,:),0)' * 100;
end
ProbMax(:,1) = spm_sample_vol(MAP(1).MaxMap,xyz(1,:),xyz(2,:),xyz(3,:),0)'; ProbMax(:,1) = ProbMax(:,1) .* (ProbMax(:,1) > 99);



for indxx  = 1:size(XYZmm,2)
    
        not_assigned = true;
            X_col(counter) = XYZmm(1,indxx);
            Y_col(counter) = XYZmm(2,indxx)+4;
            Z_col(counter) = XYZmm(3,indxx)-5;
    

    ML = round(spm_sample_vol(MAP(1).Macro,xyz(1,indxx),xyz(2,indxx),xyz(3,indxx),0)');
    if ML > 0;
        ML1 = MAP(1).MLabels.Labels{ML};
        label_col{counter} = ML1;
        counter = counter +1;
        not_assigned = false;
    else

    if any(ProbMax(indxx,:))
        Probs = find(ProbMax(indxx,2:end)>0); [value sortP]= sort(ProbMax(indxx,Probs+1));
        for getPr = size(Probs,2):-1:1
            [Ploc, Pmin, Pmax] = MinMax(MAP(Probs(sortP(getPr))).PMap,xyz(:,indxx));
            if getPr == size(Probs,2)
                woAssign = repmat(' ',10,1);
                if ProbMax(indxx,1)
                    woAssign(1:length(MAP(Probs(sortP(getPr))).name)) = MAP(Probs(sortP(getPr))).name;
                    label_col{counter} = '*'; %strip(woAssign');
                    counter = counter +1;
                    not_assigned = false;
                end
            end
        end
    end
    end
    
    if not_assigned
        label_col{counter} = '*';
        counter = counter +1;
    end
end
X_col = X_col(1:counter-1);
Y_col = Y_col(1:counter-1);
Z_col = Z_col(1:counter-1);
label_col = label_col(1:counter-1);
table_out = table(X_col,Y_col,Z_col,label_col);





function [Ploc, Pmin, Pmax] = MinMax(map,tmp)
sample = spm_sample_vol(map,...
    [tmp(1)-1 tmp(1) tmp(1)+1 tmp(1)-1 tmp(1) tmp(1)+1 tmp(1)-1 tmp(1) tmp(1)+1 ...
    tmp(1)-1 tmp(1) tmp(1)+1 tmp(1)-1 tmp(1) tmp(1)+1 tmp(1)-1 tmp(1) tmp(1)+1 ...
    tmp(1)-1 tmp(1) tmp(1)+1 tmp(1)-1 tmp(1) tmp(1)+1 tmp(1)-1 tmp(1) tmp(1)+1], ....
    [tmp(2)-1 tmp(2)-1 tmp(2)-1 tmp(2) tmp(2) tmp(2) tmp(2)+1 tmp(2)+1 tmp(2)+1 ...
    tmp(2)-1 tmp(2)-1 tmp(2)-1 tmp(2) tmp(2) tmp(2) tmp(2)+1 tmp(2)+1 tmp(2)+1 ...
    tmp(2)-1 tmp(2)-1 tmp(2)-1 tmp(2) tmp(2) tmp(2) tmp(2)+1 tmp(2)+1 tmp(2)+1], ...
    [tmp(3)-1 tmp(3)-1 tmp(3)-1 tmp(3)-1 tmp(3)-1 tmp(3)-1 tmp(3)-1 tmp(3)-1 tmp(3)-1 ...
    tmp(3) tmp(3) tmp(3) tmp(3) tmp(3) tmp(3) tmp(3) tmp(3) tmp(3) ...
    tmp(3)+1 tmp(3)+1 tmp(3)+1 tmp(3)+1 tmp(3)+1 tmp(3)+1 tmp(3)+1 tmp(3)+1 tmp(3)+1],...
    0)*100;
Pmin = min(sample);
Pmax = max(sample);
Ploc =  sample(14);