%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Filename:    PS4000_IC_Generic_Driver_Block_FFT
%
% Copyright:   Pico Technology Limited 2014
%
% Author:      KPV
%
% Description:
%   This is a MATLAB script that demonstrates how to use the
%   PicoScope 4000 Series Instrument Control Toobox driver to 
%   collect data in block mode with a trigger and then FFT values
%
%	To run this application:
%		Ensure that the following files/folders are located either in the 
%       same directory or define the path in the PS4000Config.m file:
%       
%       - picotech_ps4000_generic.mdd
%       - PS4000Constants
%       - ps4000.dll & ps4000Wrap.dll 
%       - ps4000MFile.m & ps4000WrapMFile.m
%       - PicoConstants.m
%       - PicoStatus.m
%       - Functions
%
%   Device used to generated example: PicoScope 4423 & 4262
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load Configuration Information
PS4000Config;

%% Device Connection

% Create a device object. 
% The serial number can be specified as a second input parameter.
ps4000DeviceObj = icdevice('picotech_ps4000_generic.mdd');

% Connect device object to hardware.
connect(ps4000DeviceObj);

%% Set Channels
% Default driver settings applied to channels are listed below - 
% use ps4000SetChannel to turn channels on or off and set voltage ranges, 
% coupling, as well as analogue offset.

% In this example, data is only collected on Channel A so default settings
% are used and channels B to D are switched off.

% Channels       : 1 - 3 (ps4000Enuminfo.enPS4000Channel.PS4000_CHANNEL_B - PS4000_CHANNEL_D)
% Enabled        : 0
% Type           : 1 (DC)
% Range          : 8 (ps4000Enuminfo.enPS4000Range.PS4000_5V)

% Execute device object function(s).
[status.setChB] = invoke(ps4000DeviceObj, 'ps4000SetChannel', 1, 0, 1, 8, 0.0,0);

if (ps4000DeviceObj.channelCount == 4)

	[status.setChC] = invoke(ps4000DeviceObj, 'ps4000SetChannel', 2, 0, 1, 8, 0.0,0);
	[status.setChD] = invoke(ps4000DeviceObj, 'ps4000SetChannel', 3, 0, 1, 8, 0.0,0);
	
end

%% Set Simple Trigger
% Set a trigger on Channel A, default values for delay and auto timeout are
% used.

% Trigger properties and functions are located in the Instrument
% Driver's Trigger group.

triggerGroupObj = get(ps4000DeviceObj, 'Trigger');
triggerGroupObj = triggerGroupObj(1);

% Set device to trigger automatically after 1 second
set(triggerGroupObj, 'autoTriggerMs', 1000);

% Channel     : 0 (ps4000Enuminfo.enPS4000Channel.PS4000_CHANNEL_A)
% Threshold   : 500 (mV)
% Direction   : 2 (ps4000Enuminfo.enPS4000ThresholdDirection.PS4000_RISING)

[status.SimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 500, 2);

%% Get Timebase
% Driver default timebase index used - use ps4000GetTimebase2 to query the
% driver as to suitability of using a particular timebase index then set 
% the 'timebase' property if required.

% timebase     : 161 (default)
% segment index: 0

[status.getTimebase, timeIntervalNanoSeconds, maxSamples] = invoke(ps4000DeviceObj, 'ps4000GetTimebase2', 161, 0);

%% Set Block Parameters and Capture Data
% Capture a block of data and retrieve data values for Channel A.

% Block data acquisition properties and functions are located in the 
% Instrument Driver's Block group.

blockGroupObj = get(ps4000DeviceObj, 'Block');
blockGroupObj = blockGroupObj(1);

% Set pre-trigger and post-trigger samples as required

set(ps4000DeviceObj, 'numPreTriggerSamples', 500e3);
set(ps4000DeviceObj, 'numPostTriggerSamples', 500e3);

% Capture a block of data:
%
% segment index: 0 (The buffer memory is not segmented in this example)

[status.runBlock] = invoke(blockGroupObj, 'runBlock', 0);

% Retrieve data values:
%
% start index       : 0
% segment index     : 0
% downsampling ratio: 1
% downsampling mode : 0 (ps4000Enuminfo.enPS4000RatioMode.PS4000_RATIO_MODE_NONE)

[numSamples, overflow, chA] = invoke(blockGroupObj, 'getBlockData', 0, 0, 1, 0);

% Stop the device
[status.stop] = invoke(ps4000DeviceObj, 'ps4000Stop');

%% Process Data
% Plot data values, calculate FFT and plot

figure;

% Calculate time (nanoseconds) and convert to milliseconds
% Use timeIntervalNanoSeconds output from ps4000GetTimebase2 
% or calculate from the main Programmer's Guide.

timeNs = double(timeIntervalNanoSeconds) * double([0:numSamples - 1]);
timeMs = timeNs / 1e6;

% Channel A

chAAxes = subplot(2,1,1);
plot(chAAxes,timeMs, chA, 'b');
ylim(chAAxes, [-2000 2000]);

title(chAAxes, 'Block Data Acquisition');
xlabel(chAAxes, 'Time (ms)');
ylabel(chAAxes, 'Voltage (mV)');

grid(chAAxes, 'on');
legend(chAAxes, 'Channel A');

% Calculate FFT of Channel A and plot - based on fft help file.
L = length(chA);
NFFT = 2^nextpow2(L); % Next power of 2 from length of y
Y = fft(chA, NFFT)/L;

Fs = 1/(timeIntervalNanoSeconds * 1e-9);
f = Fs/2*linspace(0, 0.001, floor(((NFFT/2)/1000) + 1)); % Reduce number of points by factor of 1000

chAFFTAxes = subplot(2,1,2);
plot(chAFFTAxes, f, 2*abs(Y(1: floor(((NFFT/2)/1000) + 1)) )); 
title(chAFFTAxes, 'Single-Sided Amplitude Spectrum of y(t)');
xlabel(chAFFTAxes, 'Frequency (Hz)');
ylabel(chAFFTAxes, '|Y(f)|');
grid(chAFFTAxes, 'on');

%% Disconnect Device

% Disconnect device object from hardware.
disconnect(ps4000DeviceObj);
