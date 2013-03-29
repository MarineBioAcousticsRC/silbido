function stats = dtAnalyzeResults(results)

falsePos = 0;
snr.detectionsN = 0;
snr = initStats();
all = initStats();
% fprintf('GT_N  Prec\tRecall\tmuDev\tsDev\tCover\tFrag\n');
fprintf('GT_N  DT_N  Prec\tRecall\tmuDev\tsDev\tCover\tFrag\n');
for idx=1:length(results)
    % track false positives
    fileFalsePos = results(idx).falsePosN;
    falsePos = falsePos + fileFalsePos;
    % compute per file stats
    [snr, fileSNR] = perfile(fileFalsePos, snr, results(idx).snr);
    [all, fileAll] = perfile(fileFalsePos, all, results(idx).all);
    %{
    %        Ngt  Prec   Rec    uDev sDev Cov   Frag   File
    fprintf('%4d  %3.1f\t%3.1f\t%4d\t%4d\t%.2f\t%.1f   %s\n', ...
        results(idx).snr.gt_matchN + results(idx).snr.gt_missN, ...
        fileSNR.precision*100, fileSNR.recall*100, ...
        round(fileSNR.dev_mean), round(sqrt(fileSNR.dev_var)), ...
        fileSNR.coverage*100, fileSNR.fragmentation, ...
        results(idx).file);
    %}
    %        Ngt  Ndt    Prec   Rec    uDev sDev Cov   Frag   File
    fprintf('%4d  %4d  %3.1f\t%3.1f\t%4d\t%4d\t%.2f\t%.1f   %s\n', ...
        results(idx).snr.gt_matchN + results(idx).snr.gt_missN, ...
        results(idx).snr.detectionsN + fileFalsePos, ...
        fileSNR.precision*100, fileSNR.recall*100, ...
        round(fileSNR.dev_mean), round(sqrt(fileSNR.dev_var)), ...
        fileSNR.coverage*100, fileSNR.fragmentation, ...
        results(idx).file);
    
    stats.snr(idx) = fileSNR;
    stats.all(idx) = fileAll;
end

stats.falsePos = falsePos;
stats.cumsnr = overall(falsePos, snr);
stats.cumall = overall(falsePos, all);
%{
fprintf('%4d  %3.1f\t%3.1f\t%4d\t%4d\t%.2f\t%.1f   %s\n', ...
        snr.gt_matchN + snr.gt_missN, ...
        stats.cumsnr.precision * 100, stats.cumsnr.recall*100, ...
        round(stats.cumsnr.dev_mean), round(sqrt(stats.cumsnr.dev_var)), ...
        stats.cumsnr.coverage*100, stats.cumsnr.fragmentation, ...
        'Overall');
%}
fprintf('%4d  %4d  %3.1f\t%3.1f\t%4d\t%4d\t%.2f\t%.1f   %s\n', ...
        snr.gt_matchN + snr.gt_missN, ...
        snr.detectionsN + falsePos, ...
        stats.cumsnr.precision * 100, stats.cumsnr.recall*100, ...
        round(stats.cumsnr.dev_mean), round(sqrt(stats.cumsnr.dev_var)), ...
        stats.cumsnr.coverage*100, stats.cumsnr.fragmentation, ...
        'Overall');
    
function cumStats = initStats()
cumStats.detectionsN = 0;
cumStats.gt_matchN = 0;
cumStats.gt_missN = 0;
cumStats.deviations = [];
cumStats.covered_s = [];
cumStats.excess_s = [];
cumStats.length_s = [];


function [cumStats, fStats] = perfile(falsePos, cumStats, results)

% file precision & recall
fStats.precision = results.detectionsN / (results.detectionsN + falsePos);
fStats.recall = results.gt_matchN / (results.gt_matchN + results.gt_missN);
% deviations
fStats.dev_mean = mean(results.deviations);
fStats.dev_var = var(results.deviations);
% coverage
fStats.coverage = sum(results.covered_s) / sum(results.length_s); 
% excess
fStats.excess_mean = mean(results.excess_s);
fStats.excess_var = var(results.excess_s);
% fragmentations
fStats.fragmentation = results.detectionsN / results.gt_matchN;

% Number of good detections
cumStats.detectionsN = cumStats.detectionsN + results.detectionsN;
cumStats.gt_matchN = cumStats.gt_matchN + results.gt_matchN;
cumStats.gt_missN = cumStats.gt_missN + results.gt_missN;
cumStats.deviations = [cumStats.deviations results.deviations];
cumStats.covered_s = [cumStats.covered_s results.covered_s];
cumStats.length_s = [cumStats.length_s results.length_s];
cumStats.excess_s = [cumStats.excess_s results.excess_s];


function stats = overall(falsePos, stats)
% overall statistics
stats.precision = stats.detectionsN / (stats.detectionsN + falsePos);
stats.recall = stats.gt_matchN / (stats.gt_matchN + stats.gt_missN);
stats.dev_mean = mean(stats.deviations);
stats.dev_var = var(stats.deviations);
stats.fragmentation = stats.detectionsN / stats.gt_matchN;
stats.coverage = sum(stats.covered_s)/sum(stats.length_s);

