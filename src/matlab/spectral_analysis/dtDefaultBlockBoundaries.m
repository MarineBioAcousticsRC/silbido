function blocks = dtDefaultBlockBoundaries(...
    file_len_s, block_len_s, block_pad_s, ...
    Advance_s, shift_samples_s)
% dtDefaultBlockBoundaries
% Given the following parameters, return a vector of start and stop times
% in seconds.
%
% Parameters
% file_len_s - file duration in seconds
% block_len_s - duration of each block
% block_pad_s - If non zero, each block will be padded by this many
%     seconds on either side, resulting in overlapping blocks.
% Advance_s - Amount of time to advance between blocks.
% shift_samples_s - If non-zero, time shifts the signal by the indicated
%    duration s.

% Two pass design to prevent costly array growth
StartBlock_s = 0;
StopBlock_s = 0;
first = true;
blocksN = 0;
while StopBlock_s < (file_len_s - Advance_s - shift_samples_s)
    blocksN = blocksN + 1;
    
    if first
        % First block is padded on right side only
        StopBlock_s = min(StartBlock_s + block_len_s + block_pad_s, file_len_s);
        first = false;
    else
        StopBlock_s = min(StartBlock_s + block_len_s + 2 * block_pad_s, file_len_s);
    end
    % next start
    StartBlock_s = max(StopBlock_s - shift_samples_s - 2 * block_pad_s, 0);
end

StartBlock_s = 0;
StopBlock_s = 0;
first = true;
blocks = zeros(blocksN, 2);  % preallocate array
for block_idx = 1:blocksN
    if first
        % First block is padded on right side only
        StopBlock_s = min(StartBlock_s + block_len_s + block_pad_s, file_len_s);
        first = false;
    else
        StopBlock_s = min(StartBlock_s + block_len_s + 2 * block_pad_s, file_len_s);
    end
    blocks(block_idx, :) = [StartBlock_s, StopBlock_s];  % store result
    % next start
    StartBlock_s = max(StopBlock_s - shift_samples_s - 2 * block_pad_s, 0);
    
end


