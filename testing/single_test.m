addpath('/Users/michael/development/sdsu/silbido/matlab-src/utils');

if (~exist('dtTonalsSave'))
    dev_init;
end




    input_file = 'testing/test.wav';
    output_dir = 'testing/';
    base_dir = 'testing/';
    [path, name, ~] = fileparts(input_file);
    rel_path = path(size(base_dir,2)+1:end);
    output_file = fullfile(output_dir,rel_path,strcat(name, '.det'));

    fprintf('Tracking Tonals for file %s ...', input_file);
    tonals = dtTonalsTracking(input_file,0,Inf);
    dtTonalsSave(output_file, tonals);
    fprintf('Completed.\n');


results = scoreall('.det', '/Users/michael/development/sdsu/silbido/corpora/paper_files/', [output_dir '/score.txt'], output_dir);
dtAnalyzeResults(results);