function [gd_stats, fp_stats] = calculate_tonal_stats(detections_base, stat_func)

[detections base] = utFindFiles({sprintf('*%s', 'det')}, {detections_base}, true);
dets_rel_path = cellfun(@(f) f(length(detections_base)+1:end), detections, 'UniformOutput', false);

% Calulate the paths of the good detections, false positive and graph
% files.
good_detection_ext = '_a.d+';
false_posative_ext = '.d-';
graphs_ext = '.graph';

good_detection_rel_paths = cellfun(@(f) strrep(f, '.det', good_detection_ext), dets_rel_path, 'UniformOutput', false);
false_pos_rel_paths = cellfun(@(f) strrep(f, '.det', false_posative_ext), dets_rel_path, 'UniformOutput', false);
graphs_rel_paths = cellfun(@(f) strrep(f, '.det', graphs_ext), dets_rel_path, 'UniformOutput', false);


gd_stats = [];
for idx=1:length(good_detection_rel_paths)
    gd_rel_path = good_detection_rel_paths{idx};
    loaded_tonals = dtTonalsLoad(fullfile(detections_base, gd_rel_path), 0);
    
    graph_rel_path = graphs_rel_paths{idx};
    sourceGraps = tonals.GraphIO.loadGraphsAsMap(fullfile(detections_base, graph_rel_path));
    
    for idx = 0:(loaded_tonals.size() - 1)
        tonal = loaded_tonals.get(idx);
        graphId = tonal.getGraphId();
        sourceGraph = sourceGraps.get(java.lang.Long(graphId));
        
        stats = stat_func(tonal, sourceGraph);
%         if (stats > 500)
%             fprintf('Filename: %s at time %f\n', gd_rel_path, sourceGraph.getAllNodes().get(0).time); 
%         end
        gd_stats = [gd_stats stats];
    end
end


fp_stats = [];
for idx=1:length(false_pos_rel_paths)
    fp_rel_path = false_pos_rel_paths{idx};
    loaded_tonals = dtTonalsLoad(fullfile(detections_base, fp_rel_path), 0);
    
    graph_rel_path = graphs_rel_paths{idx};
    sourceGraps = tonals.GraphIO.loadGraphsAsMap(fullfile(detections_base, graph_rel_path));
    
    for idx = 0:(loaded_tonals.size() - 1)
        tonal = loaded_tonals.get(idx);
        graphId = tonal.getGraphId();
        sourceGraph = sourceGraps.get(java.lang.Long(graphId));
        
        stats = stat_func(tonal, sourceGraph);
        fp_stats = [fp_stats stats];
    end
end