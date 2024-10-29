function PARAMS = initializeSession( subjectName, subjectID, deviceName )
% (c) Coraline Rinn Iordan 10/2017, 02/2018, 03/2018, 04/2018, 06/2018

if nargin < 2, error( 'Must provide subject name and ID.' ); end
if nargin < 3, deviceName = 'SKYRA.CurrentDesign'; end

initStartTime = GetSecs;


%%%%%%%%%%%%%
%%% SETUP %%%
%%%%%%%%%%%%%

rng( 'shuffle' );

PARAMS.SUBJECTNAME = subjectName;
PARAMS.SUBJECTID = subjectID;
PARAMS.DEVICENAME = deviceName;

% Find and initialize trigger and response devices
switch PARAMS.DEVICENAME  
    
    case 'SKYRA.CurrentDesign'
        
        PARAMS.TRIGGERDEVICE = utils_GetKeyboardDeviceNumber( 'Current Designs, Inc. 932' ); % 'Current Designs, Inc. 932'
        KbName( 'UnifyKeyNames' );
        PARAMS.TRIGGERKEY = KbName( '5%' );
        
        PARAMS.RESPONSEDEVICE = PARAMS.TRIGGERDEVICE;
        PARAMS.ALLOWEDRESPONSES = { '1!' };
        PARAMS.RESPONSERATINGS = 1; % wobble happened!
        
    case 'DEBUG'
        
        PARAMS.TRIGGERDEVICE = -3;
        KbName( 'UnifyKeyNames' );
        PARAMS.TRIGGERKEY = KbName( '5%' );
        
        PARAMS.RESPONSEDEVICE = PARAMS.TRIGGERDEVICE;
        PARAMS.ALLOWEDRESPONSES = { '1!' };
        PARAMS.RESPONSERATINGS = 1; % wobble happened!

    otherwise
        error( 'Unknown device.' );
        
end   
    
% Set paths and working directories
PARAMS.SUBJECTDIR = [ '/Data1/code/shapeBender/fmri/' PARAMS.SUBJECTID ]; if ~exist( PARAMS.SUBJECTDIR, 'dir' ), error( 'Subject directory not found.' ); end
PARAMS.DICOMDIR = [ '/Data1/subjects/' datestr( now, 10 ), datestr( now, 5 ), datestr( now, 7 ) '.' PARAMS.SUBJECTNAME '.' PARAMS.SUBJECTNAME ];
PARAMS.DATADIR = [ PARAMS.SUBJECTDIR '/data' ]; if ~exist( PARAMS.DATADIR, 'dir' ), mkdir( PARAMS.DATADIR ); end

PARAMS.INFOFILE = [ PARAMS.DATADIR '/info-' PARAMS.SUBJECTNAME '-' datestr( now, 10 ) '-' datestr( now, 5 ) '-' datestr( now, 7 ) '.mat' ];
PARAMS.PROTOTYPEINFOFILE = [ PARAMS.DATADIR '/prototypeinfo-' PARAMS.SUBJECTNAME '-' datestr( now, 10 ) '-' datestr( now, 5 ) '-' datestr( now, 7 ) '_%s%d.mat' ];

% Initialize experiment timing parameters
PARAMS.TRLENGTH = 2.000; % 2 sec
PARAMS.HEMOLAG = 4.000; % 2 TRs
PARAMS.LOOPDELAY = 0.005; % 5 ms


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% INITIALIZE SCREEN %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.SCREENX = 1920;
PARAMS.SCREENY = 1080;
PARAMS.CENTERX = round( PARAMS.SCREENX / 2 );
PARAMS.CENTERY = round( PARAMS.SCREENY / 2 );

PARAMS.DOTSIZE = 10;
PARAMS.SHAPESIZE = 600;
PARAMS.DESTINATIONSQUARE = [ PARAMS.CENTERX - PARAMS.SHAPESIZE / 2, PARAMS.CENTERY - PARAMS.SHAPESIZE / 2, PARAMS.CENTERX + PARAMS.SHAPESIZE / 2, PARAMS.CENTERY + PARAMS.SHAPESIZE / 2 ];
PARAMS.FIXDOTRECT = [ PARAMS.CENTERX - PARAMS.DOTSIZE, PARAMS.CENTERY - PARAMS.DOTSIZE, PARAMS.CENTERX + PARAMS.DOTSIZE, PARAMS.CENTERY + PARAMS.DOTSIZE ];
               
PARAMS.BACKCOLOR = 127;
PARAMS.TEXTCOLOR = 0;
PARAMS.SHAPECOLOR = 0;
PARAMS.FIXATIONCOLOR = 255;

% Enable less stringent vertical sync tolerance -- for Retina Macs and other newer computers
Screen( 'Preference', 'SkipSyncTests', 1 );

% Run in dual-display mode if a second window is available; otherwise run in single-display mode
Screens = Screen( 'Screens' );
PARAMS.RESOLUTION = Screen( 'Resolution', max( Screens ) );
mainWindow = Screen( 'OpenWindow', max( Screens ), PARAMS.BACKCOLOR, [ 0, 0, PARAMS.RESOLUTION.width / 2, PARAMS.RESOLUTION.height ] );

Screen( mainWindow, 'TextFont', 'Arial' );
Screen( mainWindow, 'TextSize', 20 );
Screen( mainWindow, 'TextColor', PARAMS.TEXTCOLOR );
HideCursor; GetSecs; ListenChar( 2 ); KbName( 'UnifyKeyNames' ); % platform-independent responses

PARAMS.FRAMELENGTH = Screen( 'GetFlipInterval', mainWindow ); % ~0.0167 s
PARAMS.NUMFRAMESPERSEC = round( 1 / PARAMS.FRAMELENGTH ); % 60 fps
PARAMS.SLACK  = PARAMS.FRAMELENGTH / 2;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% INITIALIZE STIMULUS SPACE %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.NSHAPES = 17;
PARAMS.CENTERSTEP = 9;
PARAMS.MAXRADIUS = 8;
PARAMS.SPACEWARP = 0;

PARAMS.W =		[  0.55      1.11	 4.94        3.39	 1.54	 3.18	 0.57   ]; % frequency for 7 base dimensions
PARAMS.A =		[ 20.34     18.00	24.58       24.90	18.00	15.38	21.15   ]; % amplitude for 7 base dimensions
PARAMS.P =		[  3.20      3.64	 2.79        3.86	 3.51	 0.34	 1.08   ]; % phase for 7 base dimensions
PARAMS.STEP =	        [  0         9.00	 4.50        0	         9.00	 0	 0      ] / 3;

PARAMS.ANCHORANGLES = [ 0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330 ]; % A = zero angle point
PARAMS.ANCHORLABELS = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L' };
PARAMS.RADII = [ 2, 4, 6, 8 ];
PARAMS.RADIILABELS = { '2', '4', '6', '8' };
PARAMS.NUMANCHORS = length( PARAMS.ANCHORANGLES );
PARAMS.NUMRADII = length( PARAMS.RADII );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PROTOTYPE PARAMETERS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.PROTOTYPE.STIMDURATION = 0.500;
PARAMS.PROTOTYPE.ISI = 0.000; % no blink
PARAMS.PROTOTYPE.BLOCKGAP = 10.000; % 10 secs
PARAMS.PROTOTYPE.INITGAP = 60.000; % 60 secs
PARAMS.PROTOTYPE.RESPONSECUTOFF = 0.100; % 100 ms

PARAMS.PROTOTYPE.NPOINTS = PARAMS.NUMANCHORS * PARAMS.NUMRADII + 1; % 4 points per radius + center = 49
PARAMS.PROTOTYPE.NSHAPESPERTRIAL = 5; % 4 shapes per mini-block
PARAMS.PROTOTYPE.NREPS = 1; % 1 reps per point
PARAMS.PROTOTYPE.NTRIALS = PARAMS.PROTOTYPE.NPOINTS * PARAMS.PROTOTYPE.NREPS; % 49
PARAMS.PROTOTYPE.TRIALLENGTHTR = ( ( PARAMS.PROTOTYPE.STIMDURATION + PARAMS.PROTOTYPE.ISI ) * PARAMS.PROTOTYPE.NSHAPESPERTRIAL + PARAMS.PROTOTYPE.BLOCKGAP ) / PARAMS.TRLENGTH; % 6.25 instead of 6.00!
PARAMS.PROTOTYPE.OMMITEDTRS = 6;

PARAMS.PROTOTYPE.NRUNS = 8; % maximum runs per session

PARAMS.PROTOTYPE.POINTS = cell( 1, PARAMS.PROTOTYPE.NPOINTS ); % 1 x 49
PARAMS.PROTOTYPE.LABELS = cell( 1, PARAMS.PROTOTYPE.NPOINTS ); % 1 x 49

for a = 1 : PARAMS.NUMANCHORS
    for r = 1 : PARAMS.NUMRADII
        
        PARAMS.PROTOTYPE.POINTS{ ( a - 1 ) * PARAMS.NUMRADII + r } = [ 0, cosd( PARAMS.ANCHORANGLES( a ) ) * PARAMS.RADII( r ), sind( PARAMS.ANCHORANGLES( a ) ) * PARAMS.RADII( r ), 0, 0, 0, 0 ];
        PARAMS.PROTOTYPE.LABELS{ ( a - 1 ) * PARAMS.NUMRADII + r } = [ PARAMS.ANCHORLABELS{ a }, PARAMS.RADIILABELS{ r } ];
        
    end
end

PARAMS.PROTOTYPE.POINTS{ PARAMS.PROTOTYPE.NPOINTS } = [ 0, 0, 0, 0, 0, 0, 0 ]; % Q
PARAMS.PROTOTYPE.LABELS{ PARAMS.PROTOTYPE.NPOINTS } = 'Q0';

for run = 1 : PARAMS.PROTOTYPE.NRUNS
    
    for rep = 1 : PARAMS.PROTOTYPE.NREPS
        PARAMS.PROTOTYPE.POSITION( run, ( rep - 1 ) * PARAMS.PROTOTYPE.NPOINTS + 1 : rep * PARAMS.PROTOTYPE.NPOINTS ) = PARAMS.PROTOTYPE.POINTS;
        PARAMS.PROTOTYPE.DESC( run, ( rep - 1 ) * PARAMS.PROTOTYPE.NPOINTS + 1 : rep * PARAMS.PROTOTYPE.NPOINTS ) = PARAMS.PROTOTYPE.LABELS;
    end
    
    PARAMS.PROTOTYPE.TRIALIDX( run, : ) = randperm( PARAMS.PROTOTYPE.NTRIALS );
    PARAMS.PROTOTYPE.POSITION( run, : ) = PARAMS.PROTOTYPE.POSITION( run, PARAMS.PROTOTYPE.TRIALIDX( run, : ) );
    PARAMS.PROTOTYPE.DESC( run, : ) = PARAMS.PROTOTYPE.DESC( run, PARAMS.PROTOTYPE.TRIALIDX( run, : ) );

end

% Generate prototype run wobbles: Shape wobble for 15 frames ~ 250 ms: 0-2 per shape
PARAMS.PROTOTYPE.MINCHANGEDISTANCE = 15; % minimum distance in frames between changes; 15 frames = 0.250 secs
PARAMS.PROTOTYPE.NUMWOBBLEFRAMES = 15; % how many frames to show at ~60 fps, must be even number!, e.g. [ 0 1 2 3 4 5 6 7 8 7 6 5 4 3 2 1 ] = 16 (15) ; % 15 frames = 0.250 secs
PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE = round( PARAMS.PROTOTYPE.STIMDURATION * PARAMS.NUMFRAMESPERSEC ); % 1.5 s x 60 fps = 90 frames
PARAMS.PROTOTYPE.WOBBLERADIUS = 1; % small radius to reduce interference; no overlap between wobbles: 1 - r - r - 5 - r - r - 9 - r - r - 13
PARAMS.PROTOTYPE.WOBBLEFRAMESTEP = 2 / PARAMS.PROTOTYPE.NUMWOBBLEFRAMES;

PARAMS.PROTOTYPE.MAXCHANGESPERSHAPE = 1; % max number of fixation changes per shape
PARAMS.PROTOTYPE.RESPONSERATINGS = [ 0, 1 ]; % did wobble happen?

PARAMS.PROTOTYPE.ALLFRAMES = cell( PARAMS.PROTOTYPE.NRUNS, PARAMS.PROTOTYPE.NTRIALS, PARAMS.PROTOTYPE.NSHAPESPERTRIAL, PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE );

for run = 1 : PARAMS.PROTOTYPE.NRUNS
    for trial = 1 : PARAMS.PROTOTYPE.NTRIALS
        for shape = 1 : PARAMS.PROTOTYPE.NSHAPESPERTRIAL
            
            switch randi( [ 0, PARAMS.PROTOTYPE.MAXCHANGESPERSHAPE ] )
                case 0
                    PARAMS.PROTOTYPE.CHANGEDFRAMES{ run, trial, shape } = [];
                    
                case 1
                    PARAMS.PROTOTYPE.CHANGEDFRAMES{ run, trial, shape } = randi( PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE - PARAMS.PROTOTYPE.NUMWOBBLEFRAMES  ); % 1 / 90 -- 75 / 90
                    
                case 2
                    idx1 = randi( PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE - PARAMS.PROTOTYPE.NUMWOBBLEFRAMES * 2 - PARAMS.PROTOTYPE.MINCHANGEDISTANCE ); % 1 / 90 -- 45 / 90
                    PARAMS.PROTOTYPE.CHANGEDFRAMES{ run, trial, shape } = [ idx1, randi( [ idx1 + PARAMS.PROTOTYPE.NUMWOBBLEFRAMES - 1 + PARAMS.PROTOTYPE.MINCHANGEDISTANCE, PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE - PARAMS.PROTOTYPE.NUMWOBBLEFRAMES ] ) ];  % idx1 + 19 / 90 -- 80 / 90
                    
                case 3
                    idx1 = randi( PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE - PARAMS.PROTOTYPE.NUMWOBBLEFRAMES * 3 - PARAMS.PROTOTYPE.MINCHANGEDISTANCE * 2 ); % 1 / 90 -- 15 / 90
                    idx2 = randi( [ idx1 + PARAMS.PROTOTYPE.NUMWOBBLEFRAMES - 1 + PARAMS.PROTOTYPE.MINCHANGEDISTANCE, PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE - PARAMS.PROTOTYPE.NUMWOBBLEFRAMES * 2 - PARAMS.PROTOTYPE.MINCHANGEDISTANCE ] ); % idx1 + 19 / 90 -- 60 / 90
                    PARAMS.PROTOTYPE.CHANGEDFRAMES{ run, trial, shape } = [ idx1, idx2, randi( [ idx2 + PARAMS.PROTOTYPE.NUMWOBBLEFRAMES - 1 + PARAMS.PROTOTYPE.MINCHANGEDISTANCE, PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE - PARAMS.PROTOTYPE.NUMWOBBLEFRAMES ] ) ]; % idx2 + 19 / 90 -- 80 / 90
                    
                otherwise
                    error( 'Too many fixation changes.' );
            end
            
            PARAMS.PROTOTYPE.ALLFRAMES( run, trial, shape, : ) = repmat( PARAMS.PROTOTYPE.POSITION( run, trial ), 1, PARAMS.PROTOTYPE.NUMFRAMESPERSHAPE ); % initialize all frames with the base shape
            chf = PARAMS.PROTOTYPE.CHANGEDFRAMES{ run, trial, shape }; numChanges = length( chf );
            
            for chg = 1 : numChanges % for each change wobble over the next 15 frames
                % generate wobble shapes along ray from orig texture; multidimensional Gaussians are radially symmetric, so this gives the correct density on unit sphere
                ray = randn( 1, 2 ); % perturbation ray
                posInit = PARAMS.PROTOTYPE.POSITION{ run, trial }; % base shape
                % Make ray stay inside the circle!
                while norm( ray + posInit( [ 2, 3 ] ) ) > PARAMS.MAXRADIUS, ray = randn( 1, 2 ); end
                
                for f = 1 : PARAMS.PROTOTYPE.NUMWOBBLEFRAMES
                    pos = posInit;
                    if f <= round( PARAMS.PROTOTYPE.NUMWOBBLEFRAMES / 2 ) + 1
                        pos( [ 2, 3 ] ) = posInit( [ 2, 3 ] ) + PARAMS.PROTOTYPE.WOBBLERADIUS * ray * ( f - 1 ) * PARAMS.PROTOTYPE.WOBBLEFRAMESTEP / norm( ray );
                    else
                        pos( [ 2, 3 ] ) = posInit( [ 2, 3 ] ) + PARAMS.PROTOTYPE.WOBBLERADIUS * ray * ( PARAMS.PROTOTYPE.NUMWOBBLEFRAMES - f + 1 ) * PARAMS.PROTOTYPE.WOBBLEFRAMESTEP / norm( ray ); % track backwards towards original shape
                    end
                    
                    PARAMS.PROTOTYPE.ALLFRAMES{ run, trial, shape, chf( chg ) + f - 1 } = pos;
                end
            end
            
        end
    end
end


%%%%%%%%%%%%%%%%%%%%
%%% INSTRUCTIONS %%%
%%%%%%%%%%%%%%%%%%%%

PARAMS.INSTRUCTIONS.WAIT = 'Waiting for experimenter to start scanning run...';

PARAMS.INSTRUCTIONS.PROTOTYPE = [ 'You will see a series of abstract shapes in the center of the screen,\nwhich may jitter during their presentation.\n\n', ...
                                  'Whenever you see a shape jitter, please press the ''1'' button.\n\n', ...
                                  'This experimental run comprises several dozen trials and will take about 10 minutes to complete.\n\n', ...
                                  'Throughout the experiment, please keep your eyes fixed on the center of the screen.\n\n', ...
                                  '>>> Press ''1'' to continue <<<' ];
                    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE PARAMETERS AND CLEAN UP %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.BEGINTIME = GetSecs;
save( PARAMS.INFOFILE, 'PARAMS' );
fprintf( '\n%%%%%%%%%%%%%% EXPERIMENT %%%%%%%%%%%%%%\n>> SUBJECT %s | ID %s | INITIALIZATION COMPLETE: %.02f secs\n\n', PARAMS.SUBJECTNAME, PARAMS.SUBJECTID, GetSecs - initStartTime );

ShowCursor; Screen( 'CloseAll' ); ListenChar( 0 );
