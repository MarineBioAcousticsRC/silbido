function [gd_stats, fp_stats] = calculate_tonal_stats(detections_base, stat_func)

[detections base] = utFindFiles({sprintf('*%s', 'det')}, {detections_base}, true);
dets_rel_path = cellfun(@(f) f(length(detections_base)+1:end), detections, 'UniformOutput', false);

good_detection_ext = '_a.d+';
false_posative_ext = '.d-';

good_detection_rel_paths = cellfun(@(f) strrep(f, '.det', good_detection_ext), dets_rel_path, 'UniformOutput', false);
gd_stats = [];
for idx=1:length(good_detection_rel_paths)
    gd_rel_path = good_detection_rel_paths{idx};
    abs_path = fullfile(detections_base, gd_rel_path);
    loaded_tonals = dtTonalsLoad(abs_path, 0);
    for idx = 0:(loaded_tonals.size() - 1)
        tonal = loaded_tonals.get(idx);
        stats = stat_func(tonal);
        gd_stats = [gd_stats stats];
    end
end

false_pos_rel_paths = cellfun(@(f) strrep(f, '.det', false_posative_ext), dets_rel_path, 'UniformOutput', false);
fp_stats = [];
for idx=1:length(false_pos_rel_paths)
    fp_rel_path = false_pos_rel_paths{idx};
    abs_path = fullfile(detections_base, fp_rel_path);
    loaded_tonals = dtTonalsLoad(abs_path, 0);
    for idx = 0:(loaded_tonals.size() - 1)
        tonal = loaded_tonals.get(idx);
        stats = stat_func(tonal);
        fp_stats = [fp_stats stats];
    end
end