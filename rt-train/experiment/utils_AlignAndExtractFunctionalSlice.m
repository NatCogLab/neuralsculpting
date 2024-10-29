function [ slice, found, loaded, specificFile, times ] = utils_AlignAndExtractFunctionalSlice( PARAMS, dicomDir, scanNum, tr, cutoffTime, hook )
% (c) Coraline Rinn Iordan 09/2017, 11/2017, 04/2018 (no GZIP, optimized timing)

%%%%% REQUIREMENTS -- DURING PREVIOUS PROTOTYPE PREPROCESSING:
% pick functional template from middle of prototype run
% align functional template to localizer anat (extant, collected previous day or earlier in the session) -- this takes ~4 min. with 3dAllineate
% resample functional template to 3.0mm iso
% resample localizer to functional template grid
%%%%% files required in PARAMS.TEMPLATEDIR: PARAMS.PROTOTYPE.TEMPLATE (reference EPI), PARAMS.LOCALIZER.TEMPLATE (localizer mask in AFNI / NIFTI format)

if nargin < 5, hook = 0; end

startTime = GetSecs;

% Initialize retrieved slice
slice = nan; loaded = 0; times.dcm = 0; times.align = 0; times.extract = 0; times.total = 0; times.found = 0;

% Wait until file is available or until we get too close to next TR to keep waiting, query every 10 ms
[ found, specificFile ] = utils_FindDicomFile( dicomDir, scanNum, tr );
while ~found && GetSecs < cutoffTime
    pause( PARAMS.LOOPDELAY );
    [ found, specificFile ] = utils_FindDicomFile( dicomDir, scanNum, tr );
end

% The file was not written to disk and/or accessible before time ran out for processing
if ~found
    times.total = GetSecs - startTime;
    fprintf( 'TR %d :: %d | TOT %1.2f\n', tr, found, times.total );
    return
% else
%     file = dir( specificFile ); times.stamp{ scanNum, tr } = file.date;
end

times.found = GetSecs - startTime;

% If DICOM file is found, pause 150 ms to complete transfer to disk
pause( PARAMS.DISKDELAY );

% Generate NIFTI file from current DICOM and store in PARAMS.NIFTIDIR
niftiFile = sprintf( 'nifti%2.2i_%4.4i', scanNum, tr );
[ statusDCM, ~ ] = unix( sprintf( '%s/dcm2niix -f %s -o %s -s y %s', PARAMS.DCMPATH, niftiFile, PARAMS.NIFTIDIR, specificFile ) );
times.dcm = GetSecs - times.found - PARAMS.DISKDELAY - startTime;

% Resample current NIFTI to functional template from Prototype run
[ statusRES, ~ ] = unix( sprintf( '%s/3dresample -master %s/%s+orig -inset %s/%s.nii.gz -prefix %s/%s_resamp+orig', PARAMS.AFNIPATH, PARAMS.TEMPLATEDIR, PARAMS.PROTOTYPE.TEMPLATE, PARAMS.NIFTIDIR, niftiFile, PARAMS.NIFTIDIR, niftiFile ) );
times.resample = GetSecs - times.dcm - startTime;

% This should take ~300-350ms for standard 64x64x36 EPI grid; it will take longer on larger grids
% Align resampled NIFTI file to functional template
if hook, [ statusAGN, ~ ] = unix( sprintf( '%s/3dvolreg -twopass -1Dmatrix_save transform.aff12.1D -base %s/%s+orig -input %s/%s_resamp+orig -prefix %s/%s_resamp_aligned+orig', PARAMS.AFNIPATH, PARAMS.TEMPLATEDIR, PARAMS.PROTOTYPE.TEMPLATE, PARAMS.NIFTIDIR, niftiFile, PARAMS.NIFTIDIR, niftiFile ) );
else [ statusAGN, ~ ] = unix( sprintf( '%s/3dAllineate -1Dmatrix_apply transform.aff12.1D -base %s/%s+orig -source %s/%s_resamp+orig -prefix %s/%s_resamp_aligned+orig -final NN', PARAMS.AFNIPATH, PARAMS.TEMPLATEDIR, PARAMS.PROTOTYPE.TEMPLATE, PARAMS.NIFTIDIR, niftiFile, PARAMS.NIFTIDIR, niftiFile ) );
end;
times.align = GetSecs - times.resample - startTime;

% Extract localizer voxels from current TR aligned to reference TR from Prototype run
[ statusXTR, ~ ] = unix( sprintf( '%s/3dmaskdump -mask %s/%s+orig %s/%s_resamp_aligned+orig > %s/slice%2.2i_%4.4i.txt', PARAMS.AFNIPATH, PARAMS.TEMPLATEDIR, PARAMS.LOCALIZERTEMPLATE, PARAMS.NIFTIDIR, niftiFile, PARAMS.PROCESSDIR, scanNum, tr ) );
data = load( sprintf( '%s/slice%2.2i_%4.4i.txt', PARAMS.PROCESSDIR, scanNum, tr ) );
slice = data( :, 4 ); loaded = 1; % remove position values; slice = numRelevantVoxels x 1 (after removal of voxels that were zeroed out at model build time)
times.extract = GetSecs - times.align - startTime;

times.total = GetSecs - startTime;
fprintf( 'TR %d :: FOUND [%d:%1.2f] | DELAY %1.2f | DCM[%d] %1.2f | RES [%d] %1.2f | AGN[%d] %1.2f | XTR[%d] %1.2f | TOT %1.2f\n', tr, found, times.found, PARAMS.DISKDELAY, statusDCM, times.dcm, statusRES, times.resample, statusAGN, times.align, statusXTR, times.extract, times.total );
