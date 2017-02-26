root_dir = '/media/dclde/DCLDE2015_HF_training/';

save_dir = '~/silbido/savedDetections/20160730/';
mkdir(save_dir);
file_type = '*.x.wav';




% Get all of the xwav files and paths
[full,name,path] = utFindFiles(file_type,root_dir,true);

[fileList, indices] = sort(full);

name = name(indices);
path = path(indices);

numFiles = size(fileList,1);

% If the thread pool has not yet been constructed, 
% create a new one
parallel_execution = true;
if parallel_execution && isempty(gcp('nocreate'))
    try
        poolobj = gcp;
        addAttachedFiles(poolobj,{'/silbido/build/java/tonals'})
    catch e
        fprintf('Unable to open Matlab pool:  %s\n', e.message);
    end
end

for fileIndex = 1:numFiles
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
    
    fileString = regexp(name(fileIndex), '\w+[^.]', 'match');
    
    saveFile = strcat(save_dir,fileString{:}(1),'.mat');
    
    if exist(saveFile{:},'file')
        fprintf('Skipped %s because already completed \n', saveFile{:});
        continue;
    end
    
    fprintf('Working on %s \n',saveFile{:});
    whistleDetections = dtTonalsTracking(fileList{fileIndex}, ...
                                      0, inf); 
                                  
    parsave(saveFile{:}, whistleDetections);
    
end


