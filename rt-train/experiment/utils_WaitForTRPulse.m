function [ pulseTime, pulseRecorded ] = utils_WaitForTRPulse( trLength, triggerKey, inputDevice, timeToWait )
% (c) Coraline Rinn Iordan 06/2018

if nargin < 3, inputDevice = -3; end
if nargin < 4, timeToWait = inf; end

pulseTime = -1; pulseRecorded = false;
loopDelay = 0.0005; % half a milisecond!
timeout = 0.050; % 50 ms waiting period for trigger

timeToWait = timeToWait + timeout;
while GetSecs < timeToWait
    WaitSecs( loopDelay );
    if timeToWait < inf % if set a time, make sure it's within 1 TR
        if GetSecs > timeToWait - ( trLength - trLength / 2 ) % only look if within a TR
            [ keyIsDown, pulseTime, keyCode ] = KbCheck( inputDevice ); KbName( keyCode )
            if keyIsDown && any( ismember( triggerKey, find( keyCode ) ) )
                pulseRecorded = true;
                break;
            end
        end
    else % if haven't set a time, just wait until the trigger is pressed
        [ keyIsDown, pulseTime, keyCode] = KbCheck( inputDevice );
        if keyIsDown && any( ismember( triggerKey, find( keyCode ) ) )
            pulseRecorded = true;
            break;
        end
    end
end

if pulseRecorded, fprintf( '|' ); else fprintf( 'X' ); end
