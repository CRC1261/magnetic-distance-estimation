%--------------------------------------------------------------------------
% Example script to load magnetic motion data from the BIDS dataset 
% and plot it
% jph 2024
%--------------------------------------------------------------------------
clear
close all
clc

addpath('auxiliary')

% Available subfolders/participants ---------------------------------------
% Technical data ----------------------------------------------------------
% sub-01 - technical; Actuator 0 - Sensor 0 (A0-S0)
%   1. task-calib0 (Training)
%   2. task-calib1 (Training) 
%   3. task-calib2 (Validation) 
% sub-02 - technical; Actuator 1 - Sensor 0 (A1-S0)
%   1. task-calib0 (Training)
%   2. task-calib1 (Validation)  
% sub-03 - technical; Actuator 0 - Sensor 1 (A0-S1)
%   1. task-calib0 (Training)
%   2. task-calib1 (Validation)  
% sub-04 - technical; Actuator 1 - Sensor 1 (A1-S1)
%   1. task-calib0 (Training)
%   2. task-calib1 (Validation)  
% sub-05 - technical; Actuator 0 - Sensor 2 (A0-S2)
%   1. task-calib0 (Training)
%   2. task-calib1 (Training) 
%   3. task-calib2 (Validation)  
% sub-06 - technical; Actuator 1 - Sensor 2 (A1-S2)
%   1. task-calib0 (Training)
%   2. task-calib1 (Validation)  
% sub-07 - technical; Actuator 0 - Sensor 3 (A0-S3)
%   1. task-calib0 (Training)
%   2. task-calib1 (Training) 
%   3. task-calib2 (Validation)  
% sub-08 - technical; Actuator 1 - Sensor 3 (A1-S3)
%   1. task-calib0 (Training)
%   2. task-calib1 (Validation)  
% Clinical data -----------------------------------------------------------
% sub-09 - clinical
%   1. task-walk05ms (Training)
%   2. task-walk1ms (Training)
% sub-10 - clinical
%   1. task-walk05ms (Training)
%   2. task-walk1ms (Training)
% sub-11 - clinical
%   1. task-walk05ms (Validation)
%   2. task-walk1ms (Validation)
% sub-12 - clinical
%   1. task-walk05ms (Validation)
%   2. task-walk1ms (Validation)
% sub-13 - clinical
%   1. task-walk05ms (Validation)
%   2. task-walk1ms (Validation)

% Available calibrations --------------------------------------------------
% cal-01 (Technical training data only)
% cal-02 (Clinical training data only)
% cal-03 (Technical and clinical training data)


% User select -------------------------------------------------------------
% Select local path of the dataset
path = 'C:/motion_distest_bids/data';

% Select subfolder and task to load
data_select = {'11', 'walk1ms'};

% Select calibration to load
calib_select = '01';

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