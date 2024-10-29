function info = display_Training( subjectName, subjectID, scanNum, currentRun )
% (c) Coraline Rinn Iordan 09/2017, 10/2017, 02/2018, 04/2018
%
% Flips on given timing! Flips TR-locked!
% Total Length: 10m32 sec = 632 secs = 316 TRs

if nargin < 4, error( 'Must provide subject name, subject ID, scan run number, and current training run number.' ); end

% Load latest version of saved PARAMS ; should match PARAMS.INFOFILE
info.loadStartTime = GetSecs;
dateStr = [ subjectName( end - 7 : end - 4 ) '-' subjectName( end - 3 : end - 2 ) '-' subjectName( end - 1 : end ) ];
load( [ '/Data1/code/shapeBender/fmri/' subjectID '/data/info-' subjectName '-' dateStr '.mat' ] ); % PARAMS after Prototype run data has been saved to disk
info.loadEndTime = GetSecs - info.loadStartTime;
fprintf( '\n%%%%%%%%%%%% TRAINING RUN %d %%%%%%%%%%%%\n>> PARAMS Loaded: %.02f\n', currentRun, info.loadEndTime );

% Initialize info
info.scanNum = scanNum;
info.currentRun = currentRun;
info.actualTimings = nan( PARAMS.TRAINING.NTRIALSPERRUN, PARAMS.TRAINING.NSWITCHESPERTRIAL, PARAMS.TRAINING.NUMWOBBLESPERSHAPE );
info.feedback = nan( PARAMS.TRAINING.NTRIALSPERRUN, PARAMS.TRAINING.TRSPERTRIAL );

% Initialize screen
Screen( 'Preference', 'SkipSyncTests', 1 );
Screens = Screen( 'Screens' );
mainWindow = Screen( 'OpenWindow', max( Screens ), PARAMS.BACKCOLOR, [ 0, 0, PARAMS.RESOLUTION.width / 2, PARAMS.RESOLUTION.height ] );

Screen( mainWindow, 'TextFont', 'Arial' );
Screen( mainWindow, 'TextSize', 20 );
Screen( mainWindow, 'TextColor', PARAMS.TEXTCOLOR );
HideCursor; GetSecs; ListenChar( 2 ); KbName( 'UnifyKeyNames' ); % platform-independent responses

% Show instructions
Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
DrawFormattedText( mainWindow, PARAMS.INSTRUCTIONS.TRAINING, 'center', 'center', PARAMS.DESTINATIONSQUARE );
Screen( 'Flip', mainWindow );

% Wait for ACK from participant that instructions were read and understood
FlushEvents( 'keyDown' );
while 1
    WaitSecs( PARAMS.LOOPDELAY );
    [ keyIsDown, ~, keyCode] = KbCheck( PARAMS.RESPONSEDEVICE );
    if keyIsDown && any( strcmp( PARAMS.ALLOWEDRESPONSES{ 1 }, KbName( keyCode ) ) ), break; end
end

Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
DrawFormattedText( mainWindow, PARAMS.INSTRUCTIONS.WAIT, 'center', 'center', PARAMS.DESTINATIONSQUARE );
Screen( 'Flip', mainWindow );

% Wait for scanner pulse to start run and write ACK file for RT code
Priority( MaxPriority( mainWindow ) ); % FlushEvents( 'keyDown' );% not necessary on fast machines
info.runStartTime = utils_WaitForTRPulse( PARAMS.TRLENGTH, PARAMS.TRIGGERKEY, PARAMS.TRIGGERDEVICE );
info.ackFile = [ PARAMS.DATADIR '/startTrain' num2str( scanNum ) '-' num2str( currentRun ) '-' subjectName '-' dateStr '.txt' ];
fid = fopen( info.ackFile, 'w' ); fprintf( fid, '%.02f', info.runStartTime ); fclose( fid );
fprintf( '>> Pulse found and written to ACK file! | Beginning training run...\n' );

% Compute trial gap presentation timings
trialDur = PARAMS.TRAINING.TRSPERTRIAL * PARAMS.TRLENGTH + PARAMS.TRAINING.ITI;
for trial = 1 : PARAMS.TRAINING.NTRIALSPERRUN + 1
    info.predictedTrialGapTimings( trial, : ) = info.runStartTime + PARAMS.TRAINING.INITGAP + ( 1 : PARAMS.TRAINING.ITI - 1 ) + ( trial - 1 ) * trialDur;
end

% Compute desired presentation times locked to initial TR pulse
for trial = 1 : PARAMS.TRAINING.NTRIALSPERRUN
    info.predictedTimings( trial, : ) = info.runStartTime + + PARAMS.TRAINING.INITGAP + PARAMS.TRAINING.ITI + ( trial - 1 ) * trialDur + ( 0 : ( PARAMS.TRAINING.FEEDBACKGRANULARITY * PARAMS.TRLENGTH ) : ( PARAMS.TRAINING.TRSPERTRIAL - 1 ) * PARAMS.TRLENGTH );    
end

fprintf( '>> Initial countdown commencing...\n' );

% Countdown: schedule all flips lock-stepped from run start; skip first
Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
for g = PARAMS.PROTOTYPE.INITGAP + PARAMS.TRAINING.ITI - 1 : -1 : 1
    DrawFormattedText( mainWindow, num2str( g ), 'center', 'center', PARAMS.DESTINATIONSQUARE );
    
    if g <= PARAMS.TRAINING.ITI - 1
        info.actualTrialGapTimings( 1, PARAMS.TRAINING.ITI - g ) = Screen( 'Flip', mainWindow, info.predictedTrialGapTimings( 1, PARAMS.TRAINING.ITI - g ) - PARAMS.SLACK );
    else
        Screen( 'Flip', mainWindow, info.predictedTrialGapTimings( 1, 1 ) + PARAMS.TRAINING.ITI - 1 - g - PARAMS.SLACK );
    end    
end

info.alternateFbk = zeros( PARAMS.TRAINING.NTRIALSPERRUN, PARAMS.TRAINING.NSWITCHESPERTRIAL );

for trial = 1 : PARAMS.TRAINING.NTRIALSPERRUN
    
    fprintf( '>> BEGIN TRIAL %d\n', trial );
    
    currentWobble = PARAMS.TRAINING.INITWOBBLE;
    info.currentWobble( trial, 1 ) = currentWobble;
    position = PARAMS.TRAINING.BASESHAPE{ currentRun, trial };
    
    for shape = 1 : PARAMS.TRAINING.NSWITCHESPERTRIAL
        
        % Generate all frames for current shape based on 'currentWobble'
        for k = 1 : PARAMS.TRAINING.NUMWOBBLESPERSHAPE
            ray = PARAMS.TRAINING.RAY{ currentRun, trial, shape, k }; % randomly change X-Y-Z wobble direction! % randn( 1, 3 ); % ray = radius * ray * frameStep / norm( ray );
            
            % Save time by only generating every 3 frames
            for f = 1 : PARAMS.TRAINING.NUMFRAMESPERWOBBLE
                allFrames{ trial, shape, k, f } = position;
                
                if f <= round( PARAMS.TRAINING.NUMFRAMESPERWOBBLE / 2 ) + 1
                    allFrames{ trial, shape, k, f }( [ 2, 3, 5 ] ) = position( [ 2, 3, 5 ] ) + ray * currentWobble * ( f - 1 ) * PARAMS.TRAINING.FRAMESTEP; % ray is already normalized when initialized!
                else
                    allFrames{ trial, shape, k, f }( [ 2, 3, 5 ] ) = position( [ 2, 3, 5 ] ) + ray * currentWobble * ( PARAMS.TRAINING.NUMFRAMESPERWOBBLE - f + 1 ) * PARAMS.TRAINING.FRAMESTEP; % track backwards towards original shape
                end
            end
        end
        
        % Show wobbling shape
        try
            for k = 1 : PARAMS.TRAINING.NUMWOBBLESPERSHAPE
                % First frame
                stimulus = Screen( 'MakeTexture', mainWindow, utils_GenerateShape( PARAMS.TRAINING.NSHAPES, allFrames{ trial, shape, k, 1 }, [ 2, 3, 5 ], PARAMS.TRAINING.CENTERSTEP, PARAMS.SPACEWARP, PARAMS.SHAPESIZE, PARAMS.BACKCOLOR, PARAMS.SHAPECOLOR ) );
                Screen( 'DrawTexture', mainWindow, stimulus, [], PARAMS.DESTINATIONSQUARE );
                info.actualTimings( trial, shape, k ) = Screen( 'Flip', mainWindow, info.predictedTimings( trial, shape ) + ( ( k - 1 ) * PARAMS.TRLENGTH / PARAMS.TRAINING.NUMWOBBLESPERSHAPE ) - PARAMS.SLACK );
                
                % All other frames ~ 20 Hz
                for frame = 2 : PARAMS.TRAINING.NUMFRAMESPERWOBBLE
                    if GetSecs >= info.predictedTimings( trial, shape ) + k * PARAMS.TRLENGTH / PARAMS.TRAINING.NUMWOBBLESPERSHAPE, break; end
                    stimulus = Screen( 'MakeTexture', mainWindow, utils_GenerateShape( PARAMS.TRAINING.NSHAPES, allFrames{ trial, shape, k, frame }, [ 2, 3, 5 ], PARAMS.TRAINING.CENTERSTEP, PARAMS.SPACEWARP, PARAMS.SHAPESIZE, PARAMS.BACKCOLOR, PARAMS.SHAPECOLOR ) );
                    Screen( 'DrawTexture', mainWindow, stimulus, [], PARAMS.DESTINATIONSQUARE );
                    Screen( 'Flip', mainWindow, info.predictedTimings( trial, shape ) + ( ( k - 1 ) * PARAMS.TRLENGTH / PARAMS.TRAINING.NUMWOBBLESPERSHAPE ) + ( ( frame - 1 ) * PARAMS.FRAMELENGTH * PARAMS.TRAINING.NUMFRAMESPERSHAPE / PARAMS.TRAINING.NUMCOMPUTEDFRAMESPERSHAPE ) - PARAMS.SLACK );
                    Screen( 'Close', stimulus );
                end
            end
        catch
            save( [ PARAMS.DATADIR '/display_Training_exception_' datestr( now, 'dd.mm.yyyy.HH.MM' ) '.mat' ] );
        end
         
        % For the first 2 + 1 = 3 TRs in each trial we can't load feedback! (hemo lag = 2 TRs + 1 TR for writing DICOM)
        % This happens after the long PARAMS.TRAINING.INITGAP countdown
        if shape <= PARAMS.TRAINING.HEMOLAGTRS + 1
            times.total = GetSecs - info.runStartTime;
            fprintf( 'Skipping TR %d Feedback | TOT %1.2f\n', shape, times.total );
            continue;
        end
        
        % Wait until 200 ms before next shape switch for feedback file to appear, then load and incorporate feedback
        % TR 3 is written to disk and processed during TR 4, which is also where we want to load it for feedback on TR 5
        past = 1;
        currentTR = PARAMS.TRAINING.OMMITEDTRS + round( PARAMS.TRAINING.INITGAP / PARAMS.TRLENGTH ) + ( trial - 1 ) * ( round( PARAMS.TRAINING.ITI / PARAMS.TRLENGTH ) + PARAMS.TRAINING.TRSPERTRIAL ) + shape;
        feedbackFile = sprintf( '%s/feedback_%d_%d.txt', PARAMS.FEEDBACKDIR, currentRun, currentTR - past ); % feedback comes from 4 secs ago, but is written as current TR!
        found = exist( feedbackFile, 'file' );
        while ~found && GetSecs < info.predictedTimings( trial, shape ) + PARAMS.TRLENGTH - PARAMS.TRAINING.DISPLAYCUTOFF
            pause( PARAMS.LOOPDELAY );
            found = exist( feedbackFile, 'file' );
        end
               
        % Update wobble parameters or record abject failure to compute/load feedback
        if found
            info.fbf( trial, shape ) = GetSecs;
        else % file was not written to disk and/or was not accessible before time ran out for processing
            while ~found && past <=4 % find last computed file
                past = past + 1;
                feedbackFile = sprintf( '%s/feedback_%d_%d.txt', PARAMS.FEEDBACKDIR, currentRun, currentTR - past );
                found = exist( feedbackFile, 'file' );
            end
            
            info.fbf( trial, shape ) = GetSecs;
        end
        
        if found, info.feedback( trial, shape ) = load( feedbackFile ); info.feedbackTotalFail( trial, shape ) = 0; else info.feedback( trial, shape ) = 0; info.feedbackTotalFail( trial, shape ) = 1; end
        
        % look back one more TR in case we skipped it due to processing delay
        if shape > PARAMS.TRAINING.HEMOLAGTRS + 2
            if currentTR - past - 1 > info.actualFeedbackTR( trial, shape - 1 )
                info.alternateFbk( trial, shape ) = load( sprintf( '%s/feedback_%d_%d.txt', PARAMS.FEEDBACKDIR, currentRun, currentTR - past - 1 ) );
            end
        end
        
        info.feedback( trial, shape ) = max( -1, min( 1, info.feedback( trial, shape ) + info.alternateFbk( trial, shape ) ) );
        currentWobble = currentWobble - info.feedback( trial, shape ) * PARAMS.TRAINING.WOBBLESTEP;
        if currentWobble < PARAMS.TRAINING.MINWOBBLE, currentWobble = PARAMS.TRAINING.MINWOBBLE; end
        if currentWobble > PARAMS.TRAINING.MAXWOBBLE, currentWobble = PARAMS.TRAINING.MAXWOBBLE; end
        info.currentWobble( trial, shape + 1 ) = currentWobble;
        times.total = GetSecs - info.runStartTime;
        
        info.actualFeedbackTR( trial, shape ) = currentTR - past;
        fprintf( 'TR %d [GLOBAL %d]:: [FBK FROM GLOBAL TR %d][FBK VAL %d] %1.2f | TOT %1.2f\n', shape, currentTR, currentTR - past, info.feedback( trial, shape ), info.fbf( trial, shape ), times.total );

    end
    
    % Fixation dot between trials
    Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
    Screen( 'FillOval', mainWindow, PARAMS.FIXATIONCOLOR, PARAMS.FIXDOTRECT );
    Screen( 'Flip', mainWindow );
    
    info.progress( trial ) = info.currentWobble( trial, end ) - PARAMS.TRAINING.INITWOBBLE; % + worse ; - better ; 0 no change
    info.perfect( trial ) = info.currentWobble( trial, end ) == PARAMS.TRAINING.MINWOBBLE; % +0.0 %
    
    if info.progress( trial ) > 0, progressString = '+WOB'; elseif info.progress( trial ) < 0, progressString = '-WOB'; else progressString = '=00='; end
    
    % Feedback statistics for current trial
    fprintf( '>> TRIAL FINISHED -- PROGRESS %s | POS FBK [%3.0f] NEG FBK [%3.0f] NO FBK [%3.0f] FAIL FBK [%3.0f]\n', ...
             progressString, sum( info.feedback( trial, : ) == +1 ), sum( info.feedback( trial, : ) == -1 ), sum( info.feedback( trial, : ) == 0 ), sum( isnan( info.feedback( trial, : ) ) ) );
        
    Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
    for g = PARAMS.TRAINING.ITI - 1 : -1 : 1
        DrawFormattedText( mainWindow, num2str( g ), 'center', 'center', PARAMS.DESTINATIONSQUARE );
        info.actualTrialGapTimings( trial + 1, PARAMS.TRAINING.ITI - g ) = Screen( 'Flip', mainWindow, info.predictedTrialGapTimings( trial + 1, PARAMS.TRAINING.ITI - g ) - PARAMS.SLACK );
    end
    
end

% performance bonus: 10 cents for each improved trial, 25 cents for each perfect trial (i.e., sustained wobble stop) ; avg. chance <= $6 ; max. $30
info.bonus = sum( info.progress < 0 ) * 0.10 + sum( info.perfect ) * 0.25;
fprintf( '>> RUN FINISHED | +WOBBLE [%d] | ZERO PROGRESS [%d] | -WOBBLE [%d] | PERFECT [%d] | BONUS [$ %2.2f]\n', ...
         sum( info.progress > 0 ), sum( info.progress == 0 ), sum( info.progress < 0 ) - sum( info.perfect ), sum( info.perfect ), info.bonus );

% Save data for Training run and close Screen
info.times = times;
save( sprintf( PARAMS.TRAININGINFOFILE, 'DISPLAY', currentRun ), 'info' );
ShowCursor; Screen( 'CloseAll' ); ListenChar( 0 );
