function blocks = dtBlockBoundaries(noiseBoundaries, ...
    file_end_s, block_len_s, block_pad_s, ...
    Advance_s, shift_samples_s)
    if (isempty(noiseBoundaries))
        blocks = dtDefaultBlockBoundaries(...
            file_end_s, block_len_s, block_pad_s, ...
            Advance_s, shift_samples_s);
    else
        % note we add the end of the file as the last boundary.
        blocks = dtBlockBoundariesFromNoiseBoundaries(...
            [noiseBoundaries, file_end_s], block_len_s, 6, 0.5);
    end
end