% This file replicates the evaluation data tests as seen in Michael
% MacFadden's thesis, "Improving Performance In Graph-Based Detection of
% Odontocete Whistles Through Graph Analysis And Noise Regime Change
% Detection". Currently this only tests the baseline usage of Silbido.

% Note: see 'run_batch_test.m' for clues on how to later test for Michael's
% additions: (BIC change detection, graph-based filtering, tonal-based
% filtering).

import tonals.*;

base_dir = '/lab/speech/corpora/dclmmpa2011/';
output_dir = 'src/sandbox/testing/results/';

test_files = ...
{
'/lab/speech/corpora/dclmmpa2011/eval_data/Tursiops truncatus-SoCal/B14h20m06s08jan2011y.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Tursiops truncatus-SoCal/CC0704-TA15-070406-140350.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Tursiops truncatus-SoCal/CC0808-TA12-080820-154920.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Tursiops truncatus-Palmyra/FS480Palmyra070924x03x0002.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Tursiops truncatus-Palmyra/palmyra072006-060808-001522.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Tursiops truncatus-Palmyra/palmyra072006-060808-234000.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Delphinus capensis/CC0707-TA33-070713-202000.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Delphinus capensis/CC0808-TA26-080826-163000.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Delphinus capensis/CC0810-TA30-081029-232000.wav';
% '/lab/speech/corpora/dclmmpa2011/eval_data/Peponocephala electra/FS480Palmyra070924x05x0004 (2).wav';
% '/lab/speech/corpora/dclmmpa2011/eval_data/Peponocephala electra/FS480Palmyra071001x21x0011.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Peponocephala electra/palmyra072006-060803-231815.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Delphinus delphis/CC0707-TA04-070630-145000.wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Delphinus delphis/CC0808-TA11-080819-220000 (4).wav';
'/lab/speech/corpora/dclmmpa2011/eval_data/Delphinus delphis/CC0808-TA22-080824-170000.wav';
};

for i = 1:size(test_files,1)
    input_file = test_files{i};
    [file_path, name, ~] = fileparts(input_file);
    rel_path = file_path(size(base_dir,2)+1:end);
    
    fprintf('Tracking Tonals for file %s ...\n', input_file);
    
%     [detectedTonals] = dtTonalsTracking(input_file,0,inf, 'FilterBank', 'linear');
    [detectedTonals] = dtTonalsTracking(input_file,0,inf, 'FilterBank', 'constantQ', 'Framing', [4 4]);
    
    if (~exist(fullfile(output_dir, rel_path), 'dir'))
        mkdir(fullfile(output_dir, rel_path));
    end
    
    output_file_base = fullfile(output_dir,rel_path,name);
    det_file = strcat(output_file_base, '.det');
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