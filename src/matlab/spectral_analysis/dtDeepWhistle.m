function [predicted_blk, Indices] = dtDeepWhistle(handle, header,...
    channel, blkstart_s, blklength_s, Shift, Framing, Range)
%DTPREDICPLOT Given a start time and length in seconds, framing
% information in samples ([Length, Advance]), and any optional
% arguments, read in a data block and perform spectral processing.
%
% Returns a confidence map of detected whistles and framing information.
%

%since blklength is shorter on the last block it does not fit our current
%restrictions of input size

% This function is called repeatedly for every block
% We load the neural network only once
persistent net
if isempty(net)
    % Determine where silbido is installed
    rootdir = fileparts(which('silbido_init'));
    % Determine net path
    netfname = fullfile(rootdir, ...
        'src/matlab/lib/DeepWhistle/DAGnet361x1500.mat');
    net = load(netfname);
end

Length_s = Framing(1)/1000;
advance_s = Framing(2)/1000;
Length_samples = round(header.fs * Length_s)+1;
Advance_samples = round(header.fs * advance_s);
blkend_s = blkstart_s + blklength_s;

%energy normalization
max_clip = 6;
min_clip = 0;

% todo:  these need to be rounded
start_sample = floor(blkstart_s * header.fs)+1;
end_sample = floor(blkend_s * header.fs);

Signal = ioReadWav(handle, header, start_sample, end_sample, ...
    'Channels', channel, 'Normalize', 'unscaled');

%Normalization
if header.samp.byte > 2
    Signal = Signal / 2^(8*(header.samp.byte- 2));
end

frames_per_s = header.fs/Advance_samples;

% Remove Shift samples from the length so that we have enough space to
% create a right shifted frame
Indices = spFrameIndices(length(Signal)-Shift, Length_samples, ...
    Advance_samples, Length_samples, frames_per_s, Shift);
last_frame = Indices.FrameLastComplete + 1;


% Figure out number of linear bins.
binHz = header.fs/Length_samples;
nyquistBin = floor(Length_samples);
highCutoffBin = min(ceil(Range(2)/binHz), nyquistBin);
lowCutoffBin= ceil(Range(1)/binHz);

% Compute dft for current block
audio = zeros(last_frame, Length_samples);

for frameidx = 1:last_frame
    frame = spFrameExtract(Signal,Indices,frameidx);
    audio(frameidx,:) = frame;
end

dftN = size(audio, 2);  % samples in frame & frequencies
fft_spec = abs(fft(audio, dftN,2));

%Entered by Marie
% Nyquist rate is half the sample rate.
% This signal is sampled at 192000, Fs/2 = 192000 / 2
% This translates into half of the frequency bins
NyquistN = ceil((dftN+1) / 2);
fft_spec(: ,NyquistN+1:end) = [];% Removes frequencie above Nyquist


fft_spec = transpose(fft_spec);
fft_spec([1:lowCutoffBin-1,highCutoffBin+1:end],:)=[];

normalized_blk = log10(fft_spec);

%normalize3_PuLi - a normalization function created for our model
normalized_blk(normalized_blk>max_clip)=max_clip;
normalized_blk(normalized_blk<min_clip)=min_clip;
normalized_blk = (normalized_blk - min_clip) / (max_clip - min_clip);

inputsize = net.net1500.Layers(1).InputSize;

blksize = size(normalized_blk);

%If the spectrogram size is different from the inputsize of our model,
%we create a new input layer to match the spectrogram
if ~all(blksize == inputsize(1:2))
    connections = net.net1500.Connections;
    layer = imageInputLayer([blksize,1], 'Name', 'Input_input.1',...
        'Normalization', 'none', 'NormalizationDimension', 'auto');
    layers = net.net1500.Layers;
    layers(1) = layer;
    lgraph = layerGraph(layers);
    %layerGraph does not connect all layers
    %LayerConnect reconnects any missed layers
    net.net1500 = LayerConnect(lgraph,connections);
end



predicted_blk = predict(net.net1500,normalized_blk);

% relative to file rather than block
Indices.timeidx = Indices.timeidx + blkstart_s;
end

function net = LayerConnect(lgraph, connections)
%Connects layers that were missed by layerGraph. Given the original
%connections
%lgraph- the new layer graph
%connections- old connections
n = 1;

%When layerGraph builds, all inputs set to 'in1'.
%To determine where connections are lost we normalize
%all 'Desitination' strings to 'in1'
for i = 1 : size(connections)
    connections{i,2} = cellstr(regexprep(string(...
        connections{i,2}),'in2','in1'));
end
diffconct = setdiff(connections, lgraph.Connections);

for i = 1 : size(diffconct)
    %We change input ports to 'in2' 
    source = string(diffconct{i,1});
    destination = regexprep(string(diffconct{i,2}),'in1', 'in2');
    lgraph = connectLayers(lgraph,string(source),...
        destination);
end
net = assembleNetwork(lgraph);
end

