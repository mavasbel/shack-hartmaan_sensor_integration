clc;
close all;
disp('Start WFS.');
disp(' ');

% Loading the dll and header file into MATLAB
libname='C:\Program Files\IVI Foundation\VISA\Win64\Bin\WFS_64.dll';
hfile='C:\Program Files\IVI Foundation\VISA\Win64\Include\WFS.h';
if (libisloaded('WFS_64'))
    a=calllib('WFS_64','WFS_close', hdl.value);
    unloadlibrary('WFS_64');
end
if (~libisloaded('WFS_64'))
    loadlibrary(libname,hfile,...
        'includepath','C:\Program Files\IVI Foundation\VISA\Win64\Lib_x64\msc',...
        'includepath','C:\Program Files\IVI Foundation\VISA\Win64\Include',...
        'addheader','C:\Program Files\IVI Foundation\VISA\Win64\Include\visa.h',...
        'addheader','C:\Program Files\IVI Foundation\VISA\Win64\Include\vpptype.h');
end

% Displays the functions in the library
% Also gives the data types used in a command
% - Not necessary for normal use -
% libfunctionsview 'WFS_64';

% Some dll functions use pointers
% The 'libpointer' command has to be used in MATLAB for this
% Get connected WFS sensors
length=libpointer('longPtr',0);
calllib('WFS_64', 'WFS_GetInstrumentListLen',0,length);
disp(['There are ', num2str(length.value), ' WFS sensors connected']);
disp(' ');

DevID=libpointer('longPtr',0);
InUse=libpointer('longPtr',0);
InstrName=libpointer('int8Ptr',int8(zeros(1,25)));
InstrSN=libpointer('int8Ptr',int8(zeros(1,25)));
ResourceName=libpointer('int8Ptr',int8(zeros(1,25)));
for i=0:(length.value-1)
    calllib('WFS_64','WFS_GetInstrumentListInfo',0,i,DevID,InUse,InstrName,InstrSN,ResourceName);
    disp(['Device ID: ', num2str(DevID.value)]);
    disp(char(InstrName.value));
    disp(['SN: ', char(InstrSN.value)]);
    disp(' ');
end;

% Select one of the connected WFS sensors
% UsedDeviceNum = input('Device ID of the WFS you want to use: ');
UsedDeviceNum = DevID.value;
disp("Device ID of the WFS you want to use: " + UsedDeviceNum);

% Initialize the WFS
UsedDeviceStr = ['USB::0x1313::0x0000::',num2str(UsedDeviceNum)];
res=libpointer('int8Ptr',int8(UsedDeviceStr));
hdl=libpointer('ulongPtr',0);
calllib('WFS_64','WFS_init',res,1,1,hdl);

% Select microlens array 0 and configure camera
calllib('WFS_64','WFS_SelectMla', hdl.value, 0);
spotsx=libpointer('int32Ptr', 0);
spotsy=libpointer('int32Ptr', 0);
calllib('WFS_64','WFS_ConfigureCam', hdl.value, 0, 2, spotsx, spotsy); % resolution 1024x1024
calllib('WFS_64','WFS_SetReferencePlane', hdl.value, 0);
calllib('WFS_64','WFS_SetPupil', hdl.value, 0.0, 0.0, 5.0, 5.0);

resolutionx = 1024;
resolutiony = 1024;
while (true)
    % Take spotfield image
    exposureTimeAct=libpointer('doublePtr',0.0);
    masterGainAct=libpointer('doublePtr',0.0);
    
    calllib('WFS_64','WFS_TakeSpotfieldImageAutoExpos',hdl.value,exposureTimeAct,masterGainAct);
    imageBuf=libpointer('uint8Ptr',zeros(resolutionx,resolutiony));
    rows=libpointer('int32Ptr',0);
    cols=libpointer('int32Ptr',0);
    calllib('WFS_64','WFS_GetSpotfieldImageCopy', hdl.value, imageBuf, rows, cols);

    % Change buffer array and show image of spotfield
%     pic=reshape(imageBuf.value, [resolutionx,resolutiony]);
    image(imageBuf.value);

    % Drawing and pausing
    drawnow;
%     pause(0.25);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Testing functions to compute points and calculate waveront
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    calllib('WFS_64','WFS_CalcSpotsCentrDiaIntens',hdl.value,1,1);
    
    centroidx=libpointer('singlePtr',zeros(resolutionx,resolutiony));
    centroidy=libpointer('singlePtr',zeros(resolutionx,resolutiony));
    calllib('WFS_64','WFS_GetSpotCentroids',hdl.value,centroidx,centroidy);
    
    beamCentroidx=libpointer('doublePtr',0);
    beamCentroidy=libpointer('doublePtr',0);
    beamDiax=libpointer('doublePtr',0);
    beamDiay=libpointer('doublePtr',0);
    calllib('WFS_64','WFS_CalcBeamCentroidDia', hdl.value, beamCentroidx, beamCentroidy, beamDiax, beamDiay);
    
    calllib('WFS_64','WFS_CalcSpotToReferenceDeviations', hdl.value, 1);
    
    deviationx=libpointer('singlePtr',zeros(resolutionx,resolutiony));
    deviationy=libpointer('singlePtr',zeros(resolutionx,resolutiony));
    calllib('WFS_64','WFS_GetSpotDeviations', hdl.value, deviationx, deviationy);

    wavefront=libpointer('singlePtr',zeros(resolutionx,resolutiony));
    calllib('WFS_64','WFS_CalcWavefront', hdl.value, 0, 0, wavefront);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    key = get(gcf,'CurrentCharacter');
    if key==' '
        break
    end
end

% Closing the WFS driver session and unloading the dll
a=calllib('WFS_64','WFS_close', hdl.value);
unloadlibrary('WFS_64');