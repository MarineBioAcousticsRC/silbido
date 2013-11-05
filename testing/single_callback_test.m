clear java;
silbido_init;

if (1)
  fileName = '/Users/michael/development/sdsu/silbido/corpora/filter_test/bottlenose/Qx-Tt-SCI0608-N1-060814-121518.wav';
  startTime = 19;
  endTime = 21;
end


fileName = '/Users/michael/development/sdsu/silbido/corpora/paper_files/common/Qx-Dc-SC03-TAT09-060516-171606.wav';
startTime = 144;
endTime = 164;
  
%fileName = '/Users/michael/development/sdsu/silbido/corpora/paper_files/melon-headed/palmyra092007FS192-071004-032342.wav';
%startTime = 0;
%endTime = 10;

%fileName = '/Users/michael/development/sdsu/silbido/corpora/paper_files/common/Qx-Dc-CC0411-TAT11-CH2-041114-154040-s.wav';
%startTime = 22;
%endTime = 30;

callback = 'none';

switch (callback)
    case 'none'
        [tonals, graphs] = dtTonalsTracking(fileName,startTime,endTime);
    case 'points'
        [tonals, graphs] = dtTonalsTracking(fileName,startTime,endTime, 'SPCallback', DTTonalsTrackingCallback());
    case 'contours'
        [tonals, graphs] = dtTonalsTracking(fileName,startTime,endTime, 'SPCallback', RidgeContourCallback());
end
        

dtTonalsPlot(fileName, tonals, graphs, startTime, endTime,'Framing', [2, 8], 'Plot', {'graph', 'tonal'});