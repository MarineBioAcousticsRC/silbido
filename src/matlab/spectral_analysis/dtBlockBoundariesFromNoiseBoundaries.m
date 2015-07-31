function blocks = dtBlockBoundariesFromNoiseBoundaries(...
    noiseBoundaries, defaultBlockLen, maxBlockLen, minBlockLen)

% records the start of the current block.
lastStart = 0;
blocks = zeros(0,2);

index = 1;
while (index <= length(noiseBoundaries))
    % Determine the current boundary.
    currentBoudnary = noiseBoundaries(index);
    
    % Compute how long the block would be if it went from the current
    % start until the next noise boundary.
    blockLen = currentBoudnary - lastStart;
    if (blockLen > maxBlockLen)
        % If the block would be larger than the maximum allowed
        % we indroduce a new artificial boundary.
        currentBoudnary = lastStart + defaultBlockLen;
        noiseBoundaries = [noiseBoundaries(1:(index - 1)) currentBoudnary noiseBoundaries(index:end)];
        index = index + 1;
        blocks = vertcat(blocks, [lastStart, currentBoudnary]);
        lastStart = currentBoudnary;
    elseif (blockLen < minBlockLen && index < length(noiseBoundaries) - 1)
        % if the noise boundary would create a block that is to short to
        % processes, we simply remove the boundary.
        noiseBoundaries = [noiseBoundaries(1:index - 1) noiseBoundaries((index + 1):end)];
    else
        % The block is within the min and max sizes, we take it as is.
        index = index + 1;
        blocks = vertcat(blocks, [lastStart, currentBoudnary]);
        lastStart = currentBoudnary;
    end
    
end