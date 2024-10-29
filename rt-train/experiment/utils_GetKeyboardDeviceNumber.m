function kbDevice = utils_GetKeyboardDeviceNumber( deviceDescription )
% (c) Coraline Rinn Iordan 06/2018

[ index, devName ] = GetKeyboardIndices;
for device = 1 : length( index )
    if strcmp( devName( device ), deviceDescription )
        kbDevice = index( device );
    end
end
