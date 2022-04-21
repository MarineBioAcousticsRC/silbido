function species_calls = dtGetLabelOptions(species_file)

if nargin < 1
    % Assume species_calls.json is in this file's directory
    lib_dir = fileparts(which(mfilename));
    species_file = fullfile(lib_dir, 'species_calls.json');
end

% Read in JSON file with species and call names that will be available for
% labeling.
file_h = fopen(species_file, 'r');
text = fread(file_h);
data = jsondecode(char(text'));

species_calls = containers.Map();
for idx=1:length(data.species_calls)
    % Create a structure with the list of calls and a value showing
    % the last selected call.  This lets clients of the map remember
    % which call was selected between species
    value = struct('calls', {data.species_calls(idx).calls}, ...
        'selected', 1);
    species_calls(data.species_calls(idx).species) = value;
end





