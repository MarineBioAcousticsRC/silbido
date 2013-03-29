addpath('/Users/michael/development/sdsu/silbido/matlab-src/utils');

base_dir = '/Users/michael/development/sdsu/silbido/corpora/test/';
output_dir = './';
test_files = getAllFiles(base_dir, '.wav');

for i=1:size(test_files,1)
    input_file = test_files{i};
    [path, name, ~] = fileparts(input_file);
    rel_path = path(size(base_dir,2)+1:end);
    output_file = fullfile(output_dir,rel_path,strcat(name, '.det'));
    mkdir(fullfile(output_dir, rel_path));
    tonals = dtTonalsTracking(input_file,0,Inf);
    dtTonalsSave(output_file, tonals);
end

results = scoreall('.det', '/Users/michael/development/sdsu/silbido/corpora/test');
dtAnalyzeResults(results);