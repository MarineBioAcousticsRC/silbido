clear all;
dev_init;
callback = DTTonalsTrackingCallback();
[tonals, graphs] = dtTonalsTracking('/Users/michael/development/sdsu/silbido/corpora/filter_test/bottlenose/Qx-Tt-SCI0608-N1-060814-121518.wav',0,10, 'SPCallback', callback);
%[tonals, graphs] = dtTonalsTracking('/Users/michael/development/sdsu/silbido/corpora/filter_test/bottlenose/Qx-Tt-SCI0608-N1-060814-121518.wav',0,Inf);
%dtTonalsPlot('/Users/michael/development/sdsu/silbido/corpora/filter_test/bottlenose/Qx-Tt-SCI0608-N1-060814-121518.wav', tonals, graphs, 0, 10,'Framing', [2, 8], 'Plot', {'graph', 'tonal'});