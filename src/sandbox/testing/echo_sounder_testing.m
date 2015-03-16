%% Paper Files
CorpusBaseDir = '/Users/michael/development/silbido/corpora/paper_files/';

RelativeFilePath = 'common/Qx-Dc-CC0411-TAT11-CH2-041114-154040-s';

dtEchosounderDetection({[CorpusBaseDir RelativeFilePath, '.wav']}, ...
    'Start_s', 0, ...
    'Stop_s', 7);
    