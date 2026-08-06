function DTDI = SATA_CBL_Get_Region_DTDI(TargetRegion, TableIn)
%SATA_CBL_Get_Region_DTDI Get the DTDI value for the target region

    binvec = strcmp(TargetRegion, TableIn.Gyrus);
    maxCurrent = max(TableIn.weighted);
    minCurrent = min(TableIn.weighted);

    currentTarget = TableIn.weighted(binvec);
    DTDI = (currentTarget-minCurrent)/(maxCurrent-minCurrent);
end