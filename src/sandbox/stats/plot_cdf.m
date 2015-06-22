function plot_cdf(correct, falsepos)
% thejerk(correct, falsepos)
% Assume column vectors

Nc = length(correct);
Nfp = length(falsepos);
N = max(Nc, Nfp);

both = zeros(N, 2)*NaN;  % for histogram
both(1:Nc,1) = correct;
both(1:Nfp,2) = falsepos;

[Fc, values_c] = stEmpiricalCDF(correct);
[Ffp, values_fp] = stEmpiricalCDF(falsepos);

figure('Name', 'Cumulative Distribution Function');
plot(values_c, Fc, 'b', values_fp, Ffp, 'r');
xlabel('stat')
ylabel('Cumulative Probability)')
legend('Good', 'False Pos');

figure('Name', 'Histogram')
hist(both, 100);
