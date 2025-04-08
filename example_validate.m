%--------------------------------------------------------------------------
% Example script to load magnetic motion data from the BIDS dataset 
% and validate the accuracy of the magnetic motion tracking approach
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

% Load data and compute mean absolute error (MAE) for each ----------------
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
disp('Validation results ----------------------------')
if clinical
    disp('Clinical validation data')
else
    disp('Technical validation data')
end

fprintf(['Raw:    Mean MAE: %.' prec 'f cm, Max. MAE %.' prec 'f cm\n'],...
    100*mean(maes_raw), 100*max(maes_raw));
fprintf(['Cal-%s: Mean MAE: %.' prec 'f cm, Max. MAE %.' prec 'f cm\n'],...
    calib_select, 100*mean(maes_cal), 100*max(maes_cal));