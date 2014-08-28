function blocks = dtDefaultBlockBoundaries(...
    file_len_s, block_len_s, block_pad_s, ...
    Advance_s, shift_samples_s)
    
    StartBlock_s = 0;
    StopBlock_s = 0;
    blocks = zeros(0,2);
    
    %frames_per_s = Fs/advance_samples;
    
    while(StopBlock_s < (file_len_s - Advance_s - shift_samples_s))
        StopBlock_s = min(StartBlock_s + block_len_s + 2 * block_pad_s, file_len_s - block_pad_s);
        %fprintf('Processing raw block from %.10f to %.10f\n', StartBlock_s, StopBlock_s);
        blocks = vertcat(blocks, [StartBlock_s, StopBlock_s]);
        %len = StopBlock_s - StartBlock_s;
        %block_samples = len * Fs;
        %Indices = spFrameIndices(...
        %    block_samples-shift_samples_s, length_samples, advance_samples, length_samples, ...
        %    frames_per_s, shift_samples_s);
        
        %StartBlock_s = Indices.timeidx(end) + Advance_s - shift_samples_s;
        %StartBlock_s = StopBlock_s - shift_samples_s;
        StartBlock_s = StartBlock_s + block_len_s - shift_samples_s;
    end
end

