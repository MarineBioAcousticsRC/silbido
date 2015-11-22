function blocks = dtBlockBoundariesFromNoiseBoundaries(...
    noiseBoundaries, defaultBlockLen, maxBlockLen, minBlockLen)


lastStart = 0;
blocks = zeros(0,2);

index = 1;
while (index <= length(noiseBoundaries))
    currentBoudnary = noiseBoundaries(index);
    blockLen = currentBoudnary - lastStart;
    if (blockLen > maxBlockLen)
        currentBoudnary = lastStart + defaultBlockLen;
        noiseBoundaries = [noiseBoundaries(1:(index - 1)) currentBoudnary noiseBoundaries(index:end)];
        index = index + 1;
        blocks = vertcat(blocks, [lastStart, currentBoudnary]);
        lastStart = currentBoudnary;
    elseif (blockLen < minBlockLen && index < length(noiseBoundaries) - 1)
        noiseBoundaries = [noiseBoundaries(1:index - 1) noiseBoundaries((index + 1):end)];
    else
        index = index + 1;
        blocks = vertcat(blocks, [lastStart, currentBoudnary]);
        lastStart = currentBoudnary;
    end
    
end