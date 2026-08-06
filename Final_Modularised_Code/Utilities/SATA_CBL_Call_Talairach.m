function table_out = SATA_CBL_Call_Talairach(mat_in)
%CBL_call_talairach(mat_in)
%
%   Purpose: integrates the talairach client with MATLAB
%
%   Inputs:
%       mat_in      -     table of coordinates to be fed into the talairach
%                         client
%
%   Outputs:
%       table_out   -     talairach client's output in the form of a MATLAB
%                         table
%
%   Processess:
%       -The function opens up the talairach client
%       -The user has to choose the input file as 
%        Choose this input file.txt
%       -The setting to be choosen is the nearest gray matter
%       -The user must click the search button and close the talairach
%        client
%
%   if you have any queries please contact clinicalbrainlab@gmail.com

str = computer('arch');

SATA_CBL_check_init;

global TALAIRACH_PATH;

% writing the matrix into a text file to be read using the talairach client

dlmwrite([TALAIRACH_PATH filesep 'Choose this input file.txt'],mat_in,'delimiter','\t');

% starting the talairach client
%creates dialog box as a GUI
mydlg = warndlg('Close Talairach, and then close this to continue execution');

switch str
    case 'win64'
        system([TALAIRACH_PATH filesep 'talairach.jar']);
    case 'maci64'
        system(['open ' TALAIRACH_PATH filesep 'talairach.jar']);
    case 'glnxa64'
        system(['java -jar ' TALAIRACH_PATH filesep 'talairach.jar']);
end

if ~strcmp(str,'win64')
    
    waitfor(mydlg);

    % reading in the output of the talairach client
    table_out = readtable([TALAIRACH_PATH filesep 'Choose this input file.td.txt'],'Delimiter','\t');

    % deleting the files created during the usage of this function
    system(['rm ' TALAIRACH_PATH filesep '"Choose this input file.txt"']);
    system(['rm ' TALAIRACH_PATH filesep '"Choose this input file.td.txt"']);

else
    
    waitfor(mydlg);

    % reading in the output of the talairach client
    table_out = readtable([TALAIRACH_PATH filesep 'Choose this input file.td.txt'],'Delimiter','\t');

    % deleting the files created during the usage of this function
    system(['del ' TALAIRACH_PATH filesep 'Choose this input file.txt']);
    system(['del ' TALAIRACH_PATH filesep 'Choose this input file.td.txt']);

end
end