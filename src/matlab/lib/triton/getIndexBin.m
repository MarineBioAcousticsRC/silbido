function [rawIndex,tBin] = getIndexBin(cx)
% [rawIndex,tBin] = getIndexBin(cx)
%
% Given the time cx in user units (time [hr]), return the index
% into the appropriate raw file (rawIndex) and the time index into that
% raw file (tBin)
%
% 060515 smw
% called by coordisp
% 
% note: cx is in user units (time [hr])
%
%
% Do not modify the following line, maintained by CVS
% $Id: getIndexBin.m,v 1.2 2007/09/15 17:07:11 mroch Exp $

global PARAMS


% 

% cx = cx - 0.5 * PARAMS.ltsa.tave / (60 * 60);

% size of time bins in [hr]
tbinsz = PARAMS.ltsa.tave / (60*60);
% time vector time bin of cursor pick
% need to move time vector over 1/2 bin because of 'image plot'
tvector = PARAMS.ltsa.t +  0.5* tbinsz;
% find which time bin the cursor(cx) is in
cursorBin = find( (tvector - cx) <= tbinsz & ...
    (tvector - cx) >= 0);
% take only one, just in case more than one were found...
cursorBin = cursorBin(1);

%  disp_msg(['cx=',num2str(cx),'  cursorBin=',num2str(cursorBin)])
% number of bins before next raw file
deltaBin = PARAMS.ltsa.nave(PARAMS.ltsa.plotStartRawIndex) - PARAMS.ltsa.plotStartBin + 1;
% index of raw file that starts plot
rawIndex = PARAMS.ltsa.plotStartRawIndex;
% find time bin and raw file of cursor
if deltaBin >= cursorBin
     tBin = cursorBin + PARAMS.ltsa.plotStartBin - 1;
else
    tBin = cursorBin - deltaBin;
    rawIndex = rawIndex + 1;
    % find which raw file cursorBin is in
    while tBin > PARAMS.ltsa.nave(rawIndex)
        tBin = tBin - PARAMS.ltsa.nave(rawIndex);
        rawIndex = rawIndex + 1;
        if rawIndex > PARAMS.ltsa.nrftot
            rawIndex = PARAMS.ltsa.nrftot;
            tBin = PARAMS.ltsa.nave(rawIndex);
            break
        end
    end
end
