function PARAMS = initializeParameters( subjectName, subjectID )
% (c) Coraline Rinn Iordan 10/2017, 03/2018

if nargin < 2, error( 'Must provide subject name and ID.' ); end

initStartTime = GetSecs;


%%%%%%%%%%%%%
%%% SETUP %%%
%%%%%%%%%%%%%

rng( 'shuffle' );

PARAMS.SUBJECTNAME = subjectName;
PARAMS.SUBJECTID = subjectID;

PARAMS.DEVICENAME = 'KEYBOARD';
KbName( 'UnifyKeyNames' );
PARAMS.RESPONSEDEVICE = -3;
PARAMS.ALLOWEDRESPONSES = { 'w', 'p' };
  
% Set paths and working directories
PARAMS.DATADIR = './data'; if ~exist( PARAMS.DATADIR, 'dir' ), mkdir( PARAMS.DATADIR ); end
PARAMS.INFOFILE = [ PARAMS.DATADIR '/info-' PARAMS.SUBJECTID '.mat' ];


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% INITIALIZE SCREEN %%%
%%%%%%%%%%%%%%%%%%%%%%%%%
               
PARAMS.BACKCOLOR = 127;
PARAMS.TEXTCOLOR = 0;
PARAMS.SHAPECOLOR = 0;
PARAMS.FIXATIONCOLOR = 255;
PARAMS.EMPHCOLOR = [ 200, 0, 80 ]; % Red

% Enable less stringent vertical sync tolerance -- for Retina Macs and other newer computers
Screen( 'Preference', 'SkipSyncTests', 1 );

% Run in dual-display mode if a second window is available; otherwise run in single-display mode
mainWindow = Screen( 'OpenWindow', max( Screen( 'Screens' ) ), PARAMS.BACKCOLOR );
PARAMS.SCREENRECT = Screen( 'Rect', mainWindow );

PARAMS.SCREENX = PARAMS.SCREENRECT( 3 );
PARAMS.SCREENY = PARAMS.SCREENRECT( 4 );
PARAMS.CENTERX = round( PARAMS.SCREENX / 2 );
PARAMS.CENTERY = round( PARAMS.SCREENY / 2 );

PARAMS.DOTSIZE = 10;
PARAMS.SHAPESIZE = 550; % round( PARAMS.SCREENX / 4 ); % 600 degrees2pixels( 5 ); % 550 for Prisma projector; 450 for MacBook 13' Retina
PARAMS.DESTINATIONSQUARE.TESTSHAPE = [ PARAMS.CENTERX - PARAMS.SHAPESIZE / 2, PARAMS.CENTERY - PARAMS.SHAPESIZE / 2, PARAMS.CENTERX + PARAMS.SHAPESIZE / 2, PARAMS.CENTERY + PARAMS.SHAPESIZE / 2 ];
PARAMS.DESTINATIONSQUARE.LEFTSHAPE = [ PARAMS.CENTERX - 2 * PARAMS.SHAPESIZE + 100, PARAMS.CENTERY - PARAMS.SHAPESIZE / 2, PARAMS.CENTERX - PARAMS.SHAPESIZE + 100, PARAMS.CENTERY + PARAMS.SHAPESIZE / 2 ];
PARAMS.DESTINATIONSQUARE.RIGHTSHAPE = [ PARAMS.CENTERX + PARAMS.SHAPESIZE - 100, PARAMS.CENTERY - PARAMS.SHAPESIZE / 2, PARAMS.CENTERX + 2 * PARAMS.SHAPESIZE - 100, PARAMS.CENTERY + PARAMS.SHAPESIZE / 2 ];
PARAMS.DESTINATIONSQUARE.FIXDOT = [ PARAMS.CENTERX - PARAMS.DOTSIZE, PARAMS.CENTERY - PARAMS.DOTSIZE, PARAMS.CENTERX + PARAMS.DOTSIZE, PARAMS.CENTERY + PARAMS.DOTSIZE ]; 

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
PARAMS.MAXRADIUS = 8; % sphere of radius 8, equivalent to NSHAPES = 17 & CENTERSTEP = 8
PARAMS.SPACEWARP = 0;

PARAMS.W =		[  0.55      1.11	 4.94        3.39	 1.54	 3.18	 0.57   ]; % frequency for 7 base dimensions
PARAMS.A =		[ 20.34     18.00	24.58       24.90	18.00	15.38	21.15   ]; % amplitude for 7 base dimensions
PARAMS.P =		[  3.20      3.64	 2.79        3.86	 3.51	 0.34	 1.08   ]; % phase for 7 base dimensions
PARAMS.STEP =	[  0         9.00	 4.50        0	     9.00	 0		 0      ] / 3;

PARAMS.ANCHORANGLES = [ 0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330 ]; % A = zero angle point ( 0, +MAXRADIUS )
PARAMS.ANCHORLABELS = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L' }; % Q = center of cube ; 8 spinward anchor points (12?)
PARAMS.RADII = [ 2, 4, 6, 8 ]; % relative to 8.0
PARAMS.RADIILABELS = { '2', '4', '6', '8' };

PARAMS.DIRECTIONS = { 'AG', 'BH', 'CI', 'DJ', 'EK', 'FL', 'GA', 'HB', 'IC', 'JD', 'KE', 'LF' };
PARAMS.NUMDIRECTIONS = length( PARAMS.DIRECTIONS ); % 12
PARAMS.NUMUNIQUEDIRECTIONS = round( PARAMS.NUMDIRECTIONS / 2 ); % 6
PARAMS.NPOINTSPERLINE = length( PARAMS.RADII ) * 2 + 1; % center Q + radii in each direction = 9

PARAMS.POINTS = cell( PARAMS.NUMDIRECTIONS, PARAMS.NPOINTSPERLINE );
PARAMS.LABELS = cell( PARAMS.NUMDIRECTIONS, PARAMS.NPOINTSPERLINE );

for a = 1 : PARAMS.NUMDIRECTIONS
        
    if a <= PARAMS.NUMUNIQUEDIRECTIONS % for first half (spinward direction)
        
        PARAMS.CATSHAPES{ a, 1 } = [ 0, cosd( PARAMS.ANCHORANGLES( a ) ) * PARAMS.MAXRADIUS, sind( PARAMS.ANCHORANGLES( a ) ) * PARAMS.MAXRADIUS, 0, 0, 0, 0 ]; % endpoint 1 @ -8.0 radius
        PARAMS.CATSHAPES{ a, 2 } = [ 0, cosd( PARAMS.ANCHORANGLES( a + PARAMS.NUMUNIQUEDIRECTIONS ) ) * PARAMS.MAXRADIUS, sind( PARAMS.ANCHORANGLES( a + PARAMS.NUMUNIQUEDIRECTIONS ) ) * PARAMS.MAXRADIUS, 0, 0, 0, 0 ]; % endpoint 2 @ +8.0 radius
        
        for r = 1 : length( PARAMS.RADII )
            
            PARAMS.POINTS{ a, r } = [ 0, cosd( PARAMS.ANCHORANGLES( a ) ) * PARAMS.RADII( r ), sind( PARAMS.ANCHORANGLES( a ) ) * PARAMS.RADII( r ), 0, 0, 0, 0 ];
            PARAMS.POINTS{ a, length( PARAMS.RADII ) + r } = [ 0, cosd( PARAMS.ANCHORANGLES( a + PARAMS.NUMUNIQUEDIRECTIONS ) ) * PARAMS.RADII( r ), sind( PARAMS.ANCHORANGLES( a + PARAMS.NUMUNIQUEDIRECTIONS ) ) * PARAMS.RADII( r ), 0, 0, 0, 0 ];
            
            PARAMS.LABELS{ a, r } = [ PARAMS.ANCHORLABELS{ a }, PARAMS.RADIILABELS{ r } ];
            PARAMS.LABELS{ a, length( PARAMS.RADII ) + r } = [ PARAMS.ANCHORLABELS{ a + PARAMS.NUMUNIQUEDIRECTIONS }, PARAMS.RADIILABELS{ r } ];
            
        end
        
        % add center at radius = 0
        PARAMS.POINTS{ a, PARAMS.NPOINTSPERLINE } = [ 0, 0, 0, 0, 0, 0, 0 ]; % Q
        PARAMS.LABELS{ a, PARAMS.NPOINTSPERLINE } = 'Q0';
        
    else % for second half (anti-spinward direction)
        
        % Reverse left / right direction
        PARAMS.CATSHAPES{ a, 1 } = PARAMS.CATSHAPES{ a - PARAMS.NUMUNIQUEDIRECTIONS, 2 };
        PARAMS.CATSHAPES{ a, 2 } = PARAMS.CATSHAPES{ a - PARAMS.NUMUNIQUEDIRECTIONS, 1 };
        
        PARAMS.POINTS( a, : ) = PARAMS.POINTS( a - PARAMS.NUMUNIQUEDIRECTIONS, : );
        PARAMS.LABELS( a, : ) = PARAMS.LABELS( a - PARAMS.NUMUNIQUEDIRECTIONS, : );
        
    end
    
    % randomize labels within each line direction
    PARAMS.TRIALIDX{ a } = randperm( PARAMS.NPOINTSPERLINE );
    PARAMS.POSITION( a, : ) = PARAMS.POINTS( a, PARAMS.TRIALIDX{ a } ); % PARAMS.PROTOTYPE.POSITION{ : }
    PARAMS.DESC( a, : ) = PARAMS.LABELS( a, PARAMS.TRIALIDX{ a } );

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PRESENTATION PARAMETERS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.LOOPDELAY = 0.250; % 5 ms
PARAMS.WAITTIME = 0.250; % wait 250 ms before accepting response
PARAMS.CROSSDUR = 0.250; % fixation cross duration

PARAMS.NRUNS = PARAMS.NUMDIRECTIONS; % 8 or 12 :: directions in the circle, both ways (AG & GA)
PARAMS.NREPETITIONS = 25;
PARAMS.NTRIALSPERRUN = PARAMS.NPOINTSPERLINE * PARAMS.NREPETITIONS; % 9 x 25 = 225

PARAMS.LINELABELS = PARAMS.DIRECTIONS;
PARAMS.RUNORDER = randperm( PARAMS.NRUNS );
PARAMS.SHOWNLINES = PARAMS.DIRECTIONS( PARAMS.RUNORDER );
PARAMS.ANGLEORDER = PARAMS.ANCHORANGLES( PARAMS.RUNORDER ); % orientation of lines according to behavioral prediction
PARAMS.CATSHAPES = PARAMS.CATSHAPES( PARAMS.RUNORDER, : ); % reorder endpoint shapes for each direction

% Generate full randomized texture presentation order (25 reps x 9 shapes per run)
for run = 1 : PARAMS.NRUNS   
    for i = 1 : PARAMS.NREPETITIONS, runIdx( :, i ) = randperm( PARAMS.NPOINTSPERLINE ); end
    
    PARAMS.RUNIDX( run, : ) = runIdx( : );
    PARAMS.ALLSHAPES( run, : ) = PARAMS.POSITION( PARAMS.RUNORDER( run ), runIdx( : ) ); % 8 x 385
    PARAMS.ALLDESC( run, : ) = PARAMS.DESC( PARAMS.RUNORDER( run ), runIdx( : ) );
end


%%%%%%%%%%%%%%%%%%%%
%%% INSTRUCTIONS %%%
%%%%%%%%%%%%%%%%%%%%

PARAMS.INSTRUCTIONS.RUNSTART = [ '>>> RUN %d / %d <<<\n\n', ...
                                 'For each run of the experiment, we generated two different categories of abstract shapes\nand chose one representative shape from each category to show you throughout the run.\n\n', ...
                                 'The representative shape from Category 1 is always shown on the LEFT side of the screen\n and the representative shape from Category 2 is always shown on the RIGHT side of the screen.\n\n', ...
                                 'On each trial you will also be shown a new abstract shape and asked to judge\nwhether it belongs to Category 1 or to Category 2.\n\n', ...
                                 'This run consists of a few hundred trials and will take about 3-4 minutes to complete.\n\n', ...
                                 '>>> Press ''1'' or ''2'' to continue <<<' ];
PARAMS.INSTRUCTIONS.RUNEND = '>>> You have completed RUN %d / %d <<<\n\nYou may take a short break before starting the next run.\n\n>>> Press ''1'' or ''2'' to continue <<<';
PARAMS.INSTRUCTIONS.XPEND = '>>> You have completed RUN %d / %d <<<\n\nThank you for participating!\n\n>>> Press ''1'' or ''2'' to exit <<<';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE PARAMETERS AND CLEAN UP %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save( PARAMS.INFOFILE, 'PARAMS' );
ShowCursor; Screen( 'CloseAll' ); ListenChar( 0 );

fprintf( '\n%%%%%%%%%%%%%% EXPERIMENT %%%%%%%%%%%%%%\n>> SUBJECT %s | ID %s | INITIALIZATION COMPLETE: %.02f secs\n\n', PARAMS.SUBJECTNAME, PARAMS.SUBJECTID, GetSecs - initStartTime );
