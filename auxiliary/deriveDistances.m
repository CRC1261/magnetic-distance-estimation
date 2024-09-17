function task = deriveDistances(task, calib)
    % Derive distances from optical signals -------------------------------
    % Pre-allocation
    task.omc.dist.set(task.N_sen, task.N_act) = struct();
    task.omc.rel.set(task.N_sen, task.N_act) = struct();

    for i_s = 1 : task.N_sen
        for i_a = 1 : task.N_act
            % Compute relative distance between sensors and actuators
            d_rel = vecnorm(task.omc.raw.set(i_s + task.N_act).p - task.omc.raw.set(i_a).p);

            % Also save uninterpolated distance signal (might be useful)
            task.omc.rel.set(i_s, i_a).d = d_rel;

            % Spline interpolation to match sample rates (exclude NaNs)
            i_nan = isnan(d_rel);
            d = spline(task.omc.raw.t(~i_nan) + task.omc.raw.T_d,...
                d_rel(~i_nan), task.magn.raw.t);

            % Propagation of NaN values
            d_nan = interp1(task.omc.raw.t + task.omc.raw.T_d,...
                double(~i_nan), task.magn.raw.t, 'nearest');
            d_nan = floor(movmean(d_nan, 0.1*ceil(task.magn.raw.f_s)));
            d_nan(d_nan < 1) = nan;

            % Save in new result structure
            task.omc.dist.set(i_s, i_a).d = d .* d_nan;
        end
    end

    % Derive distances from magnetic signals without calibration ----------
    % Magnetic field constant
    mu_0 = 4 * pi * 1e-7;

    % Pre-allocation
    task.magn.dist.set(task.N_sen, task.N_act) = struct();
    for i_s = 1 : task.N_sen
        for i_a = 1 : task.N_act
            % Divide magnetic signals by magnetic dipole moment and other
            % constants
            b = zeros(9, task.magn.raw.L);

            for i_a_ch = 1 : 3
                i_s_ch = 3*(i_a_ch - 1) + (1 : 3);
                b(i_s_ch, :) = task.magn.raw.set(i_s, i_a).b(i_s_ch, :) ./ ...
                (task.magn.raw.set(i_s, i_a).m(i_a_ch) / pi * mu_0 * sqrt(3/2) * 1/2);
            end

            % Compute distance using 1 over Frobenius norm
            task.magn.dist.set(i_s, i_a).d = 1 ./ nthroot(sum(b.^2), 6);
            task.magn.dist.set(i_s, i_a).e =...
                calcErrorMetrics(task.omc.dist.set(i_s, i_a).d ,...
                task.magn.dist.set(i_s, i_a).d );
        end
    end

    % Only compute calibrated magnetic signals if calibration is provided
    if exist('calib', 'var')

        % Pre-allocation
        task.magn.dist_cal.set(task.N_sen, task.N_act) = struct();

        % Save calibration id in result struct
        task.magn.dist_cal.cal_id = calib.id;

        % Number of calibration sets in loaded calibration
        N_c = length(calib.set);

        for i_s = 1 : task.N_sen
            for i_a = 1 : task.N_act
                % Divide magnetic signals by magnetic dipole moment and other
                % constants
                b = zeros(9, task.magn.raw.L);
                for i_a_ch = 1 : 3
                    i_s_ch = 3*(i_a_ch - 1) + (1 : 3);
                    b(i_s_ch, :) = task.magn.raw.set(i_s, i_a).b(i_s_ch, :) ./ ...
                    (task.magn.raw.set(i_s, i_a).m(i_a_ch) / pi * mu_0 * sqrt(3/2) * 1/2);
                end

                % Load matching calibration for sensor-actuator pair
                for i_c = 1 : N_c
                    if strcmp(calib.set(i_c).SensorNode, task.sensors{i_s}) && ...
                            strcmp(calib.set(i_c).ActuatorNode, task.actuators{i_a})
                        w = calib.set(i_c).CalibrationWeights;
                        break;
                    end
                end
                if ~exist('w', 'var')
                    fprintf('No matching calibration set found for sensor ''%s'' and actuator ''%s''\n', task.sensors{i_s}, task.actuators{i_a})
                    return;
                end
                
                % Magnetic distance estimation with calibration weights ---
                % Apply calibration by using the weights as transfomation
                % matrixes on the magnetic signals

                b_w = zeros(9, task.magn.raw.L);
                i_b = 0;
                for i_s_ch = 1 : 3
                    % Select a 3 elem. vector from the 9 elem. magnetic vector
                    b_s = b(3*(i_s_ch - 1) + (1 : 3), :);
                    for i_a_ch = 1 : 3
                        % Select a 3 elem. vector from the 27 elem. weight vector
                        i_w = 9*(i_s_ch - 1) + 3*(i_a_ch - 1) + (1 : 3);
                        i_b = i_b + 1;
                        % Compute element-wise multiplicationa and sum up
                        b_w(i_b, :) = sum(b_s .* w(i_w), 1);
                    end
                end
                % Compute distance using 1 over Frobenius norm
                task.magn.dist_cal.set(i_s, i_a).d = 1 ./ nthroot(sum(b_w.^2), 6);
                task.magn.dist_cal.set(i_s, i_a).e =...
                calcErrorMetrics(task.omc.dist.set(i_s, i_a).d ,...
                task.magn.dist_cal.set(i_s, i_a).d );
            end
        end
    end
end