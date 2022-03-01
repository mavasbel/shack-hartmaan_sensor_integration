clc;
clear all;
close all;

initMux('COM3')

initMux('COM3');    % Do this only once, at the beginning of the play
enMux([1 1]);
setMux([1 1]);
vRampDaq([100 0]);    % meter readout = +200V
setMux([1 0]);        % meter readout = +100V
setMux([0 1]);        % meter readout = +100V (but negative, compared to ground!)
vRampDaq([0 0]);
enMux([0 0]);    

clear all            % use to properly  disconnect from the drivers.