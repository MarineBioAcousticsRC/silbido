function  Test = trkInitTest(ToleranceS)
% Test = trkInitTest(ToleranceS)
% Data structure which describes types of conditions we track.

% Recognized test types
% CH - speaker change
% OV - speaker overlap
% PA - speaker pausen
Test.Types = {'CH', 'OV', 'PA'};
Test.Labels = {'change', 'overlap', 'pause', 'all'};
Test.TypeCount = length(Test.Types);

% for plotting
Test.TypeSymbols = {'k^', 'ms', 'gd'};
Test.TypeLines = {'k-', 'm--', 'g-.'};

Test.BICLines = {'b-o', 'g-o', 'r-o', 'm-o', 'c-o'};
Test.ToleranceS = ToleranceS;
