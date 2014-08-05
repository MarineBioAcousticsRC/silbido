function blocks = dtBlocksForSegment(blockBoundaries, start_s, end_s)

if (length(blockBoundaries) < 2)
    err = MException('ResultChk:OutOfRange', ...
        'The blockBoundaries array must have two or more elements.');
    throw(err);
end

if (start_s < blockBoundaries(1,1))
    err = MException('ResultChk:OutOfRange', ...
        'start_s must be >= to the first block boundary');
    throw(err);
end
    
if (end_s > blockBoundaries(end,2))
    err = MException('ResultChk:OutOfRange', ...
        'end_s must be <= to the last block boundary');
    throw(err);
end

blockEnds = blockBoundaries(:,2);

start_idx = find(blockEnds > start_s, 1);
end_idx = find(blockEnds > end_s, 1);
if (isempty(end_idx))
    end_idx = length(blockEnds);
end


blocks = blockBoundaries(start_idx:end_idx,:);
