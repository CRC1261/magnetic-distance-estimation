function task = importTaskFromBids(path, selection)
%IMPORTSUBFROMBIDS Summary of this function goes here
%   Detailed explanation goes here

    % Append slash at the end if necessary
    if (path(end) ~= '/') && (path(end) ~= '\')
        path = [path '/'];
    end

    if ~isfolder(path)
        fprintf('Selected result directory ''%s'' does not exist.\n', path)
        task = false;
        return;
    end


    % Number of tracksystems in this dataset is fixed
    p.tracksystems = {'omc', 'magn'};


    task = struct();

    % Check participants list ---------------------------------------------
    path_part = [path 'participants.tsv'];
    if ~exist(path_part, 'file')
        fprintf('File ''%s'' does not exist. Wrong data path?\n', path_part)
        task = false;
        return;
    end
    participants = readcell(path_part, 'FileType', 'text', 'Delimiter', '\t');
    for i_p = 2 : length(participants)
        if strcmp(participants{i_p, 1}, ['sub-' selection{1}]) 
            task.data_type = participants{i_p, 2};
            break;
        end
    end
    if ~isfield(task, 'data_type')
        fprintf('Selected subset ''sub-%s'' not found in participants.tsv in directory ''%s''\n', selection{1}, path)
        task = false;
        return;
    end


    % List contents in selected directory
    list_con = dir(path);

    i_s = 0;

    % Check if subset exists in selected directory ------------------------
    for i_c = 1 : length(list_con)
        if list_con(i_c).isdir && strcmp(list_con(i_c).name, ['sub-' selection{1}])
            i_s = i_c;
        end
    end

    if ~i_s
        fprintf('Selected subset ''sub-%s'' not found in directory ''%s''\n', selection{1}, path)
        task = false;
        return;
    end

    % Check if scan file exists in selected subset and load ---------------
    path_sub = [path 'sub-' selection{1} '/'];
    file_scan = ['sub-' selection{1} '_scans.tsv'];

    if exist([path_sub file_scan], 'file')
        scans = readcell([path_sub file_scan], 'FileType', 'text', 'Delimiter', '\t');
    else
        fprintf('File %s not found in selected subset ''sub-%s'' in directory ''%s''\n', file_scan, selection{1}, path)
        task = false;
        return;
    end

    % Check if selected task exists in scan file and load path and acq time
    file_omc = '';
    file_magn = '';

    N_sc = size(scans, 1);

    expr_sc = '(motion/sub-)(?<sub>[a-zA-Z0-9]+)(_task-)(?<task>[a-zA-Z0-9]+)(_tracksys-)(?<tracksys>[a-zA-Z0-9]+)(_motion.tsv)';
    for i_sc = 2 : N_sc
       args = regexp(scans{i_sc, 1}, expr_sc, 'names');
       if ~isempty(args) && strcmp(args.task, selection(2))
           switch(args.tracksys)
               case 'omc'
                   file_omc = scans{i_sc, 1};
                   dt_omc = scans{i_sc, 2};
               case 'magn'
                   file_magn = scans{i_sc, 1};
                   dt_magn = scans{i_sc, 2};
           end
       end
    end
    if isempty(file_omc) && isempty(file_magn)
         fprintf('Task %s not found in selected subset ''sub-%s'' in directory ''%s''\n', selection{2}, selection{1},  path)
         task = false;
         return;
    elseif isempty(file_omc) || isempty(file_magn)
        fprintf('Task %s incomplete in selected subset ''sub-%s'' in directory ''%s''\n', selection{2}, selection{1}, path)
        task = false;
        return;
    end

    expr_data = '(?<path>[a-zA-Z0-9/_-]+)(?=_motion.tsv)';
    % Check optical data files --------------------------------------------
    path_omc_common = [path_sub regexp(file_omc, expr_data, 'names').path];
    if ~exist([path_omc_common '_motion.json'], 'file') || ~exist([path_omc_common '_motion.tsv'], 'file') || ~exist([path_omc_common '_channels.tsv'], 'file')
        fprintf('Tracksys ''%s'' files missing in selected task ''%s'' of subset ''sub-%s'' in directory ''%s''\n', p.tracksystems{1}, selection{2}, selection{1}, path)
        task = false;
        return;
    end

    % Check magnetic data files -------------------------------------------
    path_magn_common = [path_sub regexp(file_magn, expr_data, 'names').path];
    if ~exist([path_magn_common '_motion.json'], 'file') || ~exist([path_magn_common '_motion.tsv'], 'file') || ~exist([path_magn_common '_channels.tsv'], 'file')
        fprintf('Tracksys ''%s'' files missing in selected task ''%s'' of subset ''sub-%s'' in directory ''%s''\n', p.tracksystems{2}, selection{2}, selection{1}, path)
        task = false;
        return;
    end

    % At this point, all required files are available
    % Load optical data ---------------------------------------------------
    M_sig = readmatrix([path_omc_common '_motion.tsv'], 'FileType','text', 'Delimiter', '\t');
    M_ch = readcell([path_omc_common '_channels.tsv'], 'FileType','text', 'Delimiter', '\t');
    specs = jsondecode(fileread([path_omc_common '_motion.json']));

    task.sensors = specs.SensorNodeIds;
    task.actuators = specs.ActuatorNodeIds;
    task.N_sen = length(task.sensors);
    task.N_act = length(task.actuators);
    task.N_dev = task.N_act + task.N_sen;

    task.omc.raw.T_d = seconds(dt_omc - dt_magn);
    task.omc.raw.f_s = specs.SamplingFrequency;
    task.omc.raw.L = size(M_sig, 1);
    task.omc.raw.t = (0 : task.omc.raw.L - 1) / task.omc.raw.f_s;
    task.omc.raw.set(task.N_dev, 1) = struct();

    % Map position data
    for i_d = 1 : task.N_dev
        i_p = 3*(i_d - 1);
        task.omc.raw.set(i_d, 1).p = M_sig(:, i_p + (1:3))';
    end

     % Load magnetic data -------------------------------------------------
    M_sig = readmatrix([path_magn_common '_motion.tsv'], 'FileType','text', 'Delimiter', '\t');
    M_ch = readcell([path_magn_common '_channels.tsv'], 'FileType','text', 'Delimiter', '\t');
    specs = jsondecode(fileread([path_magn_common '_motion.json']));
    task.magn.raw.f_s = specs.SamplingFrequency;
    task.magn.raw.L = size(M_sig, 1);
    task.magn.raw.t = (0 : task.magn.raw.L - 1) / task.magn.raw.f_s;
    task.magn.raw.set(task.N_sen, task.N_act) = struct();

    % Map magnetic and dipole moment data
    for i_s = 1 : task.N_sen
        for i_a = 1 : task.N_act
            i_b = 9*(i_s - 1) * task.N_act + 9*(i_a - 1);
            task.magn.raw.set(i_s, i_a).b = M_sig(:, i_b + (1:9))';
            i_m = 3*(i_a - 1) + 9*task.N_sen*task.N_act;
            task.magn.raw.set(i_s, i_a).m = M_sig(:, i_m + (1:3))';
        end
    end

    task.selection = selection;

    % Pre-allocation to avoid dissimilar structures issue
    task.omc.dist = struct();
    task.magn.dist = struct();
    task.magn.dist_cal = struct();
end

