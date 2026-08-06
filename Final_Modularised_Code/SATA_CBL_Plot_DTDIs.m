function SATA_CBL_Plot_DTDIs(TableIn)
%SATA_CBL_PLOT_DTDIS Plot the DTDI values for each gyrus

    maxCurrent = max(TableIn.weighted);
    minCurrent = min(TableIn.weighted);
    temp = (TableIn.weighted(1:12)-minCurrent)/(maxCurrent-minCurrent);
    l = 12;
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

    
    figure (1)
    hold on;
    for k =1:12
        h = bar(categorical(TableIn.Gyrus(k)), temp(k));
        set(h,'FaceColor',col(k,:));
    end
    ylabel('DTDI');
    hold off
end

