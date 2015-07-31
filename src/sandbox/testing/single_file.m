%% Paper Files
CorpusBaseDir = '/Users/michael/development/silbido/corpora/paper_files/';
changes_cache = 'src/sandbox/testing/cache/';

RelativeFilePath = 'common/Qx-Dc-CC0411-TAT11-CH2-041114-154040-s';
    
base_dir = CorpusBaseDir;
output_dir = 'src/sandbox/testing/results/';
enableChangeDetection = false;

%changes_file = fullfile(changes_cache, [RelativeFilePath '.changes.mat']);
input_file = fullfile(CorpusBaseDir, [RelativeFilePath '.wav']);
[path, name, ~] = fileparts(input_file);
    rel_path = path(size(base_dir,2)+1:end);
    
    fprintf('Tracking Tonals for file %s ...\n', input_file);
    
    if (enableChangeDetection)
        changes_file = fullfile(changes_cache, rel_path, [name , '.changes.mat']);
        if exist(changes_file,'file')
            load(changes_file, 'noiseBoundaries');
        else
            if (~isempty(rel_path))
                mkdir(changes_cache,rel_path);
            end
            noiseBoundaries = detect_noise_changes_in_file(input_file, 0, Inf);
            save(changes_file, 'noiseBoundaries');
        end
    else
        noiseBoundaries = [];
    end

    [detectedTonals, graphs] = dtTonalsTracking(input_file,0,30, 'NoiseBoundaries', noiseBoundaries);
    
    
    mkdir(fullfile(output_dir, rel_path));
    
    output_file_base = fullfile(output_dir,rel_path,name);
    det_file = strcat(output_file_base, '.det');
    graph_file = strcat(output_file_base, '.graph');
    
    tonals.GraphIO.saveGraphs(graphs, graph_file);
    dtTonalsSave(det_file, detectedTonals);
    fprintf('Completed.\n');