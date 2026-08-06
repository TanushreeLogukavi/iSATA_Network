function file_out = SATA_CBL_FT_Rewrite(folder,file)
%SATA_CBL_FT_Rewrite(folder,file)
%
%   Purpose: Read and rewrite the RAS image obtained from ROAST. Carried 
%   out to make acpcdetect more consistent.
%
%   Input:
%       folder  - path to the simulation folder
%       file    - name of the mri file
%
%   Output:
%       ft_converted_image_path - path to the resulting mri image 
%
%   if you have any queries please contact clinicalbrainlab@gmail.com

    mri = ft_read_mri([folder filesep file]);

    cfg.filetype = 'nifti';
    cfg.filename = [folder filesep 'ftOut'];
    cfg.parameter = 'anatomy';

    ft_volumewrite(cfg,mri);
    file_out = [folder filesep cfg.filename];
    
end

