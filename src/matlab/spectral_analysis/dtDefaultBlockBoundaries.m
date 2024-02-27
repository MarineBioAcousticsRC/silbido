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


% This was changed by someone to not use the more efficient 
% spFrameIndices, but causes a large slowdown due to increasing
% the array size all the time.  We'll keep the logic for now, but
% go through the loop twice so that we can preallocate the array


StopBlock_s = 0;
frames = 0;
while(StopBlock_s < (file_len_s - Advance_s - shift_samples_s))
    StopBlock_s = min(StartBlock_s + block_len_s + 2 * block_pad_s, file_len_s);
    StartBlock_s = StartBlock_s + block_len_s - shift_samples_s;
    frames = frames + 1;
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


