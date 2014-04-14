function aSignal = spAnalytic(Signal)
% aSignal = spAnalytic(Signal)
% compute the analytic signal

aSignal = Signal + j*hilbert(Signal);
