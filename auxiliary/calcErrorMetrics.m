function em = calcErrorMetrics(v, v_est)
    % Error signal (exclude NaNs)
    i_nan = ~isnan(v);
    e = v(i_nan) - v_est(i_nan);

    % Absolute error signal
    ae = abs(e);

    % Squared error signal
    se = e.^2;

    % Mean value
    em.mu = mean(e);

    % Standard deviation
    em.sigma = std(e);

    % Mean absolute error
    em.mae = mean(ae);

    % Mean squared error
    em.mse = mean(se);

    % Mean absolute percentage error
    em.mape = mean(e ./ v(i_nan));
end