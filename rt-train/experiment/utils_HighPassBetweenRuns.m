function outputPatterns = utils_HighPassBetweenRuns( inputPatterns, TR, cutoffTime )
% (c) Megan deBettencourt 07/2011, Coraline Rinn Iordan 06/2018

% Inputs: 
% - inputPatterns:  patterns matrix [time x voxels]
% - TR:             sampling rate   [sec]
% - cutoffTime:     filter cutoff   [sec]
%
% Outputs:
% - outputPatterns: patterns vector [1 x voxels]

% Standard deviation of high pass gaussian
hp_sigma = cutoffTime / ( 2 * TR ); % FSL's approximation to calculating standard deviation

% Call MEX function to high pass according to 'fslmaths'
outputPatterns = highpass_gaussian_betweenruns( inputPatterns, hp_sigma );
