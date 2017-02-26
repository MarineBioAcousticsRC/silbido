xwav_dir = '/media/dclde/DCLDE2015_HF_training/';
save_dir = '~/silbido/savedDetections/20160730/';
output_dir = strcat(save_dir,'diskWritesRemoved/');
mkdir(output_dir);

file_type = '*.x.wav';


% Get all of the xwav files and paths
[full_xwav,name_xwax,path_xwav] = utFindFiles(file_type,xwav_dir,true);


file_type = '*.mat';

% Get all of the .mat files and paths
[full,name,path] = utFindFiles(file_type,save_dir,false);

numberFiles = size(full,1);

% If the thread pool has not yet been constructed, 
% create a new one
parallel_execution = true;
if parallel_execution && isempty(gcp('nocreate'))
    try
        poolobj = gcp;
        %addAttachedFiles(poolobj,{'/silbido/build/java/tonals'})
    catch e
        fprintf('Unable to open Matlab pool:  %s\n', e.message);
    end
end

for fileIdx = 1 : numberFiles
    
    javaaddpath(fullfile(RootDir, ...
                'silbido/src/java/bin'));
    javaaddpath(fullfile(RootDir, ...
                'silbido/src/java/lib/Jama-1.0.3-sources.jar'));
    javaaddpath(fullfile(RootDir, ...
                'silbido/src/java/lib/Jama-1.0.3.jar'));
    javaaddpath(fullfile(RootDir, ...
                'silbido/src/java/lib/commons-math3-3.2-sources.jar'));
    javaaddpath(fullfile(RootDir, ...
                'silbido/src/java/lib/commons-math3-3.2.jar'));
    
    % create the file name to be saved
    fileString = regexp(name(fileIdx), '\w+[^.]', 'match');
    saveFile = strcat(output_dir,fileString{:}(1),'.mat');
    
    % skip if previously completed
    if exist(saveFile{:},'file')
        fprintf('Skipped %s because already completed \n', saveFile{:});
        continue;
    end
    
    whistles = load(full{fileIdx});
    whistlesDetects = whistles.detectionsToSave;
    
    numWhistles = whistlesDetects.size();
    
   
    midpts = zeros(numWhistles, 1);
    
    for idx = 0:numWhistles - 1 
        % Find and store midpoint for each tonal
        tonal = whistlesDetects.get(idx);
        time = tonal.get_time();
        midpts(idx+1) =  (time(1)+time(end))/2;
    end
    
    
    hdr = ioReadXWAVHeader(full_xwav{fileIdx});
    
    % only one disk write so do not need to remove any disk writes
    if size(hdr.raw.dnumStart,2) == 1
        parsave(saveFile{:}, whistlesDetects);
        warning('Only one disk write for %s', saveFile{:});
        continue;
    end
    
    timeDifferencesFromStart = round(diff(hdr.raw.dnumStart - ...
                                          hdr.raw.dnumStart(1)),5);
                                      
    uniqueTimeDiffs = unique(timeDifferencesFromStart);
    negIndices = find (uniqueTimeDiffs < 0);
    
    if ~isempty(negIndices)
        warning(['One of the disk writes has a time that is ' ...
                'before the start of the first disk write. ' ...
                'Will use the first positive time difference. File %s'],...
                saveFile{:});
        negativeIndices = find(uniqueTimeDiffs < 0);
        uniqueTimeDiffs(negativeIndices) = [];
    end
    
    if size(uniqueTimeDiffs,1)>1
        warning('More than one unique time difference in a file.' + ...
                'The disk writes are being written with more than' + ...
                ' one offset time');
    end
    
    % day to seconds conversion
    timeBetweenDiskWrites = uniqueTimeDiffs * 24 * 60 * 60;
    
    % find the diskwrites to remove
    % outliers are the indices of machine writes
    [~,outliers] = periodic_filter(midpts, timeBetweenDiskWrites(1), ...
        'periodOutlierPercent',10);
    
    % filter out the disk writes from the whistle detections
    indicesToRemove = outliers.outlierIdx -1;
    
    for removeIdx = size(indicesToRemove,1):-1:1
        whistlesDetects.remove(indicesToRemove(removeIdx));
    end
    
   
    % save the whistles with disk writes removed
    parsave(saveFile{:}, whistlesDetects);
    
end




% N = wDetects.size();
% midpts = zeros(N, 1);
% for idx = 0:N - 1 
%     % Find and store midpoint for each tonal
%     tonal = wDetects.get(idx);
%     time = tonal.get_time();
%     midpts(idx+1) =  (time(1)+time(end))/2;
% end
% 
% hdr = ioReadXWAVHeader(full{1})
% 

% cd ../mfa/
% [a,b] = periodic_filter(midpts, 75);
% cd ..
% edit startup.m
% startup
% cd mfa
% [a,b] = periodic_filter(midpts, 75);
% b
% bar(b.centers,b.bincounts)
% figure
% bar(b.centers,b.bincounts)
% dbstop if error
% histogram(diff(midpt))
% histogram(diff(midpts))
% hdr = ioReadXWAVHeader('/media/dclde/DCLDE2015_HF_training/CINMS_C/CINMS19C_2/CINMS19C_DL17_121101_223325.x.wav')
% hdr.raw
% hdr.xhd
% hdr.raw
% datestr(hdr.raw.dnumStart - hdr.raw.dnumStart(1))
% datestr(hdr.raw.dnumStart - hdr.raw.dnumStart(1), 'HH:MM:SS.FFF')
% datestr(diff(hdr.raw.dnumStart - hdr.raw.dnumStart(1)), 'HH:MM:SS.FFF')
% [a,b] = periodic_filter(midpts, 43.75);
% bar(b.centers,b.bincounts)
% [1:15]*43.75
% [1:15]*43.75-5
% dtTonalAnnotate('Filename','/lab/speech/corpora/dclmmpa2011/devel_data/common/Qx-Dd-SCI0608-N1-060816-142812.wav');
% ls