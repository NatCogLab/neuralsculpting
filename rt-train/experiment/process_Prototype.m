function PARAMS = process_Prototype( subjectName, subjectID, scanNum, scanNumAnat, protoRun )
% (c) Coraline Rinn Iordan 09/2017, 10/2017, 02/2018, 04/2018
%
% Prototype run has 341 TRs total -- 335 TRs after preprocessing ; used: 49 samples @ 1 TRs / sample = 49 TRs

if nargin < 4, error( 'Must provide subject name, subject ID, Prototype scan number, and MPRAGE scan number.' ); end

% Load latest version of saved PARAMS ; should match PARAMS.INFOFILE
info.loadStartTime = GetSecs;
dateStr = [ subjectName( end - 7 : end - 4 ) '-' subjectName( end - 3 : end - 2 ) '-' subjectName( end - 1 : end ) ];
load( [ '/Data1/code/shapeBender/fmri/' subjectID '/data/info-' subjectName '-' dateStr '.mat' ] );
info.loadEndTime = GetSecs - info.loadStartTime;
fprintf( '\n%%%%%%%%%%%%% PROTOTYPE RUN %%%%%%%%%%%%%\n>> PARAMS Loaded: %.02f\n', info.loadEndTime );

% Initialize prototype run
info.scanNum = scanNum;
info.scanNumAnat = scanNumAnat;
info.protoRun = protoRun;

info.numTRs = 335;
info.specificFile = cell( info.numTRs, 1 );
info.found = nan( info.numTRs, 1 );

% % Generate and process ANAT
info.anatStartTime = GetSecs;
fprintf( '>> Preprocessing ANAT...\n' );
[ found, specificFile ] = utils_FindDicomFile( PARAMS.DICOMDIR, info.scanNumAnat, 1 ); % wait until ANAT file is available
while ~found && GetSecs
    pause( PARAMS.LOOPDELAY );
    [ found, specificFile ] = utils_FindDicomFile( PARAMS.DICOMDIR, info.scanNumAnat, 1 );
end
anatFolder = sprintf( [ PARAMS.NIFTIDIR '/anatCurrent%2.2i' ], scanNumAnat );
[ statusFOL, ~ ] = unix( sprintf( 'mkdir %s', anatFolder ) );
[ statusMOV, ~ ] = unix( sprintf( 'cp %s/001_0000%s_00*.dcm %s', PARAMS.DICOMDIR, num2str( scanNumAnat, '%2.2i' ), anatFolder ) );
[ statusDCM, ~ ] = unix( sprintf( '%s/dcm2niix -f %s -o %s -z y %s/', PARAMS.DCMPATH, PARAMS.CURRENTANAT, PARAMS.TEMPLATEDIR, anatFolder ) );
[ status3DC, ~ ] = unix( sprintf( '%s/3dcopy %s/%s.nii %s/%s+orig', PARAMS.AFNIPATH, PARAMS.TEMPLATEDIR, PARAMS.CURRENTANAT, PARAMS.TEMPLATEDIR, PARAMS.CURRENTANAT ) );
info.anatEndTime = GetSecs - info.anatStartTime;
info.statusANA = statusMOV | statusDCM | status3DC | statusFOL;
fprintf( '>> ANAT [%d] Built and ready: %3.2f\n', info.statusANA, info.anatEndTime )

% Startprocessing Prototype run
fprintf( '>> Processing PROTOTYPE run | Looking for pulse ACK from display code...\n' );

% Wait an unlimited amount of time for ack of first TR pulse from display script before starting to look for DICOMs
info.ackFile = [ PARAMS.DATADIR '/startPrototype-' subjectName '-' dateStr '.txt' ];
while ~exist( info.ackFile, 'file' ), pause( PARAMS.LOOPDELAY ); end
info.runStartTime = load( info.ackFile ); % this time stamp should match the time stamp that the display script uses to schedule Screen Flips
fprintf( '>> Pulse ACK found: %.02f! | Counting DICOMs...\n', info.runStartTime );

for tr = 1 : info.numTRs  
    [ info.found( tr ), ~ ] = utils_FindDicomFile( PARAMS.DICOMDIR, info.scanNum, tr );

    % The file was not written to disk and/or accessible before time ran out for processing
    if ~info.found( tr ), fprintf( 'TR %d NOT FOUND!', tr ); end
end

fprintf( '>> TRs found: %d / %d | Starting Processing...\n', sum( info.found ), info.numTRs )

% Generate prototype DICOM folder and make full NIFTI
nifStart = GetSecs;
prototypeFolder = sprintf( [ PARAMS.NIFTIDIR '/prototype%2.2i' ], scanNum );
[ statusFOL, ~ ] = unix( sprintf( 'mkdir %s', prototypeFolder ) );
times.fol = GetSecs - nifStart;

[ statusMOV, ~ ] = unix( sprintf( 'cp %s/001_0000%s_00*.dcm %s/prototype%s/', PARAMS.DICOMDIR, num2str( scanNum, '%2.2i' ), PARAMS.NIFTIDIR, num2str( scanNum, '%2.2i' ) ) );
times.mov = GetSecs - times.fol - nifStart;
[ statusDCM, ~ ] = unix( sprintf( '%s/dcm2niix -f %s -o %s -z y %s/', PARAMS.DCMPATH, PARAMS.PROTOTYPE.NIFTIFILE, PARAMS.NIFTIDIR, prototypeFolder ) );
times.dcm = GetSecs - nifStart - times.mov - times.fol;
[ status3DC, ~ ] = unix( sprintf( '%s/3dcopy %s/%s.nii %s/%s+orig', PARAMS.AFNIPATH, PARAMS.NIFTIDIR, PARAMS.PROTOTYPE.NIFTIFILE, PARAMS.NIFTIDIR, PARAMS.PROTOTYPE.NIFTIFILE ) );
times.tdc = GetSecs - nifStart - times.dcm - times.fol - times.mov;
times.nif = GetSecs - nifStart;
fprintf( '>> Generated Prototype AFNI file: FOL[%d] %1.2f | MOV [%d] %1.2f | DCM[%d] %1.2f | 3DC[%d] %1.2f | TOT %1.2f\n', statusFOL, times.fol, statusMOV, times.mov, statusDCM, times.dcm, status3DC, times.tdc, times.nif );

% Preprocess full NIFTI ; align to 'anatCurrent'
ppStart = GetSecs;
[ statusPRP, ~ ] = unix( sprintf( 'export PATH="%s:$PATH" ; %s/%s %s %s %s %s', PARAMS.AFNIPATH, PARAMS.SCRIPTSDIR, PARAMS.PROTOTYPE.PREPROCESSINGSCRIPT, PARAMS.NIFTIDIR, PARAMS.PROTOTYPE.NIFTIFILE, PARAMS.TEMPLATEDIR, PARAMS.CURRENTANAT ) );
times.prp = GetSecs - ppStart;
fprintf( '>> Preprocessed Prototype NIFTI file: STAT[%d] %1.2f\n', statusPRP, times.prp );

% Align processed Prototype to 'anatLocalizer' ; rename and move prototype files to final locations
qqStart = GetSecs;
[ statusQQ, ~ ] = unix( sprintf( 'export PATH="%s:$PATH" ; %s/%s %s %s %s %s %s %s', PARAMS.AFNIPATH, PARAMS.SCRIPTSDIR, PARAMS.PROTOTYPE.ALIGNMENTSCRIPT, PARAMS.TEMPLATEDIR, PARAMS.LOCALIZERANAT, PARAMS.CURRENTANAT, PARAMS.LOCALIZERTEMPLATE, PARAMS.NIFTIDIR, PARAMS.PROTOTYPE.FINALFILE ) );
times.qq = GetSecs - qqStart;
fprintf( '>> Aligned and resampled Prototype NIFTI file: STAT[%d] %1.2f\n', statusQQ, times.qq );

% Select and save Prototype slice as prototypeReference
savStart = GetSecs;
[ statusSEL, ~ ] = unix( sprintf( '%s/3dbucket -prefix %s/%s+orig -fbuc %s/%s+orig[%d]', PARAMS.AFNIPATH, PARAMS.TEMPLATEDIR, PARAMS.PROTOTYPE.TEMPLATE, PARAMS.NIFTIDIR, PARAMS.PROTOTYPE.FINALFILE, PARAMS.PROTOTYPE.REFERENCESLICE ) );
times.sel = GetSecs - savStart;
fprintf( '>> Reorganized file structure: SEL[%d] %1.2f\n', statusSEL, times.sel );

% Dump localizer timecourse
dumpStart = GetSecs;
[ statusDMP, ~ ] = unix( sprintf( '%s/3dmaskdump -mask %s/%s+orig %s/%s+orig > %s/%s.txt', PARAMS.AFNIPATH, PARAMS.TEMPLATEDIR, PARAMS.LOCALIZER.TEMPLATE, PARAMS.NIFTIDIR, PARAMS.PROTOTYPE.FINALFILE, PARAMS.PROCESSDIR, PARAMS.PROTOTYPE.FINALFILE ) );
times.dump = GetSecs - dumpStart;
fprintf( '>> Dumped localized Prototype timecourse: DMP[%d] %1.2f\n', statusDMP, times.dump );

% Load timecourse
ppStart = GetSecs;
info.prototypeData = load( [ PARAMS.PROCESSDIR '/' PARAMS.PROTOTYPE.FINALFILE '.txt' ] );
info.prototypeData = info.prototypeData( : , 4 : end ); % remove locations
times.lod = GetSecs - ppStart;

% Identify bad voxels (e.g., zero and/or constant)
for v = 1 : size( info.prototypeData, 1 ), info.voxVals( v ) = length( unique( info.prototypeData( v, : ) ) ); end % slow!
info.relevantVoxelsIndex = sum( info.prototypeData, 2 ) & info.voxVals' > 1;
info.relevantVoxels = find( sum( info.prototypeData, 2 ) & info.voxVals' > 1 ); % find( indicator variable ) = indices

if isempty( info.relevantVoxels ) % phantom shenanigans or fatal error
    
    info.relevantVoxels = 1 : size( info.prototypeData, 1 );
    info.prototypeDataClean = rand( size( info.prototypeData ) );
    fprintf( '>> Non-Constant Localizer Voxels: 0! | Assuming Phantom shenanigans and plowing ahead into the unknonwn...\n' );

elseif length( info.relevantVoxels ) < size( info.prototypeData, 1 ) % Danger, Will Robinson! Some localizer voxels are zero here, probably due to misalignment! %% soldiering on, nonetheless...
    
    info.prototypeDataClean = info.prototypeData;
    fprintf( '>> Non-Constant Localizer Voxels: %d / %d | POTENTIALLY DANGEROUS CONFLICT: %d Constant voxels used for computing feedback!', ...
             length( info.relevantVoxels ), size( info.prototypeData, 1 ), size( info.prototypeData, 1 ) - length( info.relevantVoxels ) );
    
else % all is well with the world, taking all good voxels that also overlap with localizer
    
    info.prototypeDataClean = info.prototypeData;
    fprintf( '>> Non-Constant Localizer Voxels: %d / %d | No conflicts!\n', length( info.relevantVoxels ), size( info.prototypeData, 1 ) );
      
end

% Highpass filtering
info.prototypeDataCleanFilt = utils_HighPassBetweenRuns( info.prototypeDataClean', PARAMS.TRLENGTH, PARAMS.FILTERCUTOFF )'; % only compiled for Linux!
times.cln = GetSecs - ppStart - times.lod;

% Extract samples for each shape trial
info.lbl = { 'A8', 'A6', 'A4', 'A2', 'Q0', 'G2', 'G4', 'G6', 'G8' ; ...
             'B8', 'B6', 'B4', 'B2', 'Q0', 'H2', 'H4', 'H6', 'H8' ; ...
             'C8', 'C6', 'C4', 'C2', 'Q0', 'I2', 'I4', 'I6', 'I8' ; ...
             'D8', 'D6', 'D4', 'D2', 'Q0', 'J2', 'J4', 'J6', 'J8' ; ...
             'E8', 'E6', 'E4', 'E2', 'Q0', 'K2', 'K4', 'K6', 'K8' ; ...
             'F8', 'F6', 'F4', 'F2', 'Q0', 'L2', 'L4', 'L6', 'L8' };

info.trialOrder = unique( info.lbl ); % 'A2', 'A4', 'A6', 'A8', 'B2', ..., 'L8', 'Q0' = 49
info.numTrials = length( info.trialOrder ); % 49

[ ~, info.trialOrderIndexed ] = ismember( info.lbl, info.trialOrder );

info.normalizationTRs = 1 : round( PARAMS.PROTOTYPE.INITGAP / PARAMS.TRLENGTH ); % 1 : 30
info.timeIndex = round( 1 : ( PARAMS.PROTOTYPE.BLOCKGAP + PARAMS.PROTOTYPE.STIMDURATION * PARAMS.PROTOTYPE.NSHAPESPERTRIAL ) / PARAMS.TRLENGTH : info.numTRs ); % 1 : 12.5 : 341
info.timeIndex = info.timeIndex( 1 : info.numTrials );
info.trIdx = round( ( PARAMS.PROTOTYPE.BLOCKGAP + PARAMS.PROTOTYPE.INITGAP ) / PARAMS.TRLENGTH ) - PARAMS.PROTOTYPE.OMMITEDTRS + round( PARAMS.HEMOLAG / PARAMS.TRLENGTH ) + info.timeIndex; % collect 1 TR per stimulus

[ ~, info.currOrder ] = ismember( info.trialOrder, PARAMS.PROTOTYPE.DESC( 1, : ) );
info.dataRaw = info.prototypeDataCleanFilt( :, info.trIdx ); % numVoxels x numTrials = 49
info.dataRaw = info.dataRaw( :, info.currOrder );

times.xtr = GetSecs - ppStart - times.cln;

% ZSC vs. first 30 TRs
info.meanRest = mean( info.prototypeDataCleanFilt( :, info.normalizationTRs ), 2 );
info.stdRest = std( info.prototypeDataCleanFilt( :, info.normalizationTRs ), [], 2 );
info.dataRest = ( info.dataRaw - repmat( info.meanRest, 1, size( info.dataRaw, 2 ) ) ) ./ repmat( info.stdRest, 1, size( info.dataRaw, 2 ) ); % already ordered cf. info.currOrder
info.dataRest( isnan( info.dataRest ) ) = 0; % std = 0 => division by zero => NaNs => set to zero ; this is just a stopgap, something more intelligent should be done here...
times.zsc = GetSecs - ppStart - times.xtr;

% Output processing stats
times.prep = GetSecs - ppStart;
fprintf( '>> Loaded and processed Prototype data: LOAD %1.2f | CLN %1.2f | XTR %1.2f | ZSC %1.2f | TOT %1.2f\n', times.lod, times.cln, times.xtr, times.zsc, times.prep );

% Test pre-built localizer Gaussian model on current prototype data
fprintf( '>> Testing KLE model...\n');
modelStart = GetSecs;

% Save!
info.times = times;
PARAMS.PROTOTYPE.runInfoRT = info;
save( PARAMS.INFOFILE, 'PARAMS' );

accKLE = 0;
pointLLR = zeros( 1, info.numTrials );
for sample = 1 : info.numTrials
    if ismember( info.trialOrder{ sample }( 1 ), PARAMS.TRAINING.CATEGORY1 ), info.label( sample ) = 1; elseif ismember( info.trialOrder{ sample }( 1 ), PARAMS.TRAINING.CATEGORY2 ), info.label( sample ) = 2; else info.label( sample ) = 0; continue; end
    [ ~, point ] = utils_ApplyModel( PARAMS.LOCALIZER.MODELS( 1 ), info.label( sample ), info.dataRest( logical( PARAMS.LOCALIZER.INDEX( 1, : ) ), sample ) );
    accKLE = accKLE + ( point.estClass == info.label( sample ) );
    pointLLR( sample ) = point.LLR;
    info.estClass( sample ) = point.estClass;
end

times.modelTime = GetSecs - modelStart;

info.acc = 100 * accKLE ./ sum( info.label > 0 ); % some labels may be zero, e.g., for 'Q0'
if info.acc <= 55, info.okString = 'GARBAGE'; elseif info.acc <= 65, info.okString = 'IFFY'; elseif info.acc <= 75, info.okString = 'OK'; else info.okString = 'EXCELLENT'; end
    
% Output model statistics
fprintf( '>> Localizer Model %s @ %2.1f%% | Total Time: %1.2f\n', info.okString, info.acc, times.modelTime )
    
% Save!
info.pointLLR = pointLLR;
info.times = times;
PARAMS.PROTOTYPE.runInfoRT = info;
save( PARAMS.INFOFILE, 'PARAMS' );

% Update and save PARAMS
times.saveStartTime = GetSecs;
info.times = times;
fprintf( '>> Updating and Saving PARAMS...\n' );
PARAMS.PROTOTYPE.runInfoRT = info;
save( PARAMS.INFOFILE, 'PARAMS' );

fprintf( '>> DONE! %1.2f\n', GetSecs - times.saveStartTime );
