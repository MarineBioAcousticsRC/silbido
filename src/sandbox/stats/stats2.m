
base_dir = '/Users/michael/development/sdsu/silbido/silbido-hg-repo/testing/results/';
%base_file_name = bottlenose/Qx-Tt-SCI0608-N1-060814-121518';
%base_file_name = '/Users/michael/development/sdsu/silbido/silbido-hg-repo/testing/results/bottlenose/palmyra092007FS192-070924-205305';
base_file_name = [base_dir 'bottlenose/palmyra092007FS192-070924-205730'];
%base_file_name = '/Users/michael/development/sdsu/silbido/silbido-hg-repo/testing/results/bottlenose/palmyra092007FS192-070924-205730';
%base_file_name = [base_dir 'common/Qx-Dc-CC0411-TAT11-CH2-041114-154040'];

fileName = [base_file_name '_a.d+'];
loaded_tonals = dtTonalsLoad(fileName, 0);

fprintf('\nGood Detections\n');
gd_jerk = [];
gd_wait_times = [];

for idx=0:(loaded_tonals.size() - 1)
    tonal = loaded_tonals.get(idx);
    gd_wait_times = [gd_wait_times nth_wait_times(tonal,3)];
    gd_jerk = [gd_jerk; tonal_jerk(tonal)];
end

good_det_jerk = gd_jerk(~isnan(gd_jerk));
good_det_jerk = good_det_jerk(good_det_jerk ~= Inf);


fprintf('\nFalse Posatives\n');
fileName = [base_file_name '.d-'];
loaded_tonals = dtTonalsLoad(fileName, 0);
false_posative_jerk = [];
fp_wait_times= [];
for idx=0:(loaded_tonals.size() - 1)
    tonal = loaded_tonals.get(idx);
    fp_wait_times = [gd_wait_times nth_wait_times(tonal, 3)];
    false_posative_jerk = [false_posative_jerk; tonal_jerk(tonal)];
end

figure
%hist(fp_jerk, 40);
%h = findobj(gca,'Type','patch');
%set(h,'FaceColor','r','EdgeColor','w','facealpha',0.75)
%hold on;

hist(good_det_jerk, 40);
h1 = findobj(gca,'Type','patch');
set(h1,'FaceColor','b', 'facealpha',0.75);

hold off;