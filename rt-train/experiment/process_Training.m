function info = process_Training( subjectName, subjectID, scanNum, currentRun )
% (c) Coraline Rinn Iordan 09/2017, 10/2017, 02/2018, 04/2018
%
% This version normalizes w.r.t. the initial 30 TR countdown in the run
% Each run has 316 TRs total ; used: 310 TRs ( = number of NIFTI files exported )

if nargin < 4, error( 'Must provide subject name, subject ID, scan number, and current training run number.' ); end

% Load latest version of saved PARAMS ; should match PARAMS.INFOFILE
info.loadStartTime = GetSecs;
dateStr = [ subjectName( end - 7 : end - 4 ) '-' subjectName( end - 3 : end - 2 ) '-' subjectName( end - 1 : end ) ];
load( [ '/Data1/code/shapeBender/fmri/' subjectID '/data/info-' subjectName '-' dateStr '.mat' ] );
info.loadEndTime = GetSecs - info.loadStartTime;
fprintf( '\n%%%%%%%%%%%% TRAINING RUN %d %%%%%%%%%%%%\n>> PARAMS Loaded: %.02f | Waiting for pulse ACK from display code...\n', currentRun, info.loadEndTime );

% Initialize current training run
info.scanNum = scanNum;
info.currentRun = currentRun;

info.specificFile = cell( PARAMS.TRAINING.TOTALRUNTRS, 1 ); % 324
info.patterns.slice = nan( PARAMS.TRAINING.TOTALRUNTRS, size( PARAMS.LOCALIZER.INDEX, 2 ) );
info.patterns.sliceFiltered = nan( PARAMS.TRAINING.TOTALRUNTRS, size( PARAMS.LOCALIZER.INDEX, 2 ) );
info.patterns.sliceFilteredZ = nan( PARAMS.TRAINING.TOTALRUNTRS, size( PARAMS.LOCALIZER.INDEX, 2 ) );

info.feedback = nan( PARAMS.TRAINING.TOTALRUNTRS, 1 );

info.found = nan( PARAMS.TRAINING.TOTALRUNTRS, 1 );
info.loaded = nan( PARAMS.TRAINING.TOTALRUNTRS, 1 );
info.filtered = nan( PARAMS.TRAINING.TOTALRUNTRS, 1 );
info.filterNans = nan( PARAMS.TRAINING.TOTALRUNTRS, 1 );

% Wait an unlimited amount of time for ack of first TR pulse from display script before starting to look for DICOMs
info.ackFile = [ PARAMS.DATADIR '/startTrain' num2str( scanNum ) '-' num2str( currentRun ) '-' subjectName '-' dateStr '.txt' ];
while ~exist( info.ackFile, 'file' ), pause( PARAMS.LOOPDELAY ); end
info.runStartTime = load( info.ackFile ); % this time stamp should match the time stamp that the display script uses to schedule Screen Flips
fprintf( '>> Pulse ACK found: %.02f! | Listening for DICOMs...\n', info.runStartTime );

% Pre-compute expected flip times for shapes based on ACKed first TR pulse
info.predictedTRTimings = info.runStartTime + PARAMS.TRAINING.INITGAP + PARAMS.TRLENGTH * ( 1 : PARAMS.TRAINING.TOTALRUNTRS - 1 );

categOrder = zeros( 1, PARAMS.TRAINING.TOTALRUNTRS ); % which category is shown during each TR % this number does not omit the first 6 TRs and includes the initial 30 TR gap!
categOrder( 1 : PARAMS.TRAINING.OMMITEDTRS ) = -1;
categOrder( PARAMS.TRAINING.OMMITEDTRS + 1 : PARAMS.TRAINING.OMMITEDTRS + round( PARAMS.TRAINING.INITGAP / PARAMS.TRLENGTH ) ) = 5; % TRs used for normalizing!
for trial = 1 : PARAMS.TRAINING.NTRIALSPERRUN
    categStart = 1 + round( PARAMS.TRAINING.INITGAP / PARAMS.TRLENGTH ) + PARAMS.TRAINING.OMMITEDTRS + PARAMS.TRAINING.HEMOLAGTRS + ( trial - 1 ) * ( round( PARAMS.TRAINING.ITI / PARAMS.TRLENGTH ) + PARAMS.TRAINING.TRSPERTRIAL );
    categOrder( categStart : categStart + PARAMS.TRAINING.TRSPERTRIAL - 1 ) = PARAMS.TRAINING.TRIALORDER( currentRun, trial );
end

info.hook = zeros( 1, PARAMS.TRAINING.TOTALRUNTRS );
info.categOrder = categOrder;

trial = 0; inTrial = 0; normIdx = [];
for tr = 1 : PARAMS.TRAINING.TOTALRUNTRS

    trStart = GetSecs;
    
    % Skip ommited TRs at the beginning of the run
    if categOrder( tr ) == -1
        info.procTime( tr ) = GetSecs - trStart;
        fprintf( '[TR %d] | Ommited | Total Time: %1.2f\n', tr,info.procTime( tr ) );
        continue;
    end

    if tr <= 10 || ( tr >= 36 && ~mod( tr - 36, 14 ) ), info.hook( tr ) = 1; end
    % Process this TR slice -- wait for DICOM for 'tr' until at most 1 second before 'tr' + 2, because we're looking for feedback written from 'tr' during 'tr' + 1 || KEEP LOOKING FOREVER...
    [ info.patterns.slice( tr, : ), info.found( tr ), info.loaded( tr ), info.specificFile{ tr }, info.aeTimes{ tr } ] = utils_AlignAndExtractFunctionalSlice( PARAMS, PARAMS.DICOMDIR, info.scanNum, tr, Inf, info.hook( tr ) ); % info.predictedTRTimings( tr ) + 2 * PARAMS.TRLENGTH - PARAMS.TRAINING.TRCUTOFF );

    % If we loaded NaNs for any reason, then this TR is a fail ; load previous successfully computed TR
    if any( isnan( info.patterns.slice( tr, : ) ) ) && tr > PARAMS.TRAINING.OMMITEDTRS
        info.loaded( tr ) = 0;
        info.patterns.slice( tr, : ) = info.patterns.slice( tr - 1, : ); % this will break if failure happens at first TR in the trial!
    end
    
    info.filtStart = GetSecs;
    % High-pass filter using fast MEX implementation of 'fslmaths' % Filter every TR up to the current one
    info.patterns.sliceFiltered( PARAMS.TRAINING.OMMITEDTRS + 1 : tr, : ) = utils_HighPassBetweenRuns( info.patterns.slice( PARAMS.TRAINING.OMMITEDTRS + 1 : tr, : ), PARAMS.TRLENGTH, PARAMS.FILTERCUTOFF ); % only compiled for Linux!
    info.filtered( tr ) = 1;
    info.filtTime( tr ) = GetSecs - info.filtStart;
    
    % If a new trial just started, write default feedback and skip this TR
    if tr > 1 && ~categOrder( tr - 1 ) && categOrder( tr ) && categOrder( tr ) ~=5
        trial = trial + 1;
        inTrial = 1;
        fid = fopen( sprintf( '%s/feedback_%d_%d.txt', PARAMS.FEEDBACKDIR, currentRun, tr ), 'w' ); fprintf( fid, '0' ); fclose( fid );
        fid = fopen( sprintf( '%s/feedback_%d_%d.txt', PARAMS.FEEDBACKDIR, currentRun, tr - 1 ), 'w' ); fprintf( fid, '0' ); fclose( fid );
        fid = fopen( sprintf( '%s/feedback_%d_%d.txt', PARAMS.FEEDBACKDIR, currentRun, tr - 2 ), 'w' ); fprintf( fid, '0' ); fclose( fid );
        fid = fopen( sprintf( '%s/feedback_%d_%d.txt', PARAMS.FEEDBACKDIR, currentRun, tr - 3 ), 'w' ); fprintf( fid, '0' ); fclose( fid );
    elseif tr > 1 && ~categOrder( tr - 1 ) && categOrder( tr ) == 5
        inTrial = 1;
    elseif tr > 1 && categOrder( tr - 1 ) && categOrder( tr )
        inTrial = inTrial + 1;
    elseif ~categOrder( tr )
        inTrial = 0;
    end
    
    if categOrder( tr ) == 5 % these are TRs used for normalization
        
        normIdx = [ normIdx, tr ];
        info.procTime( tr ) = GetSecs - trStart;
        
        fprintf( '[TR %d][Trial %d, inTR %d] Found [%d] | Loaded [%d] | Filtered [%d] %1.2f | Recording Normalization TR | Outside Feedback Range | Total Time: %1.2f\n', tr, trial, inTrial, info.found( tr ), info.loaded( tr ), info.filtered( tr ), info.filtTime( tr ), info.procTime( tr ) );

        continue;
        
    elseif ~inTrial || trial < 1
        
        info.procTime( tr ) = GetSecs - trStart;
        
        fprintf( '[TR %d][Trial %d, inTR %d] Found [%d] | Loaded [%d] | Filtered [%d] %1.2f | Outside Feedback Range | Total Time: %1.2f\n', tr, trial, inTrial, info.found( tr ), info.loaded( tr ), info.filtered( tr ), info.filtTime( tr ), info.procTime( tr ) );
        continue;
        
    else % inTrial, not a normalization TR5
        
        if trial == 1 && inTrial == 1 % first feedback TR of first trial!
            info.patterns.sliceMean = squeeze( mean( info.patterns.sliceFiltered( normIdx, : ), 1 ) );
            info.patterns.sliceStd = squeeze( std( info.patterns.sliceFiltered( normIdx, : ) ) );
            
            for t = 1 : length( normIdx )
                sliceFilt = ( squeeze( info.patterns.sliceFiltered( normIdx( t ), : ) ) - squeeze( info.patterns.sliceMean ) ) ./ squeeze( info.patterns.sliceStd );
                info.filterNans( normIdx( t ) ) = sum( isnan( sliceFilt ) );
                info.filterInfs( normIdx( t ) ) = sum( isinf( sliceFilt ) );
                sliceFilt( isnan( sliceFilt ) ) = 0;
                sliceFilt( isinf( sliceFilt ) ) = 0;
                info.patterns.sliceFilteredZ( normIdx( t ), : ) = sliceFilt;
            end
        end
        
        % Z-score relative to first 30 TRs
        sliceFilt = ( squeeze( info.patterns.sliceFiltered( tr, : ) ) - squeeze( info.patterns.sliceMean ) ) ./ squeeze( info.patterns.sliceStd );
        info.filterNans( tr ) = sum( isnan( sliceFilt ) );
        info.filterInfs( tr ) = sum( isinf( sliceFilt ) );
        sliceFilt( isnan( sliceFilt ) ) = 0;
        sliceFilt( isinf( sliceFilt ) ) = 0;
        info.patterns.sliceFilteredZ( tr, : ) = sliceFilt;
        
        % Apply model to current slice and write suggested feedback to disk
        trailingIdx = tr; % if inTrial >= PARAMS.TRAINING.TRAILINGTRS, trailingIdx = tr - inTrial + 1 : tr; else trailingIdx = tr - PARAMS.TRAINING.TRAILINGTRS + 1 : tr; end
        [ info.feedback( tr ), info.point( tr ) ] = utils_ApplyModel( PARAMS.LOCALIZER.MODELS( 1 ), PARAMS.TRAINING.TRIALORDER( currentRun, trial ), squeeze( nanmean( info.patterns.sliceFilteredZ( trailingIdx, : ), 1 ) )' );
        % Write feedback for previous TR! (using Prototype run model by default)
        fid = fopen( sprintf( '%s/feedback_%d_%d.txt', PARAMS.FEEDBACKDIR, currentRun, tr ), 'w' ); info.fbr( tr ) = GetSecs; fprintf( fid, '%d', info.feedback( tr ) ); fclose( fid );
        
        info.procTime( tr ) = GetSecs - trStart;
        
        fprintf( '[TR %d][Trial %d, inTR %d] Found [%d] | Loaded [%d] | Filtered [%d][NaNs %d] %1.2f | Total Time: %1.2f\n\tPrototype Model :: P1 %.2f :: P2 %.2f :: LLR %.2f :: KLE %.4f EstClass [%d/%d] | KLEQ[%d] | Feedback [%d] %1.2f\n', ...
            tr, trial, inTrial, info.found( tr ), info.loaded( tr ), info.filtered( tr ), info.filterNans( tr ), info.filtTime( tr ), info.procTime( tr ), ...
            info.point( tr ).p1, info.point( tr ).p2, info.point( tr ).LLR, info.point( tr ).KLE, info.point( tr ).estClass, PARAMS.TRAINING.TRIALORDER( currentRun, trial ), info.point( tr ).percKLE, info.feedback( tr ), info.fbr( tr ) );
        
    end
   
end

% Update and save PARAMS
info.saveStartTime = GetSecs;
fprintf( '>> Updating and saving info...\n' );
save( sprintf( PARAMS.TRAININGINFOFILE, 'RT', currentRun ), 'info' );
fprintf( '>> DONE! %.02f\n', GetSecs - info.saveStartTime );
