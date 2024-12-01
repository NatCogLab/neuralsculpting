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
        PARAMS.RESPONSERATINGS = 1; % wobble happened
        
    case 'DEBUG'
        
        PARAMS.TRIGGERDEVICE = -3;
        KbName( 'UnifyKeyNames' );
        PARAMS.TRIGGERKEY = KbName( '5%' );
        
        PARAMS.RESPONSEDEVICE = PARAMS.TRIGGERDEVICE;
        PARAMS.ALLOWEDRESPONSES = { '1!' };
        PARAMS.RESPONSERATINGS = 1; % wobble happened

    otherwise
        error( 'Unknown device.' );
        
end   

% Set paths and working directories
PARAMS.DCMPATH = '/opt/MRICROGL/2-2016'; if ~exist( PARAMS.DCMPATH, 'dir' ), error( 'DCM directory not found.' ); end
PARAMS.FSLPATH = '/opt/fsl/5.0.9/bin'; if ~exist( PARAMS.FSLPATH, 'dir' ), error( 'FSL directory not found.' ); end
PARAMS.AFNIPATH = '/opt/AFNI/5-23-17-openmp'; if ~exist( PARAMS.AFNIPATH, 'dir' ), error( 'AFNI directory not found.' ); end

PARAMS.SUBJECTDIR = [ '/Data1/code/shapeBender/fmri/' PARAMS.SUBJECTID ]; if ~exist( PARAMS.SUBJECTDIR, 'dir' ), error( 'Subject directory not found.' ); end
PARAMS.DICOMDIR = [ '/Data1/subjects/' PARAMS.SUBJECTNAME( end - 7 : end - 4 ) PARAMS.SUBJECTNAME( end - 3 : end - 2 ) PARAMS.SUBJECTNAME( end - 1 : end ) '.' PARAMS.SUBJECTNAME '.' PARAMS.SUBJECTNAME ];
PARAMS.DATADIR = [ PARAMS.SUBJECTDIR '/data' ]; if ~exist( PARAMS.DATADIR, 'dir' ), mkdir( PARAMS.DATADIR ); end
PARAMS.TEMPLATEDIR = [ PARAMS.SUBJECTDIR '/templates' ]; if ~exist( PARAMS.TEMPLATEDIR, 'dir' ), error( 'Template directory not found.' ); end
PARAMS.NIFTIDIR = [ PARAMS.SUBJECTDIR '/nii' ]; if ~exist( PARAMS.NIFTIDIR, 'dir' ), mkdir( PARAMS.NIFTIDIR ); end
PARAMS.PROCESSDIR = [ PARAMS.SUBJECTDIR '/processed' ]; if ~exist( PARAMS.PROCESSDIR, 'dir' ), mkdir( PARAMS.PROCESSDIR ); end
PARAMS.FEEDBACKDIR = [ PARAMS.SUBJECTDIR '/feedback' ]; if ~exist( PARAMS.FEEDBACKDIR, 'dir' ), mkdir( PARAMS.FEEDBACKDIR ); end
PARAMS.SCRIPTSDIR = '/Data1/code/shapeBender/scripts'; if ~exist( PARAMS.SCRIPTSDIR, 'dir' ), error( 'Scripts directory not found.' ); end

dateStr = [ PARAMS.SUBJECTNAME( end - 7 : end - 4 ) '-' PARAMS.SUBJECTNAME( end - 3 : end - 2 ) '-' PARAMS.SUBJECTNAME( end - 1 : end ) ];
PARAMS.INFOFILE = [ PARAMS.DATADIR '/info-' PARAMS.SUBJECTNAME '-' dateStr '.mat' ];
PARAMS.PROTOTYPEINFOFILE = [ PARAMS.DATADIR '/prototypeinfo-' PARAMS.SUBJECTNAME '-' dateStr '_%s%d.mat' ];
PARAMS.TRAININGINFOFILE = [ PARAMS.DATADIR '/traininginfo-' PARAMS.SUBJECTNAME '-' dateStr '_%s%d.mat' ];
PARAMS.LOCALIZERTEMPLATE = 'localizer';
PARAMS.LOCALIZERANAT = 'anatLocalizer';
PARAMS.CURRENTANAT = 'anatCurrent';

% Initialize experiment timing parameters
PARAMS.TRLENGTH = 2.000; % 2 sec
PARAMS.HEMOLAG = 4.000; % 2 TRs
PARAMS.LOOPDELAY = 0.005; % 5 ms
PARAMS.DISKDELAY = 0.150; % 150 ms
PARAMS.FILTERCUTOFF = 26;


%%%%%%%%%%%%%%%%%%%%%%%%%
%%% INITIALIZE SCREEN %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.SCREENX = 1920; PARAMS.SCREENY = 1080;
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LOAD AND INITIALIZE LOCALIZER %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.LOCALIZER.DATAFILE = [ 'localizerParams-' PARAMS.SUBJECTID '.mat' ]; % localizerParams-107-TRAIN1.mat

locData = load( [ PARAMS.DATADIR '/' PARAMS.LOCALIZER.DATAFILE ] ); % localizerData.descriptions, localizerData.file, localizerData.models, localizerData.localizerIndex
PARAMS.LOCALIZER.INDEX = locData.localizerData.localizerIndex;
PARAMS.LOCALIZER.TEMPLATE = locData.localizerData.file; % 'localizer';
PARAMS.LOCALIZERTEMPLATE = PARAMS.LOCALIZER.TEMPLATE; % For backwards compatibility within utils_AlignAndExtractFunctionalSlice
PARAMS.LOCALIZER.DESCRIPTIONS = locData.localizerData.descriptions; % 'Localizer'
PARAMS.LOCALIZER.MODELS = locData.localizerData.models;


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

PARAMS.ANCHORANGLES = [ 0, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330 ]; % A = zero angle point ( 0, +MAXRADIUS )
PARAMS.ANCHORLABELS = { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L' }; % 12 spinward anchor points
PARAMS.RADII = [ 2, 4, 6, 8 ]; % relative to 8.0
PARAMS.RADIILABELS = { '2', '4', '6', '8' };
PARAMS.NUMANCHORS = length( PARAMS.ANCHORANGLES );
PARAMS.NUMRADII = length( PARAMS.RADII );


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% PROTOTYPE PARAMETERS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.PROTOTYPE.TEMPLATE = 'prototypeReference';
PARAMS.PROTOTYPE.NIFTIFILE = 'prototypeNIFTI';
PARAMS.PROTOTYPE.PREPROCESSINGSCRIPT = 'processPrototype.sh';
PARAMS.PROTOTYPE.ALIGNMENTSCRIPT = 'alignPrototype.sh';
PARAMS.PROTOTYPE.FINALFILE = 'prototypeFinal';
PARAMS.PROTOTYPE.REFERENCESLICE = 50;

PARAMS.PROTOTYPE.STIMDURATION = 0.500; % 500 msecs
PARAMS.PROTOTYPE.ISI = 0.000;
PARAMS.PROTOTYPE.BLOCKGAP = 10.000; % 10 secs
PARAMS.PROTOTYPE.INITGAP = 60.000; % 60 secs
PARAMS.PROTOTYPE.RESPONSECUTOFF = 0.100; % 100 ms
PARAMS.PROTOTYPE.MAXTRPROCTIME = 2.000; % 2 secs max processing time per slice (cummulative)

PARAMS.PROTOTYPE.NPOINTS = PARAMS.NUMANCHORS * PARAMS.NUMRADII + 1; % 4 points per radius + center = 49
PARAMS.PROTOTYPE.NSHAPESPERTRIAL = 5; % 5 shapes per mini-block
PARAMS.PROTOTYPE.NREPS = 1; % 1 reps per point
PARAMS.PROTOTYPE.NTRIALS = PARAMS.PROTOTYPE.NPOINTS * PARAMS.PROTOTYPE.NREPS; % 49
PARAMS.PROTOTYPE.TRIALLENGTHTR = ( ( PARAMS.PROTOTYPE.STIMDURATION + PARAMS.PROTOTYPE.ISI ) * PARAMS.PROTOTYPE.NSHAPESPERTRIAL + PARAMS.PROTOTYPE.BLOCKGAP ) / PARAMS.TRLENGTH; % 6.25 secs
PARAMS.PROTOTYPE.OMMITEDTRS = 6;

PARAMS.PROTOTYPE.NRUNS = 8; % max number of runs (usually collect 5-7 / day during localizer, 1 / day during training)

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
PARAMS.PROTOTYPE.RESPONSERATINGS = [ 0, 1, 2 ]; % number of wobbles

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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% RT TRAINING PARAMETERS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.TRAINING.NRUNS = 7; % 7 runs x 20 trials per run = 70 min
PARAMS.TRAINING.NTRIALSPERRUN = 20;
PARAMS.TRAINING.TRSPERTRIAL = 8; % 16 secs
PARAMS.TRAINING.INITGAP = 60.000; % 60 secs
PARAMS.TRAINING.ITI = 12; % 12 secs
PARAMS.TRAINING.TOTALRUNTRS = PARAMS.TRAINING.NTRIALSPERRUN * ( PARAMS.TRAINING.TRSPERTRIAL + round( PARAMS.TRAINING.ITI / PARAMS.TRLENGTH ) ) + round( PARAMS.TRAINING.ITI / PARAMS.TRLENGTH ) + round( PARAMS.TRAINING.INITGAP / PARAMS.TRLENGTH ); % 316 for 20 trials % includes the 6 TRs we ommit
PARAMS.TRAINING.OMMITEDTRS = 6;

PARAMS.TRAINING.FEEDBACKGRANULARITY = 1; % 1 TR = 2.000 sec
PARAMS.TRAINING.NSWITCHESPERTRIAL = round( PARAMS.TRAINING.TRSPERTRIAL / PARAMS.TRAINING.FEEDBACKGRANULARITY ); % 1 switch / TR
PARAMS.TRAINING.NUMFRAMESPERSHAPE = round( ( PARAMS.TRAINING.TRSPERTRIAL / PARAMS.TRAINING.NSWITCHESPERTRIAL ) * PARAMS.TRLENGTH * PARAMS.NUMFRAMESPERSEC );
PARAMS.TRAINING.HEMOLAGTRS = round( PARAMS.HEMOLAG / PARAMS.TRLENGTH ); % 2 TRs @ 2.000 sec each
PARAMS.TRAINING.NUMCOMPUTEDFRAMESPERSHAPE = round( PARAMS.TRAINING.NUMFRAMESPERSHAPE / 3 ); % display at 20 Hz instead of 60 Hz to accomodate Skyra projector ACK lag
PARAMS.TRAINING.NUMFRAMESPERWOBBLE = 10;
PARAMS.TRAINING.FRAMESTEP = 2 / PARAMS.TRAINING.NUMFRAMESPERWOBBLE; % we have to go forward and backwards!
PARAMS.TRAINING.NUMWOBBLESPERSHAPE = round( PARAMS.TRAINING.NUMCOMPUTEDFRAMESPERSHAPE / PARAMS.TRAINING.NUMFRAMESPERWOBBLE ); % 4 wobbles every 2 secs

PARAMS.TRAINING.TRCUTOFF = 1.000; % must find the file from the previous TR at most 1.000 sec before the next TR starts to allow enough time for processing
PARAMS.TRAINING.TRAILINGTRS = 1; % don't use trailing average
PARAMS.TRAINING.DISPLAYCUTOFF = 0.200; % must find feedback 200 ms before next trial

% Establish categories between anchor labels to maximize model training data
PARAMS.TRAINING.NSHAPES = 17;
PARAMS.TRAINING.CENTERSTEP = 9;
PARAMS.TRAINING.CATEGORY1 = { 'E', 'F', 'G', 'H', 'I', 'J' };
% 130 = { 'B', 'C', 'D', 'E', 'F', 'G' };
% 129 = { 'C', 'D', 'E', 'F', 'G', 'H' };
% 126 = { 'E', 'F', 'G', 'H', 'I', 'J' };
% 124 = { 'D', 'E', 'F', 'G', 'H', 'I' };
% 121 = { 'D', 'E', 'F', 'G', 'H', 'I' };
% 119 = { 'A', 'B', 'C', 'D', 'E', 'F' }; 
% 118 = { 'B', 'C', 'D', 'E', 'F', 'G' };
% 117 = { 'C', 'D', 'E', 'F', 'G', 'H' };
% 110 = { 'F', 'G', 'H', 'I', 'J', 'K' };
% 107 = { 'E', 'F', 'G', 'H', 'I', 'J' };
PARAMS.TRAINING.CATEGORY2 = { 'K', 'L', 'A', 'B', 'C', 'D' };
% 130 = { 'H', 'I', 'J', 'K', 'L', 'A' };
% 129 = { 'I', 'J', 'K', 'L', 'A', 'B' };
% 126 = { 'K', 'L', 'A', 'B', 'C', 'D' };
% 124 = { 'J', 'K', 'L', 'A', 'B', 'C' };
% 121 = { 'J', 'K', 'L', 'A', 'B', 'C' };
% 119 = { 'G', 'H', 'I', 'J', 'K', 'L' };
% 118 = { 'H', 'I', 'J', 'K', 'L', 'A' };
% 117 = { 'I', 'J', 'K', 'L', 'A', 'B' };
% 110 = { 'L', 'A', 'B', 'C', 'D'. 'E' };
% 107 = { 'K', 'L', 'A', 'B', 'C', 'D' };

PARAMS.TRAINING.ANGLEGAP = 30;

PARAMS.TRAINING.WOBBLERANGE.CAT1angle = 120 + [ 0 - PARAMS.TRAINING.ANGLEGAP / 2, 180 - PARAMS.TRAINING.ANGLEGAP / 2 ]; % var + [ -015 : +165 ]
% 130: 030 + -015 : +165 == +015 : +195 :: A/B to G/H :: BCDEFG vs. HIJKLA
% 129: 060 + -015 : +165 == +045 : +225 :: B/C to H/I :: CDEFGH vs. IJKLAB
% 126: 120 + -015 : +165 == +105 : +285 :: D/E to J/K :: EFGHIJ vs. KLABCD   
% 124: 090 + -015 : +165 == +075 : +255 :: C/D to I/J :: DEFGHI vs. JKLABC
% 121: 090 + -015 : +165 == +075 : +255 :: C/D to I/J :: DEFGHI vs. JKLABC   
% 119: 000 + -015 : +165 == -015 : +165 :: L/A to F/G :: ABCDEF vs. GHIJKL   
% 118: 030 + -015 : +165 == +015 : +195 :: A/B to G/H :: BCDEFG vs. HIJKLA
% 117: 060 + -015 : +165 == +045 : +225 :: B/C to H/I :: CDEFGH vs. IJKLAB
% 110: 150 + -015 : +165 == +135 : +315 :: E/F to K/L :: FGHIJK vs. LABCDE
% 107: 120 + -015 : +165 == +105 : +285 :: D/E to J/K :: EFGHIJ vs. KLABCD

PARAMS.TRAINING.WOBBLERANGE.CAT2angle = 120 + [ 180 - PARAMS.TRAINING.ANGLEGAP / 2, 360 - PARAMS.TRAINING.ANGLEGAP / 2 ]; % var + [ +165 : +345 ]
% 130: 030 + +165 : +345 == +195 : +015 :: G/H to A/B :: HIJKLA vs. BCDEFG
% 129: 060 + +165 : +345 == +225 : +045 :: H/I to B/C :: IJKLAB vs. CDEFGH
% 126: 120 + +165 : +345 == +285 : +105 :: J/K to D/E :: KLABCD vs. EFGHIJ
% 124: 090 + +165 : +345 == +255 : +075 :: I/J to C/D :: JKLABC vs. DEFGHI
% 121: 090 + +165 : +345 == +255 : +075 :: I/J to C/D :: JKLABC vs. DEFGHI
% 119: 000 + +165 : +345 == +165 : +345 :: F/G to L/A :: GHIJKL vs. ABCDEF
% 118: 030 + +165 : +345 == +195 : +015 :: G/H to A/B :: HIJKLA vs. BCDEFG
% 117: 060 + +165 : +345 == +225 : +045 :: H/I to B/C :: IJKLAB vs. CDEFGH
% 110: 150 + +165 : +345 == +315 : +135 :: K/L to E/F :: LABCDE vs. FGHIJK
% 107: 120 + +165 : +345 == +285 : +105 :: J/K to D/E :: KLABCD vs. EFGHIJ

PARAMS.TRAINING.RADIUSRANGE = [ 0, PARAMS.MAXRADIUS ];
PARAMS.TRAINING.MINDIST = 1.00; % enforce 1-unit gap along category boundary and along direction perpendicular to it, e.g., AG & DJ -- this ensures that initial wobble remains fully within target category and that classifier confusion close to boundary is minimized

PARAMS.TRAINING.INITWOBBLE = +1.875;
PARAMS.TRAINING.WOBBLESTEP = 0.625;
PARAMS.TRAINING.MINWOBBLE = +0.000;
PARAMS.TRAINING.MAXWOBBLE = +2.500;
 
for run = 1 : PARAMS.TRAINING.NRUNS % 7
    
    % Let all trials vary randomly within each run in equal proportion
    allTrials = [ ones( 1, round( PARAMS.TRAINING.NTRIALSPERRUN / 2 ) ), 2 * ones( 1, round( PARAMS.TRAINING.NTRIALSPERRUN / 2 ) ) ];
    PARAMS.TRAINING.NEWORDER = randperm( length( allTrials ) );
    PARAMS.TRAINING.TRIALORDER( run, : ) = allTrials( PARAMS.TRAINING.NEWORDER );
    
    for trial = 1 : PARAMS.TRAINING.NTRIALSPERRUN % 20
        
        inCat = 0;
        switch( PARAMS.TRAINING.TRIALORDER( run, trial ) )
            
            case 1 % ABCDEF
                while ~inCat
                    angle = PARAMS.TRAINING.WOBBLERANGE.CAT1angle( 1 ) + ( PARAMS.TRAINING.WOBBLERANGE.CAT1angle( 2 ) - PARAMS.TRAINING.WOBBLERANGE.CAT1angle( 1 ) ) .* rand;
                    radius = PARAMS.TRAINING.RADIUSRANGE( 1 ) + ( PARAMS.TRAINING.RADIUSRANGE( 2 ) - PARAMS.TRAINING.RADIUSRANGE( 1 ) ) .* rand;
                    point = [ 0, cosd( angle ) * radius, sind( angle ) * radius, 0, 0, 0, 0 ];
                    
                    if abs( sind( angle - PARAMS.TRAINING.WOBBLERANGE.CAT1angle( 1 ) ) * radius ) > PARAMS.TRAINING.MINDIST && ...
                       abs( sind( angle - PARAMS.TRAINING.WOBBLERANGE.CAT1angle( 2 ) - 90 ) * radius ) > PARAMS.TRAINING.MINDIST, inCat = 1; end % at least 1 unit away from horz and vert boundaries
                end
                PARAMS.TRAINING.BASESHAPE{ run, trial } = point;
                
            case 2 % GHIJKL
                while ~inCat
                    angle = PARAMS.TRAINING.WOBBLERANGE.CAT2angle( 1 ) + ( PARAMS.TRAINING.WOBBLERANGE.CAT2angle( 2 ) - PARAMS.TRAINING.WOBBLERANGE.CAT2angle( 1 ) ) .* rand;
                    radius = PARAMS.TRAINING.RADIUSRANGE( 1 ) + ( PARAMS.TRAINING.RADIUSRANGE( 2 ) - PARAMS.TRAINING.RADIUSRANGE( 1 ) ) .* rand;
                    point = [ 0, cosd( angle ) * radius, sind( angle ) * radius, 0, 0, 0, 0 ];
            
                    if abs( sind( angle - PARAMS.TRAINING.WOBBLERANGE.CAT2angle( 1 ) ) * radius ) > PARAMS.TRAINING.MINDIST && ...
                       abs( sind( angle - PARAMS.TRAINING.WOBBLERANGE.CAT2angle( 2 ) - 90 ) * radius ) > PARAMS.TRAINING.MINDIST, inCat = 1; end % at least 1 unit away from horz and vert boundaries (for symmetry)
                end
                PARAMS.TRAINING.BASESHAPE{ run, trial } = point;
                
            otherwise
                error( 'Unknown shape category.' );
                
        end
        
    end
    
end

% Generate set of random rays for wobblage
PARAMS.TRAINING.RAY = cell( PARAMS.TRAINING.NRUNS, PARAMS.TRAINING.NTRIALSPERRUN, PARAMS.TRAINING.NSWITCHESPERTRIAL, PARAMS.TRAINING.NUMWOBBLESPERSHAPE ); % 7 x 20 x 8 x 4
for run = 1 : PARAMS.TRAINING.NRUNS
    for trial = 1 : PARAMS.TRAINING.NTRIALSPERRUN
        ray = randn( 1, 3 ); ray( 3 ) = 0; % one ray per trial to eliminate speed confusion
        for shape = 1 : PARAMS.TRAINING.NSWITCHESPERTRIAL
            for wob = 1 : PARAMS.TRAINING.NUMWOBBLESPERSHAPE
                PARAMS.TRAINING.RAY{ run, trial, shape, wob } = ray / norm( ray );
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
                    
PARAMS.INSTRUCTIONS.TRAINING = [ 'During each trial, you will see an abstract shape in the center of the screen,\nwhich will continuously jitter.\n\n', ...
                                 'Your goal throughout each trial is to generate a mental state that will\nREDUCE THE INTENSITY OF THE JITTER.\n', ...
                                 'You are welcome to explore any mental strategies you want to achieve this goal.\n\n', ...
                                 'Please remember that the SHAPES WILL CHANGE SLOWLY and it will take SUSTAINED CONCENTRATION of several seconds\non a particular mental state to cause actual change in the shapes.\n\n', ...
                                 'We expect this task to be quite difficult at first,\nbut it is possible to stop the shape from jittering altogether with enough training.\n\n', ...
                                 'This experimental run comprises 10-20 trials and will take about 10 minutes to complete.\n', ...
                                 'Between trials, a countdown will be shown in the center of the screen for several seconds before a new shape will appear.\n\n', ...
                                 'Throughout the experiment, please keep your eyes fixed on the center of the screen.\n\n', ...
                                 '>>> Press ''1'' to continue <<<' ];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SAVE PARAMETERS AND CLEAN UP %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PARAMS.BEGINTIME = GetSecs;
save( PARAMS.INFOFILE, 'PARAMS' );

fprintf( '\n%%%%%%%%%%%%%% EXPERIMENT %%%%%%%%%%%%%%\n>> SUBJECT %s | ID %s | INITIALIZATION COMPLETE: %.02f secs\n\n', PARAMS.SUBJECTNAME, PARAMS.SUBJECTID, GetSecs - initStartTime );
ShowCursor; Screen( 'CloseAll' ); ListenChar( 0 );
