function stimulusMatrix = utils_GenerateShape( nShapes, shapeInit, manipulateDim, shapeNum, warp, sizeShape, background, Lmin )
% (c) Coraline Rinn Iordan 06/2018

% nShapes:          number of shapes to generate on continuum ; should be odd number!
% shapeInit:        baseline shape parameters
% manipulateDim:    which dimensions of stimulus space to iterate over
% shapeNum:         which shape to generate in continuum [ 1 .. nShapes ]
% warp:             modulate all shapes along w6 dimension (shift entire space)
% sizeShape:        pixel size of resulting shapes
% background:       background color
% Lmin:             stimulus color

if nargin < 1, nShapes = 13; end % identical to P. Kok shapes
if nargin < 2, shapeInit = [ 0, 0, 0, 0, 0, 0, 0 ]; end % center of original shape space
if nargin < 3, manipulateDim = [ 2 3 5 ]; end % diagonal of cube: BH
if nargin < 4, shapeNum = 1; end % first shape in continuum
if nargin < 5, warp = 0; end % original space
if nargin < 6, sizeShape = degrees2pixels( 5 ); end % create shapes that span 5 degrees of visual angle
if nargin < 7, background = 128; end % gray
if nargin < 8, Lmin = 0; end % black

params.w =		[  0.55      1.11	 4.94        3.39	 1.54	 3.18	 0.57   ]; % frequency for 7 base dimensions
params.A =		[ 20.34     18.00	24.58       24.90	18.00	15.38	21.15   ]; % amplitude for 7 base dimensions
params.P =		[  3.20      3.64	 2.79        3.86	 3.51	 0.34	 1.08   ]; % phase for 7 base dimensions
params.step =	[  0         9.00	 4.50        0	     9.00	 0		 0      ];

params.step = params.step * 1/3; % adapt params for multiple steps
params.A( 6 ) = params.A( 6 ) + warp; % modulate the amplitude of dimension #6 according to how much we want to change the shape

% generate binary stimulus mask
for i = 1 : length( params.A ), params.A( i ) = params.A( i ) + params.step( i ) * shapeInit( i ); end % jitter center of space according to shapeInit
points = zeros( 1, length( params.w ) ); % no deviation unless specified by shapeNum
points( manipulateDim ) = shapeNum - ceil( nShapes / 2 ); % center around canonical stimulus % points( [ 2 3 5 ] )
stimulusMatrix = double( utils_RFC( params, sizeShape, points ) );

% replace binary values by RGB
stimulusMatrix( stimulusMatrix == 0 ) = background;
stimulusMatrix( stimulusMatrix == 1 ) = Lmin;
