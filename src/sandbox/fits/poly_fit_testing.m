import tonals.fit.*;

close all;

times = [0.446, 0.45, 0.452, 0.454, 0.456, 0.458, 0.462, 0.464, 0.468, 0.47, 0.472, 0.474];
times_v = java.util.Vector();
for i=1:length(times)
    times_v.add(times(i));
end


freqs = [21500, 21000, 21125, 21125, 21125, 21000, 20750, 20625, 20500, 20500, 20500, 20250];
freqs_v = java.util.Vector();
for i=1:length(times)
    freqs_v.add(freqs(i));
end


dt = times(2) - times(1);

colors = ['r', 'g', 'y', 'c', 'k'];

scatter(times,freqs);
hold on;

next_time = times(end) + dt;

for i = 1:5
    
    % MATLAB Fit
    p = polyfit(times, freqs, i);
    next_freq = polyval(p, next_time);
    all_fit_freqs = polyval(p, [times next_time]);
    scatter(next_time,next_freq, colors(i));
    plot([times next_time], all_fit_freqs, colors(i));
    
    % Original FitPoly
    fp1 = tonals.FitPolyOrig(i, times_v, freqs_v);
    next_freq1 = fp1.predict(next_time);
    scatter(next_time,next_freq1, strcat(colors(i), '^'));
    
    % New Fit Poly
    fp2 = tonals.FitPolyJama(i, times_v, freqs_v);
    next_freq2 = fp2.predict(next_time);
    scatter(next_time,next_freq2, strcat(colors(i), '+'));
    
    fp3 = tonals.FitPolyCommons(i, times_v, freqs_v);
    next_freq3 = fp3.predict(next_time);
    scatter(next_time,next_freq3, strcat(colors(i), 'v'));
    
    fprintf( strcat('Order: %d\n\tMATLAB: %f\n',...
                    '\t  Orig: %f, Delta %f\n',...
                    '\t   New: %f, Delta %f\n',...
                    '\t   PTL: %f, Delta %f\n'),...
                    i, next_freq, ...
                    next_freq1, next_freq - next_freq1, ...
                    next_freq2, next_freq - next_freq2, ...
                    next_freq3, next_freq - next_freq3);
end

hold off;


