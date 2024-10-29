function [ found, specificFile ] = utils_FindDicomFile( dicomDir, scanNum, tr )
% (c) Coraline Rinn Iordan 06/2018
%
% check if specified dicom file exists in 'dicomDir'

specificFile = [ dicomDir '/001_0000' num2str( scanNum, '%2.2i' ) '_00' num2str( tr, '%4.4i' ) '.dcm' ]; % intelrt.pni
if exist( specificFile, 'file' ), found = 1; else found = 0; end
