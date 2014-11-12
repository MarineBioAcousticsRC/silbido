%% Paper Files
CorpusBaseDir = '/Users/michael/development/silbido/corpora/paper_files/';
changes_cache = 'src/sandbox/testing/cache/';

RelativeFilePath = 'common/Qx-Dc-CC0411-TAT11-CH2-041114-154040-s';
    




changes_file = fullfile(changes_cache, [RelativeFilePath '.changes.mat']);
input_file = fullfile(CorpusBaseDir, [RelativeFilePath '.wav']);
load(changes_file, 'noiseBoundaries');
dtTonalsTracking(input_file,0,7, 'NoiseBoundaries', changes_file);