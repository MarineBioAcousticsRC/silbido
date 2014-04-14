function envelope = spEnvelope(signal)
% Compute the envelope of a signal

envelope = abs(spAnalytic(signal));
