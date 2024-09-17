function calib = importCalibFromBids(path, selection)
    % Append slash at the end if necessary
    if (path(end) ~= '/') && (path(end) ~= '\')
        path = [path '/'];
    end

    file = [path 'derivatives/calibration/cal-' selection '/cal-' selection '.json'];

    if ~exist(file, 'file')
        fprintf('Selected calibration ''cal-%s'' not found in directory ''%s''\n', selection, file)
        calib = false;
        return;
    end

    cal_set = jsondecode(fileread(file));
    calib.set = cal_set;
    calib.id = selection;
end