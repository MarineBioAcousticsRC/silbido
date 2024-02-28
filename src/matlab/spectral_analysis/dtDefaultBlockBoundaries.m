function blocks = dtDefaultBlockBoundaries(...
    file_len_s, block_len_s, block_pad_s, ...
    Advance_s, shift_samples_s)
% dtDefaultBlockBoundaries
% Given the following parameters, return a vector of start and stop times
% in seconds.
% Parameters
% file_len_s - file duration in seconds
% block_len_s - duration of each block
% block_pad_s - If non zero, each block will be padded by this many
%   seconds on either side, resulting in overlapping blocks.  Padding
% Advance_s - Amount of time to advance between blocks.
% shift_samples_s - If non-zero, time shifts the signal by the indicated
%  duration s.

    
    StartBlock_s = 0;
    StopBlock_s = 0;
    blocks = zeros(0,2);
    
    %frames_per_s = Fs/advance_samples;
    first = true;
    while(StopBlock_s < (file_len_s - Advance_s - shift_samples_s))
        if (first)
            StopBlock_s = min(StartBlock_s + block_len_s + block_pad_s, file_len_s);
            first = false;
        else
            StopBlock_s = min(StartBlock_s + block_len_s + 2 * block_pad_s, file_len_s);
        end

        
        %fprintf('Processing raw block from %.10f to %.10f\n', StartBlock_s, StopBlock_s);
        blocks = vertcat(blocks, [StartBlock_s, StopBlock_s]);
        %len = StopBlock_s - StartBlock_s;
        %block_samples = len * Fs;
        %Indices = spFrameIndices(...
        %    block_samples-shift_samples_s, length_samples, advance_samples, length_samples, ...
        %    frames_per_s, shift_samples_s);
        
        %StartBlock_s = Indices.timeidx(end) + Advance_s - shift_samples_s;
        %StartBlock_s = StopBlock_s - shift_samples_s;
        StartBlock_s = max(StopBlock_s - shift_samples_s - 2 * block_pad_s, 0);
    end
end


StartBlock_s = 0;
StopBlock_s = 0;
blocks = zeros(frames, 2);
frame_idx = 1;
while frame_idx <= frames
    StopBlock_s = min(StartBlock_s + block_len_s + 2 * block_pad_s, file_len_s);
    blocks(frame_idx, :) = [StartBlock_s, StopBlock_s];
    % prime for next
    StartBlock_s = StartBlock_s + block_len_s - shift_samples_s;
    frame_idx = frame_idx + 1;
end

1;


