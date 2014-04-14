
base_dir = '/Users/michael/development/sdsu/silbido/silbido-hg-repo/testing/results/';
%base_file_name = bottlenose/Qx-Tt-SCI0608-N1-060814-121518';
%base_file_name = '/Users/michael/development/sdsu/silbido/silbido-hg-repo/testing/results/bottlenose/palmyra092007FS192-070924-205305';
base_file_name = [base_dir 'bottlenose/palmyra092007FS192-070924-205730'];
%base_file_name = '/Users/michael/development/sdsu/silbido/silbido-hg-repo/testing/results/bottlenose/palmyra092007FS192-070924-205730';
%base_file_name = [base_dir 'common/Qx-Dc-CC0411-TAT11-CH2-041114-154040'];

fileName = [base_file_name '_a.d+'];
loaded_tonals = dtTonalsLoad(fileName, 0);

fprintf('\nGood Detections\n');
gd_jerk = zeros(loaded_tonals.size(),1);
gd_awt = zeros(loaded_tonals.size(),1);
gd_length = zeros(loaded_tonals.size(),1);

for idx=0:(loaded_tonals.size() - 1)
    tonal = loaded_tonals.get(idx);
   
    t_stats = tonal_stats(tonal, {'mean_jerk'}, {'mean_wait_time',2}, {'tonal_length'});
    gd_jerk(idx+1) = t_stats(1);
    gd_awt(idx+1) = t_stats(2);
    gd_length(idx+1) = t_stats(3);
    
    times = tonal.get_time();
    freqs = tonal.get_freq();
    start_time = times(1);
    start_freq = freqs(1);
    fprintf( 'Tonal starting at (%fs, %fkHz): Jerk: %f, awt: %f, length: %f\n', start_time, (start_freq / 1000), t_stats(1), t_stats(2), t_stats(3));
end

fprintf('\nFalse Posatives\n');
fileName = [base_file_name '.d-'];
loaded_tonals = dtTonalsLoad(fileName, 0);
fp_jerk = zeros(loaded_tonals.size(),1);
fp_awt = zeros(loaded_tonals.size(),1);
fp_length = zeros(loaded_tonals.size(),1);

for idx=0:(loaded_tonals.size() - 1)
    tonal = loaded_tonals.get(idx);
   
    t_stats = tonal_stats(tonal, {'mean_jerk'}, {'mean_wait_time',2}, {'tonal_length'});
    fp_jerk(idx+1) = t_stats(1);
    fp_awt(idx+1) = t_stats(2);
    fp_length(idx+1) = t_stats(3);
    
    times = tonal.get_time();
    freqs = tonal.get_freq();
    start_time = times(1);
    start_freq = freqs(1);
    fprintf( 'Tonal starting at (%fs, %fkHz): Jerk: %f, awt: %f, length: %f\n', start_time, (start_freq / 1000), t_stats(1), t_stats(2), t_stats(3));
end

figure
hold on;
plot(gd_jerk, gd_length,'g*');
plot(fp_jerk, fp_length,'r.');
hold off;