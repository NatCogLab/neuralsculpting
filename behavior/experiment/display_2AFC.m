function PARAMS = display_2AFC( subjectID )
% (c) Coraline Rinn Iordan 10/2017, 03/2018

if nargin < 1, error( 'Must provide subject ID.' ); end

% Load latest version of saved PARAMS ; should match PARAMS.INFOFILE
info.loadStartTime = GetSecs;
load( [ './data/info-' subjectID '.mat' ] ); % PARAMS
info.loadEndTime = GetSecs - info.loadStartTime;
fprintf( '\n%%%%%%%%%%%%% DISPLAY START %%%%%%%%%%%%%\n>> PARAMS Loaded: %.02f\n', info.loadEndTime );

% Initialize info
info.timings = nan( PARAMS.NRUNS, PARAMS.NTRIALSPERRUN, 3 );
info.counts = nan( PARAMS.NRUNS, PARAMS.NTRIALSPERRUN ); % record reported category
info.badResponse = zeros( PARAMS.NRUNS, PARAMS.NTRIALSPERRUN );

% Initialize screen
Screen( 'Preference', 'SkipSyncTests', 1 );

% Run in dual-display mode if a second window is available; otherwise run in single-display mode
mainWindow = Screen( 'OpenWindow', max( Screen( 'Screens' ) ), PARAMS.BACKCOLOR );
Screen( mainWindow, 'TextFont', 'Arial' );
Screen( mainWindow, 'TextSize', 20 );
Screen( mainWindow, 'TextColor', PARAMS.TEXTCOLOR );
HideCursor; GetSecs; ListenChar( 2 ); KbName( 'UnifyKeyNames' ); % platform-independent responses

for run = 1 : PARAMS.NRUNS
    
    fprintf( '>> BEGIN RUN %d\n', run );
    
    % Show instructions
    Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
    DrawFormattedText( mainWindow, sprintf( PARAMS.INSTRUCTIONS.RUNSTART, run, PARAMS.NRUNS ), 'center', 'center', PARAMS.DESTINATIONSQUARE.TESTSHAPE );
    Screen( 'Flip', mainWindow );
    
    % Wait for ACK from participant that instructions were read and understood
    FlushEvents( 'keyDown' );
    while 1
        WaitSecs( PARAMS.LOOPDELAY );
        [ keyIsDown, ~, keyCode] = KbCheck( PARAMS.RESPONSEDEVICE );
        if keyIsDown && any( strcmp( PARAMS.ALLOWEDRESPONSES, KbName( keyCode ) ) ), break; end
    end
    
    info.runStartTimes( run ) = GetSecs;
    fprintf( '>> Instructions ACK received! | Beginning experimental run...\n' );
    
    leftCat = Screen( 'MakeTexture', mainWindow, utils_GenerateShape( PARAMS.NSHAPES, PARAMS.CATSHAPES{ run, 1 }, [ 2, 3, 5 ], PARAMS.CENTERSTEP, PARAMS.SPACEWARP, PARAMS.SHAPESIZE, PARAMS.BACKCOLOR, PARAMS.SHAPECOLOR ) );
    rightCat = Screen( 'MakeTexture', mainWindow, utils_GenerateShape( PARAMS.NSHAPES, PARAMS.CATSHAPES{ run, 2 }, [ 2, 3, 5 ], PARAMS.CENTERSTEP, PARAMS.SPACEWARP, PARAMS.SHAPESIZE, PARAMS.BACKCOLOR, PARAMS.SHAPECOLOR ) );
    
    for trial = 1 : PARAMS.NTRIALSPERRUN
        % Show fixation dot
        Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
        Screen( 'DrawTexture', mainWindow, leftCat, [], PARAMS.DESTINATIONSQUARE.LEFTSHAPE );
        Screen( 'DrawTexture', mainWindow, rightCat, [], PARAMS.DESTINATIONSQUARE.RIGHTSHAPE );
        Screen( 'FillOval', mainWindow, PARAMS.BACKCOLOR, PARAMS.DESTINATIONSQUARE.FIXDOT );
        info.timings( run, trial, 1 ) = Screen( 'Flip', mainWindow );
 
        % Show shapes
        try
            stimulus = Screen( 'MakeTexture', mainWindow, utils_GenerateShape( PARAMS.NSHAPES, PARAMS.ALLSHAPES{ run, trial }, [ 2, 3, 5 ], PARAMS.CENTERSTEP, PARAMS.SPACEWARP, PARAMS.SHAPESIZE, PARAMS.BACKCOLOR, PARAMS.SHAPECOLOR ) );
            Screen( 'DrawTexture', mainWindow, leftCat, [], PARAMS.DESTINATIONSQUARE.LEFTSHAPE );
            Screen( 'DrawTexture', mainWindow, rightCat, [], PARAMS.DESTINATIONSQUARE.RIGHTSHAPE );
            Screen( 'DrawTexture', mainWindow, stimulus, [], PARAMS.DESTINATIONSQUARE.TESTSHAPE );
            info.timings( run, trial, 2 ) = Screen( 'Flip', mainWindow, info.timings( run, trial, 1 ) + PARAMS.CROSSDUR );
        catch
            save( [ PARAMS.DATADIR '/display_exception_' datestr( now, 'dd.mm.yyyy.HH.MM' ) '.mat' ] );
        end
        
        % Check for response
        FlushEvents( 'keyDown' ); % remove responses to last trial
        WaitSecs( PARAMS.WAITTIME );
        while 1 % keep waiting for that response...
            [ keyIsDown, secs, keyCode ] = KbCheck( PARAMS.RESPONSEDEVICE );
            
            response = KbName( keyCode );
            if keyIsDown && any( strcmp( PARAMS.ALLOWEDRESPONSES, response ) )
                info.timings( run, trial, 3 ) = secs;
                switch response( 1 )
                    case PARAMS.ALLOWEDRESPONSES{ 1 }
                        info.counts( run, trial ) = 1;
                    case PARAMS.ALLOWEDRESPONSES{ 2 }
                        info.counts( run, trial ) = 2;
                    otherwise
                        info.badResponse( run, trial ) = 1; % error( 'Unknown response.' );
                end
                
                break;
            end
        end
        
        fprintf( '>> TRIAL %d :: %s [%d] %.02f\n', trial, PARAMS.ALLDESC{ run, trial }, info.counts( run, trial ), info.timings( run, trial, 3 ) - info.timings( run, trial, 2 ) );
    end
    
    % Show instructions
    Screen( mainWindow, 'FillRect', PARAMS.BACKCOLOR );
    if run == PARAMS.NRUNS, instructions = PARAMS.INSTRUCTIONS.XPEND; else instructions = PARAMS.INSTRUCTIONS.RUNEND; end
    DrawFormattedText( mainWindow, sprintf( instructions, run, PARAMS.NRUNS ), 'center', 'center', PARAMS.DESTINATIONSQUARE.TESTSHAPE );
    Screen( 'Flip', mainWindow );
    
    WaitSecs( 2.0 ); % wait a bit before participant can advance
    
    % Wait for ACK from participant that run has finished
    FlushEvents( 'keyDown' );
    while 1
        WaitSecs( PARAMS.LOOPDELAY );
        [ keyIsDown, ~, keyCode] = KbCheck( PARAMS.RESPONSEDEVICE );
        if keyIsDown && any( strcmp( PARAMS.ALLOWEDRESPONSES, KbName( keyCode ) ) ), break; end
    end
    
    info.runEndTimes( run ) = GetSecs;
    fprintf( '>> RUN FINISHED -- TOTAL TIME %.02f\n', info.runEndTimes( run ) - info.runStartTimes( run ) );
    
    % Save run data
    PARAMS.runInfo( run ) = info;
    save( PARAMS.INFOFILE, 'PARAMS' );

end

% Close Screen and clean up
ShowCursor; Screen( 'CloseAll' ); ListenChar( 0 );
