addpath('/Users/michael/development/sdsu/silbido/matlab-src/utils');

if (~exist('dtTonalsSave'))
    dev_init;
end

import tonals.*;

%base_dir = '/Users/michael/development/sdsu/silbido/corpora/filter_test/';
%base_dir = '/Users/michael/development/sdsu/silbido/corpora/paper_files/';
%base_dir = '/Users/michael/development/sdsu/silbido/corpora/trouble/';
base_dir = '/Users/michael/development/sdsu/silbido/corpora/single_file_test/';
%base_dir = '/Users/michael/development/sdsu/silbido/corpora/short_beaked/';
%base_dir = '/Users/michael/development/sdsu/silbido/corpora/short-test/';
output_dir = 'src/sandbox/testing/results/';

if exist(output_dir,'dir')
    rmdir(output_dir, 's');    
end

test_files = utFindFiles({'*.wav'}, base_dir);

for i = 1:size(test_files,1)
    input_file = test_files{i};
    fprintf('Tracking Tonals for file %s ...', input_file);
    
    [detectedTonals, graphs] = dtTonalsTracking3(input_file,0,Inf);
    
    [path, name, ~] = fileparts(input_file);
    rel_path = path(size(base_dir,2)+1:end);
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