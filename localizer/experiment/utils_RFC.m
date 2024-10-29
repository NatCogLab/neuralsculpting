function BW = utils_RFC( par, mysize, dimvals )
% original version: Hans Op de Beeck
% (c) 2009 D Drucker
% (c) 2016 Peter Kok
% (c) 2017/10 Coraline Rinn Iordan

w = par.w;
A = par.A;
P = par.P;
step = par.step;

ODBsize = 299; % original image size used by Op De Beeck. Need this because the amplitudes and the smoothing kernel need to scale with this
A = A .* ( mysize / ODBsize );
step = step .* ( mysize / ODBsize );

% Number of pixels on circle outline
r = round( mysize / 4 );
nPixel = round( 2 * pi * r );
canvas = zeros( mysize );

% If some frequencies are not integer, the beginning and endpoint of the series will not have the same position (no closed contour)
% Here this potential difference is calculated for later use
xb = 0;
xe = 2 * pi;
yb = 0;
ye = 0;
for i = 1 : length( w )
    yb = yb + ( A( i ) + step( i ) * dimvals( i ) ) * sin( w( i ) * xb + P( i ) );
    ye = ye + ( A( i ) + step( i ) * dimvals( i ) ) * sin( w( i ) * xe + P( i ) );
end
yb = round( yb );
ye = round( ye );
d_1e = ye - yb;

Xpoly = zeros( 1, nPixel );
Ypoly = zeros( 1, nPixel );
for iPixel = 1 : nPixel
    
    % Modulation by fourier components is calculated for each point on the curve
    x = ( iPixel / nPixel ) * 2 * pi; % runs from 0-2pi
    y = mysize / 2;
    for i = 1 : length( w )
        y = y + ( A( i ) + step( i ) * dimvals( i ) ) * sin( w( i ) * x + P( i ) );
    end
    y = round( y );
    
    % This modulation is put on a circle
    % Potential correction (see above) is applied to get a closed contour
    angle = x + pi / 2;
    xcircle = mysize + r * cos( angle );
    ycircle = ( mysize / 2 ) + r + r * sin( angle );
    xcurve = round( xcircle + ( y - ( mysize / 2 ) ) * cos( angle ) );
    ycurve = round( ycircle + ( y - ( mysize / 2 ) ) * sin( angle ) );
    ycurve = round( ycurve + cos( ( angle - pi / 2 ) / 2 ) * d_1e / 2 ); % closed contour correction
    
    % X,Ypoly are the curves that define the shape ; plot( Xpoly, Ypoly ) gives the shape outline
    Xpoly( iPixel ) = xcurve - ( mysize / 2 );
    Ypoly( iPixel ) = ycurve - r;
    
end

% Smooth the shape
windsize = floor( 15 * mysize / ODBsize );
wind = ones( 1, windsize );
Xpoly = filtfilt( wind / windsize, 1, Xpoly );
Ypoly = filtfilt( wind / windsize, 1, Ypoly );

BW = imfill( roipoly( canvas, Xpoly, Ypoly ), 'holes' )';

% Find the centroid of the binary image
STATS = regionprops( BW, 'centroid' );
centroid = STATS.Centroid;

BW( round( centroid( 2 ) ), round( centroid( 1 ) ) ) = 0;

[ rows, columns ] = size( BW );
rowsToShift = round( rows / 2 - centroid( 2 ) );
columnsToShift = round( columns / 2 - centroid( 1 ) );
% Call circshift to move region to the center
BW = circshift( BW, [ rowsToShift columnsToShift ] );
