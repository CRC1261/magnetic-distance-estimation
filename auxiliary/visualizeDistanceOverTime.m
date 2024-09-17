function gf = visualizeDistanceOverTime(task, use_calibration) 
    gf = figure;

    label_header = ['Subfolder: sub-' task.selection{1} ', Task: ' task.selection{2} ', Datatype: ' task.data_type];

    if use_calibration
        m = task.magn.dist_cal; 
        sgtitle([label_header ', Calibration: cal-' m.cal_id], 'Interpreter', 'latex')
    else
        m = task.magn.dist; 
        sgtitle([label_header ', Uncalibrated'], 'Interpreter', 'latex')
    end

    o = task.omc.dist;
    

    cm = lines(task.N_sen * task.N_act);
    cm(8, :) = [0.6 0.6, 0.13];
    cm_dark = cm * 0.6;
    

    for i_s = 1 : task.N_sen
        for i_a = 1 : task.N_act
    
            k = ((i_s - 1) * task.N_act + i_a);
    
            ax(i_s, i_a) = subplot(task.N_sen, task.N_act, task.N_act*(i_s-1) + i_a);
            plot(task.magn.raw.t, 100*o.set(i_s, i_a).d, 'Color', cm_dark(k, :), 'LineWidth', 1.5)
            hold on
            plot(task.magn.raw.t, 100*m.set(i_s, i_a).d, 'Color', cm(k, :), 'LineWidth', 1)
            grid on
            ax(i_s, i_a).TickLabelInterpreter = 'latex';

            y_sc = 100 * [min(o.set(i_s, i_a).d), max(o.set(i_s, i_a).d)];
            ylim(y_sc + 0.2*diff(y_sc)*[-1 1])
    
            str_comb = sprintf('%s-%s', upper(task.actuators{i_a}), upper(task.sensors{i_s}));
    
            ylabel(['\textbf{' str_comb '} Distance (cm)'], 'Interpreter', 'latex', 'FontSize', 14)
            legend({'Reference', 'Estimation'}, 'Interpreter', 'latex', 'FontSize', 14)
    
            str_err = [sprintf('MAE: %.1f cm', m.set(i_s, i_a).e.mae * 100)];
            disp([str_comb ': ' str_err])
    
            text(0.01, 0.99, str_err, 'Interpreter', 'latex', 'VerticalAlignment', 'top', 'FontSize', 14, 'Units', 'normalized');
    
            if i_s == task.N_sen
                 xlabel('Time (s)', 'Interpreter', 'latex', 'FontSize', 14)
            end
        end 
    end

    linkaxes(ax, 'x')
end