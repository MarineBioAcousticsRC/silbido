addpath('/Users/michael/development/sdsu/silbido/matlab-src/utils');

if (~exist('dtTonalsSave'))
    dev_init;
end

base_dir = '/Users/michael/development/sdsu/silbido/corpora/filter_test/';
%base_dir = '/Users/michael/development/sdsu/silbido/corpora/paper_files/';
%base_dir = '/Users/michael/development/sdsu/silbido/corpora/short-test/';
output_dir = 'testing/results/';
test_files = getAllFiles(base_dir, '.wav');

for i=1:size(test_files,1)
    input_file = test_files{i};
    [path, name, ~] = fileparts(input_file);
    rel_path = path(size(base_dir,2)+1:end);
    output_file = fullfile(output_dir,rel_path,strcat(name, '.det'));
    mkdir(fullfile(output_dir, rel_path));
    fprintf('Tracking Tonals for file %s ...', input_file);
    tonals = dtTonalsTracking(input_file,0,Inf);
    dtTonalsSave(output_file, tonals);
    fprintf('Completed.\n');
end

results = scoreall('.det', base_dir, [output_dir '/score.txt'], output_dir);
dtAnalyzeResults(results);