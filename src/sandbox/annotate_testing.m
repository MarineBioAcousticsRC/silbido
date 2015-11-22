Mode = 'analyze';
%Mode = 'annotate';

CorpusBaseDir = '/Users/michael/development/silbido/corpora/eval-data/';
%RelativeFilePath = 'common/Qx-Dd-SCI0608-Ziph-060817-100219.wav';
%RelativeFilePath = 'common/Qx-Dc-CC0411-TAT11-CH2-041114-154040-s.wav';

%CorpusBaseDir = '/Users/michael/development/silbido/corpora/single_file_test/';
%RelativeFilePath = 'Qx-Tt-SCI0608-N1-060814-121518.wav';

RelativeFilePath = 'melon-headed-whale/FS480Palmyra070924x05x0004 (2).wav';

ScoringBaseDir = 'src/sandbox/testing/results/';

dtTonalAnnotate('Mode', Mode, 'CorpusBaseDir', CorpusBaseDir, 'ScoringBaseDir', ScoringBaseDir, 'RelativeFilePath', RelativeFilePath);
%dtTonalAnnotate('Filename', [CorpusBaseDir RelativeFilePath]);