xwav_dir = '/media/dclde/DCLDE2015_HF_training/';
save_dir = '~/silbido/savedDetections/20160730/diskWritesRemoved/';
output_dir = strcat(save_dir,'whistleDensity');
mkdir(output_dir);

file_type = '*.x.wav';
% Get all of the xwav files and paths
[full_xwav,name_xwax,path_xwav] = utFindFiles(file_type,xwav_dir,true);

file_type = '*.mat';
% Get all of the detected whistle files files and paths
[full,name,path] = utFindFiles(file_type,save_dir,false);

numberFiles = size(full,1);

% If the thread pool has not yet been constructed, 
% create a new one
parallel_execution = false;
if parallel_execution && isempty(gcp('nocreate'))
    try
        poolobj = gcp;
        %addAttachedFiles(poolobj,{'/silbido/build/java/tonals'})
    catch e
        fprintf('Unable to open Matlab pool:  %s\n', e.message);
    end
end

wDensityStruct = struct;
wDensityStruct.CINMS_B = struct;
wDensityStruct.CINMS_C = struct;
wDensityStruct.DCPP_A = struct;
wDensityStruct.DCPP_B = struct;
wDensityStruct.DCPP_C = struct;
wDensityStruct.SOCAL_E = struct;
wDensityStruct.SOCAL_R = struct;

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
    
    file_parts = regexp(name(fileIdx),'_','split');
    file_site = regexprep(file_parts{1},'\d+','_');
%         
%     % create the file name to be saved
%     fileString = regexp(name(fileIdx), '\w+[^.]', 'match');
%     saveFile = strcat(output_dir,fileString{:}(1),'.mat');
%     
%     % skip if previously completed
%     if exist(saveFile{:},'file')
%         fprintf('Skipped %s because already completed \n', saveFile{:});
%         continue;
%     end
    
    whistles = load(full{fileIdx});
    whistlesDetects = whistles.detectionsToSave;
    
    numWhistles = whistlesDetects.size();
    
    
    midpts = zeros(numWhistles, 1);
    % get the midpoint of each whistle detection
    for idx = 0:numWhistles - 1 
        % Find and store midpoint for each tonal
        tonal = whistlesDetects.get(idx);
        time = tonal.get_time();
        midpts(idx+1) =  (time(1)+time(end))/2;
    end
   
    
    hdr = ioReadXWAVHeader(full_xwav{fileIdx});
%     SECS_PER_MINUTE = 60;
    fileSizeInSeconds = hdr.xhd.dSubchunkSize/hdr.xhd.SampleRate/2;
    
    histEdges = linspace(0,fileSizeInSeconds, fileSizeInSeconds+1);
    
    % creates a histogram of detected whistles for a xwav file
    wDensity = histcounts(midpts,histEdges);
%     W_DENSITY_THRESHOLD_PER_SECOND = 10;
%     binsWithWhistles = find(wDensity>W_DENSITY_THRESHOLD_PER_SECOND);
    
    site_info = regexp(name(fileIdx),'\.','split');
    
    
    
    if (~isempty(wDensity))
        wDensityStruct.(file_site{1}).(site_info{1}{1}).wDensity = ...
            wDensity;
%         wDensityStruct.(file_site{1}).(site_info{1}{1}).wBins = ...
%             binsWithWhistles;
%         wDensityStruct.(file_site{1}).(site_info{1}{1}).wCounts = ... 
%             wDensity(binsWithWhistles);
    end
    
    clear whistlesDetects;
%     
%     
%     % day to seconds conversion
%     timeBetweenDiskWrites = uniqueTimeDiffs * 24 * 60 * 60;
%     
%     % find the diskwrites to remove
%     % outliers are the indices of machine writes
%     [~,outliers] = periodic_filter(midpts, timeBetweenDiskWrites(1), ...
%         'periodOutlierPercent',10);
%     
%     % filter out the disk writes from the whistle detections
%     indicesToRemove = outliers.outlierIdx -1;
%     
%     for removeIdx = size(indicesToRemove,1):-1:1
%         whistlesDetects.remove(indicesToRemove(removeIdx));
%     end
%     
%    
%     % save the whistles with disk writes removed
%     parsave(saveFile{:}, whistlesDetects);
    
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