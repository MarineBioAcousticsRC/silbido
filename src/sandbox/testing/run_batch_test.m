addpath('/Users/michael/development/silbido/matlab-src/utils');

if (~exist('dtTonalsSave'))
    dev_init;
end

import tonals.*;

enableChangeDetection = false;

%base_dir = '/Users/michael/development/silbido/corpora/filter_test/';
base_dir = '/Users/michael/development/silbido/corpora/paper_files/';
%base_dir = '/Users/michael/development/silbido/corpora/trouble/';
%base_dir = '/Users/michael/development/silbido/corpora/single_file_test/';
%base_dir = '/Users/michael/development/silbido/corpora/eval-data/';
%base_dir = '/Users/michael/development/silbido/corpora/biowaves-2015/';
%base_dir = '/Users/michael/development/silbido/corpora/short_beaked/';
%base_dir = '/Users/michael/development/silbido/corpora/short-test/';
output_dir = 'src/sandbox/testing/results/';

if exist(output_dir,'dir')
    %rmdir(output_dir, 's');    
end

changes_cache = 'src/sandbox/testing/cache/';


test_files = utFindFiles({'*.wav'}, base_dir, true);

for i = 1:size(test_files,1)
    input_file = test_files{i};
    [path, name, ~] = fileparts(input_file);
    rel_path = path(size(base_dir,2)+1:end);
    
    fprintf('Tracking Tonals for file %s ...\n', input_file);
    
    if (enableChangeDetection)
        changes_file = fullfile(changes_cache, rel_path, [name , '.changes.mat']);
        if exist(changes_file,'file')
            load(changes_file, 'noiseBoundaries');
        else
            if (~isempty(rel_path))
                mkdir(changes_cache,rel_path);
            end
            noiseBoundaries = detect_noise_changes_in_file(input_file, 0, Inf);
            save(changes_file, 'noiseBoundaries');
        end
    else
        noiseBoundaries = [];
    end

    [detectedTonals, graphs] = dtTonalsTracking(input_file,0,Inf, 'NoiseBoundaries', noiseBoundaries);
    
    
    mkdir(fullfile(output_dir, rel_path));
    
    output_file_base = fullfile(output_dir,rel_path,name);
    det_file = strcat(output_file_base, '.det');
    graph_file = strcat(output_file_base, '.graph');
    
    tonals.GraphIO.saveGraphs(graphs, graph_file);
    dtTonalsSave(det_file, detectedTonals);
    fprintf('Completed.\n');
end

results = scoreall( ...
    'DetExt', '.det', ...
    'Corpus', base_dir, ...
    'ResultName', [output_dir '/score'], ...
    'Detections', output_dir, ...
    'GroundTruthCriteria', [10, .3]);

dtAnalyzeResults(results);