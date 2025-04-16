%--------------------------------------------------------------------------
% Example script to load magnetic motion data from the BIDS dataset 
% and plot it
% jph 2024
%--------------------------------------------------------------------------
clear
close all
clc

addpath('auxiliary')

% User select -------------------------------------------------------------
% Check the docu subfolder to get more info on the available datasets 
% and how to load them

% Select local path of the dataset
path = 'C:/data/';

% Select subfolder (e.g., sub-11) and task (e.g., task-walk05ms) to load
data_select = {'01', 'walk05ms'};

% Select calibration to load (e.g., cal-01)
calib_select = '04';

% Load --------------------------------------------------------------------
task = importTaskFromBids(path, data_select);
if ~isstruct(task)
    return
end

calib = importCalibFromBids(path, calib_select);
if ~isstruct(calib)
    return
end

task = deriveDistances(task, calib);

% Plot results ------------------------------------------------------------
% Plot results without calibration
visualizeDistanceOverTime(task, false);
visualizeDistanceOverDistance(task, false);

% Plot results with calibration
visualizeDistanceOverTime(task, true);
visualizeDistanceOverDistance(task, true);
