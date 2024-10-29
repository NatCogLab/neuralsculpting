function PARAMS = display_Prototype( subjectName, subjectID, scanNum, protoRun )
% (c) Coraline Rinn Iordan 10/2017, 02/2018, 03/2018, 04/2018
%
% Flips on given timing! Flips TR-locked! 
% Total Length: 11m 22.5sec = 682.5 secs = 341 TRs

if nargin < 1, error( 'Must provide subject name.' ); end

% Load latest version of saved PARAMS ; should match PARAMS.INFOFILE
info.loadStartTime = GetSecs;
dateStr = [ subjectName( end - 7 : end - 4 ) '-' subjectName( end - 3 : end - 2 ) '-' subjectName( end - 1 : end ) ];
load( [ '/Data1/code/shapeBender/fmri/' subjectID '/data/info-' subjectName '-' dateStr '.mat' ] ); % PARAMS
info.loadEndTime = GetSecs - info.loadStartTime;
fprintf( '\n%%%%%%%%%%%%% PROTOTYPE RUN %%%%%%%%%%%%%\n>> PARAMS Loaded: %.02f\n', info.loadEndTime );

% Initialize info
info.scanNum = scanNum;
info.protoRun = protoRun;
info.actualTrialGapTimings = nan( PARAMS.PROTOTYPE.NTRIALS + 1, PARAMS.PROTOTYPE.BLOCKGAP - 1 );
info.actualTimings = nan( PARAMS.PROTOTYPE.NTRIALS, PARAMS.PROTOTYPE.NSHAPESPERTRIAL );
info.accuracy = zeros( 1, PARAMS.PROTOTYPE.NTRIALS );
info.counts = nan( PARAMS.PROTOTYPE.NTRIALS, PARAMS.PROTOTYPE.NSHAPESPERTRIAL ); % record jitter responses

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
DrawFormattedText( mainWindow, PARAMS.INSTRUCTIONS.PROTOTYPE, 'center', 'center', PARAMS.DESTINATIONSQUARE );
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
info.ackFile = [ PARAMS.DATADIR '/startPrototype-' subjectName '-' dateStr '-' num2str( info.protoRun ) '.txt' ];
fid = fopen( info.ackFile, 'w' ); fprintf( fid, '%.02f', info.runStartTime ); fclose( fid );
fprintf( '>> Pulse found and written to ACK file! | Beginning prototype run...\n' );

% Compute block gap presentation timings
trialDur = PARAMS.PROTOTYPE.STIMDURATION + PARAMS.PROTOTYPE.ISI;
for shape = 1 : PARAMS.PROTOTYPE.NTRIALS + 1
    info.predictedTrialGapTimings( shape, : ) = info.runStartTime + PARAMS.PROTOTYPE.INITGAP + ( 1 : PARAMS.PROTOTYPE.BLOCKGAP - 1 ) + ( shape - 1 ) * ( PARAMS.PROTOTYPE.NSHAPESPERTRIAL * trialDur + PARAMS.PROTOTYPE.BLOCKGAP );
end

% Compute desired presentation times locked to initial TR pulse
for shape = 1 : PARAMS.PROTOTYPE.NTRIALS
    info.predictedTimings( shape, 1, 1 ) = info.runStartTime + PARAMS.PROTOTYPE.INITGAP + shape * PARAMS.PROTOTYPE.BLOCKGAP + ( shape - 1 ) * PARAMS.PROTOTYPE.NSHAPESPERTRIAL * trialDur;
    info.predictedTimings( shape, 1, 2 ) = info.runStartTime + PARAMS.PROTOTYPE.INITGAP + shape * PARAMS.PROTOTYPE.BLOCKGAP + ( shape - 1 ) * PARAMS.PROTOTYPE.NSHAPESPERTRIAL * trialDur + PARAMS.PROTOTYPE.STIMDURATION;
    
    info.predictedTimings( shape, 2 : PARAMS.PROTOTYPE.NSHAPESPERTRIAL, 1 ) = info.predictedTimings( shape, 1, 1 ) + trialDur * ( 1 : PARAMS.PROTOTYPE.NSHAPESPERTRIAL - 1 );
    info.predictedTimings( shape, 2 : PARAMS.PROTOTYPE.NSHAPESPERTRIAL, 2 ) = info.predictedTimings( shape, 1, 2 ) + trialDur * ( 1 : PARAMS.PROTOTYPE.NSHAPESPERTRIAL - 1 );
end

fprintf( '>> Initial countdown commencing...\n' );

% Countdown: schedule all flips lock-stepped from run start; skip first
Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
for g = PARAMS.PROTOTYPE.INITGAP + PARAMS.PROTOTYPE.BLOCKGAP - 1 : -1 : 1
    DrawFormattedText( mainWindow, num2str( g ), 'center', 'center', PARAMS.DESTINATIONSQUARE );
    if g <= PARAMS.PROTOTYPE.BLOCKGAP - 1
        info.actualTrialGapTimings( 1, PARAMS.PROTOTYPE.BLOCKGAP - g ) = Screen( 'Flip', mainWindow, info.predictedTrialGapTimings( 1, PARAMS.PROTOTYPE.BLOCKGAP - g ) - PARAMS.SLACK );
    else
        Screen( 'Flip', mainWindow, info.predictedTrialGapTimings( 1, 1 ) + PARAMS.PROTOTYPE.BLOCKGAP - 1 - g - PARAMS.SLACK );
    end
end

for trial = 1 : PARAMS.PROTOTYPE.NTRIALS
    
    fprintf( '>> BEGIN TRIAL %d\n', trial );
    
    for shape = 1 : PARAMS.PROTOTYPE.NSHAPESPERTRIAL
        
        % Show shape
        try
            numResponses = 0;
            
            % First frame
            stimulus = Screen( 'MakeTexture', mainWindow, utils_GenerateShape( PARAMS.NSHAPES, PARAMS.PROTOTYPE.ALLFRAMES{ info.protoRun, trial, shape, 1 }, [ 2, 3 ], PARAMS.CENTERSTEP, PARAMS.SPACEWARP, PARAMS.SHAPESIZE, PARAMS.BACKCOLOR, PARAMS.SHAPECOLOR ) );
            Screen( 'DrawTexture', mainWindow, stimulus, [], PARAMS.DESTINATIONSQUARE );
            info.actualTimings( trial, shape ) = Screen( 'Flip', mainWindow, info.predictedTimings( trial, shape, 1 ) - PARAMS.SLACK );
            
            % All other frames % show every 3 frames ~ 20 Hz
            for frame = 4 : 3 : PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE
                if GetSecs >= info.predictedTimings( trial, shape, 1 ) + PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE * PARAMS.FRAMELENGTH, break; end
                stimulus = Screen( 'MakeTexture', mainWindow, utils_GenerateShape( PARAMS.NSHAPES, PARAMS.PROTOTYPE.ALLFRAMES{ info.protoRun, trial, shape, frame }, [ 2, 3 ], PARAMS.CENTERSTEP, PARAMS.SPACEWARP, PARAMS.SHAPESIZE, PARAMS.BACKCOLOR, PARAMS.SHAPECOLOR ) );
                Screen( 'DrawTexture', mainWindow, stimulus, [], PARAMS.DESTINATIONSQUARE );
                Screen( 'Flip', mainWindow, info.predictedTimings( trial, shape, 1 ) + ( frame - 1 ) * PARAMS.FRAMELENGTH - PARAMS.SLACK );
                Screen( 'Close', stimulus );
                
                % check for response
                [ keyIsDown, ~, keyCode ] = KbCheck( PARAMS.RESPONSEDEVICE );
                if keyIsDown && any( strcmp( PARAMS.ALLOWEDRESPONSES{ 1 }, KbName( keyCode ) ) )
                    numResponses = 1;
                end
            end
            
        catch
           save( [ PARAMS.DATADIR '/display_Prototype_exception_' datestr( now, 'dd.mm.yyyy.HH.MM' ) '.mat' ] );
        end
                
        if shape == PARAMS.PROTOTYPE.NSHAPESPERTRIAL, nextTime = info.predictedTimings( trial, shape, 2 ) + PARAMS.PROTOTYPE.STIMDURATION + PARAMS.PROTOTYPE.ISI; else nextTime = info.predictedTimings( trial, shape + 1, 1 ); end
        while GetSecs < nextTime - PARAMS.PROTOTYPE.RESPONSECUTOFF % restrict response time to end 100 ms before next trial
            WaitSecs( PARAMS.LOOPDELAY );
            
            [ keyIsDown, ~, keyCode ] = KbCheck( PARAMS.RESPONSEDEVICE );
            if keyIsDown && any( strcmp( PARAMS.ALLOWEDRESPONSES{ 1 }, KbName( keyCode ) ) ), numResponses = 1; end
        end
        
        info.counts( trial, shape ) = numResponses;
        ll = length( PARAMS.PROTOTYPE.CHANGEDFRAMES{ info.protoRun, trial, shape } );
        if ( numResponses == 0 && ll == 0 ) || ( numResponses == 1 && ll > 0 )
            info.accuracy( trial ) = info.accuracy( trial ) + 1 / PARAMS.PROTOTYPE.NSHAPESPERTRIAL;
        end
        
        fprintf( 'Trial %d :: Shape %d :: %s :: %1.2f[%d] :: R[%d] :: E[%d]\n', ...
                      trial, shape, PARAMS.PROTOTYPE.DESC{ info.protoRun, trial }, info.actualTimings( trial, shape ) - info.actualTimings( trial, 1, 1 ), frame, numResponses, length( PARAMS.PROTOTYPE.CHANGEDFRAMES{ info.protoRun, trial, shape } ) );
                
    end
    
    fprintf( '>> TRIAL FINISHED -- ACCURACY %02g%%\n', info.accuracy( trial ) * 100 )
    
    Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
    for g = PARAMS.PROTOTYPE.BLOCKGAP - 1 : -1 : 1
        DrawFormattedText( mainWindow, num2str( g ), 'center', 'center', PARAMS.DESTINATIONSQUARE );
        info.actualTrialGapTimings( trial + 1, PARAMS.PROTOTYPE.BLOCKGAP - g ) = Screen( 'Flip', mainWindow, info.predictedTrialGapTimings( trial + 1, PARAMS.PROTOTYPE.BLOCKGAP - g ) - PARAMS.SLACK );
    end
        
end

info.runEndTime = GetSecs;
fprintf( '%%%%%% PROTOTYPE RUN FINISHED %%%%%% :: %0.2f\n', info.runEndTime - info.runStartTime );

% Save data for Prototype run and close Screen
PARAMS.PROTOTYPE.runInfoDisplay( info.protoRun ) = info;
save( PARAMS.INFOFILE, 'PARAMS' );
save( sprintf( PARAMS.PROTOTYPEINFOFILE, 'DISPLAY', info.protoRun ), 'info' );
ShowCursor; Screen( 'CloseAll' ); ListenChar( 0 );
