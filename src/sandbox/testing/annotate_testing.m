Mode = 'analyze';
CorpusBaseDir = '/Users/michael/development/sdsu/silbido/corpora/paper_files/';
ScoringBaseDir = 'testing/results/';
%ScoringBaseDir = '../foo/silbido/testing/results/';
%RelativeFilePath = 'bottlenose/Qx-Tt-SCI0608-N1-060814-121518.wav';
RelativeFilePath = 'common/Qx-Dd-SCI0608-Ziph-060817-100219.wav';
dtTonalAnnotate('Mode', Mode, 'CorpusBaseDir', CorpusBaseDir, 'ScoringBaseDir', ScoringBaseDir, 'RelativeFilePath', RelativeFilePath);