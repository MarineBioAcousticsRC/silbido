function Fx = stDiscreteCDF(x, Population)
% Fx = stDiscreteCDF(x, Population)
% Given a value x and a discrete population, evaulate the cumulative
% distribution function for x.

PopulationSize = length(Population);	% how many?
Fx = zeros(length(x), 1);	% preallocate
for idx = 1:length(x)
  Indices = find(Population <= x(idx));
  Fx(idx) = length(Indices) / PopulationSize;
end
