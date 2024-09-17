%--------------------------------------------------------------------------
% Example script to load magnetic motion data from the BIDS dataset 
% and validate the accuracy of the magnetic motion tracking approach
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

% User select -------------------------------------------------------------
% Select local path of the dataset
path = 'C:/motion_distest_bids/data';

% Use clinical (true) or technical (false) validation data
clinical = false;

if clinical
    data_select = {{'11', 'walk05ms'},...
                {'11', 'walk1ms'},...
                {'12', 'walk05ms'},...
                {'12', 'walk1ms'},...
                {'13', 'walk05ms'},...
                {'13', 'walk1ms'}...
                };
else
    data_select = {{'01', 'calib2'},...
                {'02', 'calib1'},...
                {'03', 'calib1'},...
                {'04', 'calib1'},...
                {'05', 'calib2'},...
                {'06', 'calib1'},...
                {'07', 'calib2'},...
                {'08', 'calib1'},...
                };
end

% Available calibrations --------------------------------------------------
% cal-01 (Technical training data only)
% cal-02 (Clinical training data only)
% cal-03 (Technical and clinical training data)

% Select calibration to load
calib_select = '03';


calib = importCalibFromBids(path, calib_select);
if ~isstruct(calib)
    return
end

% Load data and compute mean absolute error (mae) for each ----------------
% Allocate empty vectors for mae results (raw and calibrated)
maes_raw = [];
maes_cal = [];

N_sel = length(data_select);
for i = 1 : N_sel
    task = importTaskFromBids(path, data_select{i});
    if ~isstruct(task)
        return
    end
       
    task = deriveDistances(task, calib);

    % Save error results in the corresponding structs
    for i_s = 1 : task.N_sen
        for i_a = 1 : task.N_act
            maes_raw = [maes_raw task.magn.dist.set(i_s, i_a).e.mae];
            maes_cal = [maes_cal task.magn.dist_cal.set(i_s, i_a).e.mae];
        end
    end
end

% Output results ----------------------------------------------------------
% Mean MAE: Mean of all computed MAEs (overall performance)
% Max. MAE: Error of worst performing actuator-sensor combination

% Specify number of decimals
prec = num2str(1);

% Print results
fprintf(['Raw:    Mean MAE: %.' prec 'f cm, Max. MAE %.' prec 'f cm\n'],...
    100*mean(maes_raw), 100*max(maes_raw));
fprintf(['Cal-%s: Mean MAE: %.' prec 'f cm, Max. MAE %.' prec 'f cm\n'],...
    calib_select, 100*mean(maes_cal), 100*max(maes_cal));