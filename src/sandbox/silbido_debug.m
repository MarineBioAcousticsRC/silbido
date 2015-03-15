NoiseBoundariesDir = 'sandbox/testing/cache/';


%% Paper Files
CorpusBaseDir = '/Users/michael/development/silbido/corpora/paper_files/';

%RelativeFilePath = 'common/Qx-Dc-CC0411-TAT11-CH2-041114-154040-s';
RelativeFilePath = 'bottlenose/Qx-Tt-SCI0608-N1-060814-121518';
 


%% EVAL DATA
CorpusBaseDir = '/Users/michael/development/silbido/corpora/eval-data/';


% BOTTLENOSE
%RelativeFilePath = 'bottlenose/B14h20m06s08jan2011y';
%RelativeFilePath = 'bottlenose/CC0704-TA15-070406-140350';
%RelativeFilePath = 'bottlenose/CC0808-TA12-080820-154920';
%RelativeFilePath = 'bottlenose/FS480Palmyra070924x03x0002';
%RelativeFilePath = 'bottlenose/palmyra072006-060808-001522';
%RelativeFilePath = 'bottlenose/palmyra072006-060808-234000';

% LONG BEAKED
%RelativeFilePath = 'longbeaked/CC0707-TA33-070713-202000';
RelativeFilePath = 'longbeaked/CC0808-TA26-080826-163000';
%RelativeFilePath = 'longbeaked/CC0810-TA30-081029-232000';

% MELON HEADED
%RelativeFilePath = 'melon-headed-whale/FS480Palmyra070924x05x0004 (2)';
%RelativeFilePath = 'melon-headed-whale/FS480Palmyra071001x21x0011';
%RelativeFilePath = 'melon-headed-whale/palmyra072006-060803-231815';


% SHORT BEAKED
%RelativeFilePath = 'shortbeaked/CC0707-TA04-070630-145000';
%RelativeFilePath = 'shortbeaked/CC0808-TA11-080819-220000 (4)';
%RelativeFilePath = 'shortbeaked/CC0808-TA22-080824-170000';


noiseFile = fullfile(NoiseBoundariesDir, [RelativeFilePath, '.changes.mat']);
waveFile = fullfile(CorpusBaseDir, [RelativeFilePath, '.wav']);

load(noiseFile, 'noiseBoundaries');

SilbidoDebugUI(...
    'Filename', waveFile, ...
    'ViewStart', 0, ...
    'ViewLength', 7, ...
    'NoiseBoundaries', noiseBoundaries);