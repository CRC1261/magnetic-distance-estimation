function gf = visualizeDistanceOverDistance(task, use_calibration) 
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

    for i_s = 1 : task.N_sen
        for i_a = 1 : task.N_act
    
            k = ((i_s - 1) * task.N_act + i_a);
    
            y_sc = 100 * [min(o.set(i_s, i_a).d), max(o.set(i_s, i_a).d)];

            ax(i_s, i_a) = subplot(task.N_sen, task.N_act, task.N_act*(i_s-1) + i_a);
            plot(100*o.set(i_s, i_a).d, 100*m.set(i_s, i_a).d, '.', 'Color', cm(k, :), 'LineWidth', 1)
            hold on
            plot(y_sc, y_sc, '--', 'Color', 0.2 * [1 1 1], 'LineWidth', 2);
            grid on
            ax(i_s, i_a).TickLabelInterpreter = 'latex';

            axis image

            ylim(y_sc)
            xlim(y_sc)
    
            str_comb = sprintf('%s-%s', upper(task.actuators{i_a}), upper(task.sensors{i_s}));
    
            ylabel(['\textbf{' str_comb '} Estim. distance (cm)'], 'Interpreter', 'latex', 'FontSize', 14)
    
            str_err = [sprintf('MEAN + STDVAR:\n%.2f + %.2f cm', 100*m.set(i_s, i_a).e.mu, 100*m.set(i_s, i_a).e.sigma)];
            disp([str_comb ': ' str_err])
    
            text(0.01, 0.99, replace(str_err, '+', '$\pm$'), 'Interpreter', 'latex', 'VerticalAlignment', 'top', 'FontSize', 14, 'Units', 'normalized');
    
            if i_s == task.N_sen
                 xlabel('True distance (cm)', 'Interpreter', 'latex', 'FontSize', 14)
            end
        end 
    end

end