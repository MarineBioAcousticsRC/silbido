function onnx2dag(model)
% onnx2dag(model)
% Given the path to an open neural network exchange format model
% (ONNX, https://onnx.ai), convert it to a Matlab directed acyclic
% graph.  
%
% The model is stored in the same directory as the ONNX file with
% the extension .mat

[dir, name, ext] = fileparts(model);

network = importONNXNetwork(model, 'OutputLayerType', 'regression');

newname = fullfile(dir, [name, '.mat']);
save(newname, 'network');




