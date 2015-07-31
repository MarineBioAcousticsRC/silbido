function blocks = blockBoundaries(...
    noiseBoundaries, idealBlockLen, maxBlockLen, minBlockLen)

% records the start of the current block.
currentBlockStart = 0;
blocks = zeros(0,2);

index = 1;
while (index <= length(noiseBoundaries))
    % Determine the current boundary.
    nextNoiseBoundary = noiseBoundaries(index);
    
    % Compute how long the block would be if it went from the current
    % start until the next noise boundary.
    blockLen = nextNoiseBoundary - currentBlockStart;
    if (blockLen > maxBlockLen)
        % If the block would be larger than the maximum allowed
        % we indroduce a new artificial boundary.
        nextNoiseBoundary = currentBlockStart + idealBlockLen;
        blocks = vertcat(blocks, [currentBlockStart, nextNoiseBoundary]);
        currentBlockStart = nextNoiseBoundary;
    elseif (blockLen < minBlockLen && index < length(noiseBoundaries) - 1)
        % if the noise boundary would create a block that is to short to
        % processes, we simply remove the boundary and bring the last block
        % up to end at this boundary.  We know that the block after the
        % next boundary is a new noise regime, the but the block behind
        % could be part of the same regime if the current block was created
        % as a result of splitting a larger block into smaller ones.
        % Therefore the safer bet is to merge backwards.
        noiseBoundaries = [noiseBoundaries(1:index - 1) noiseBoundaries((index + 1):end)];
        blocks(end,2) = nextNoiseBoundary;
    else
        % The block is within the min and max sizes, we take it as is.
        blocks = vertcat(blocks, [currentBlockStart, nextNoiseBoundary]);
        currentBlockStart = nextNoiseBoundary;
        index = index + 1;
    end
end