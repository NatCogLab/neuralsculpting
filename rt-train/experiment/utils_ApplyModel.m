function [ feedback, point ] = utils_ApplyModel( model, classVar, slice )
% (c) Coraline Rinn Iordan 10/2017, 04/2018, 06/2018
%
% slice : numVoxels x 1
% KLE = LLR: log-likelihood ratio between classes

positiveThreshold = 70;
negativeThreshold = 1;

point.valFull = slice' / model.PCA.coeff'; % 1 x numComponents
point.val = point.valFull( 1 : model.PCA.numDims )'; % pcaDims x 1

point.p1 = log( mvnpdf( point.val, model.KLE.mu1, model.KLE.sigma ) ); % log prob of belonging to class 1
point.p2 = log( mvnpdf( point.val, model.KLE.mu2, model.KLE.sigma ) ); % log prob of belonging to class 2

if point.p1 > point.p2, point.estClass = 1; elseif point.p1 < point.p2, point.estClass = 2; else point.estClass = 0; end

switch classVar
    case 1
        point.LLR = point.p1 - point.p2;
        point.KLE = point.LLR;
        
        if point.KLE >= model.KLE.quantileKLE1( positiveThreshold ) % top of class 1 LLR distribution
            feedback = +1; point.feedback = +1;
        elseif point.KLE <= model.KLE.quantileKLE1( negativeThreshold ) % bottom of class 1 LLR distribution
            feedback = -1; point.feedback = -1;
        else
            feedback = 0; point.feedback = 0; % wandering somewhere through the other part of the space...
        end
        
        % Compute at which percentile of LLR we are
        index = 1; while index <= 100 && point.KLE > model.KLE.quantileKLE1( index ), index = index + 1; end
        point.percKLE = index - 1;
        
    case 2
        point.LLR = point.p2 - point.p1;
        point.KLE = point.LLR;
      
        if point.KLE >= model.KLE.quantileKLE2( positiveThreshold ) % top of class 2 LLR distribution
            feedback = +1; point.feedback = +1;
        elseif point.KLE <= model.KLE.quantileKLE2( negativeThreshold ) % bottom of class 2 LLR distribution
            feedback = -1; point.feedback = -1;
        else
            feedback = 0; point.feedback = 0; % wandering somewhere through the other part of the space...
        end
        
        % Compute at which percentile of LLR we are
        index = 1; while index <= 100 && point.KLE > model.KLE.quantileKLE2( index ), index = index + 1; end
        point.percKLE = index - 1;
        
    otherwise
        error( 'MODEL EXCEPTION: Unknown class var.' );
end
