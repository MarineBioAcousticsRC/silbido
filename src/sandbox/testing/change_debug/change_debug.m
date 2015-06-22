wavFile = '/Users/michael/development/silbido/corpora/paper_files/common/Qx-Dc-CC0411-TAT11-CH2-041114-154040-s.wav';
changesFile = 'src/sandbox/testing/change_debug/Qx-Dc-CC0411-TAT11-CH2-041114-154040-s.changes.mat';
load(changesFile, 'noiseBoundaries');

SilbidoDebugUI('Filename', wavFile, 'NoiseBoundaries', noiseBoundaries,'ViewStart', 0);