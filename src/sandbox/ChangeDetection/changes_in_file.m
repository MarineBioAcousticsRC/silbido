% This file simply tests passing the noise bounadies to one file.


output_dir = 'src/sandbox/testing/results/';
if exist(output_dir,'dir')
    rmdir(output_dir, 's');    
end

changes_cache = 'src/sandbox/testing/cache/';


%base_dir = '/Users/michael/development/silbido/corpora/paper_files/';
%filename ='common/Qx-Dc-SC03-TAT09-060516-171606.wav';

base_dir = '/Users/michael/development/silbido/corpora/single_file_test/';
filename ='Qx-Tt-SCI0608-N1-060814-121518.wav';

input_file = [base_dir, filename];

changes_file = fullfile(changes_cache, [filename, '.changes.mat']);
if exist(changes_file,'file')
    load(changes_file, 'noiseBoundaries');
else
    changes = detect_noise_changes_in_file(input_file, 0, Inf);
    save(changes_file, 'noiseBoundaries');
end

[detectedTonals, graphs] = dtTonalsTracking3(input_file,0,Inf, 'NoiseBoundaries', noiseBoundaries);
    
[path, name, ~] = fileparts(input_file);
rel_path = path(size(base_dir,2)+1:end);
mkdir(fullfile(output_dir, rel_path));

output_file_base = fullfile(output_dir,rel_path,name);
det_file = strcat(output_file_base, '.det');
graph_file = strcat(output_file_base, '.graph');

tonals.GraphIO.saveGraphs(graphs, graph_file);
dtTonalsSave(det_file, detectedTonals);
fprintf('Completed.\n');

results = scoreall( ...
    'DetExt', '.det', ...
    'Corpus', base_dir, ...
    'ResultName', [output_dir '/score'], ...
    'Detections', output_dir, ...
    'GroundTruthCriteria', [10, .3]);

dtAnalyzeResults(results);
