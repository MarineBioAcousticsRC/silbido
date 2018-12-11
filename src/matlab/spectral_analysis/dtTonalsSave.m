function dtTonalsSave(Filename, tonals, varargin)
% dtTonalsSave(Filename, tonals, OptionalArgs)
% Save the list of tonals to the specified file.  The recommended 
% filename extension is '.ann' for annotation file format.  When
% Filename is set to [], a dialog will request a filename.
%
% The tonals is a linked list of tonals.  See the documentation for 
% details on how to create these.
%
% OptionalArgs:
%   'Comment', string - Comment to be stored with file
%   'Dialog', true|false - Display a dialog that prompts for a filename.
%      Defaults to false unless Filename is empty.
%   'Save', Mask - Specify parameters to be saved with each point.
%      Mask is a bitwise or (bitor) of any of the TonalHeader fields:
%       per time-freq node measurements: 
%           TIME, FREQ, SNR, PHASE
%       per tonal measurements
%           CONFIDENCE, SCORE, SPECIES, CALL
%      If not specified, time and frequency only will be saved.  
%      Note that for each of these, the values must have been set in the
%      tonals for the fields to be meaningful.
%      If a vector is passed in, it is assumed that this is a list of 
%      tonal header fields and they are bitwise or'd for the caller.
%    'Version', N - A version number associated with the caller's detector.
%         It is saved as a short integer, for more sophisticated version
%         schemes, it is suggested that the comment field be used.
%
% Example:
%  % Invoke code that generates a set of tonals and corresponding scores
%  tonals = YourDetectionCode('somefile.wav');
%  % properties of tonals can be set as follows if the detector does not
%  % do this:
%  tonals.get(tonal_idx).setScore(some_score);
%  tonals.get(tonal_idx).setConfidence(some_confidence)
%  as well as .setSpecies() and .setCall() to set the species id and call
%     type.
%
%  % score times, frequencies, and scores
%  dtTonalSave('somefile.ann', tonals, 'Save', ...
%        bitor(TonalHeader.TIME, ...
%              bitor(TonalHeader.FREQ, TonalHeader.SCORE)));
%
%  % similar to above, but save the snr 
%  dtTonalSave('somefile.ann', tonals, ...
%     'Save', bitor(TonalHeader.TIME, 
%                   bitor(TonalHeader.FREQ, TonalHeader.SNR)));


import tonals.*;

error(nargchk(2,Inf,nargin));

% Set up defaults
savemask = TonalHeader.DEFAULT;  % time x freq only
gui = isempty(Filename);  % graphical prompt?
scores = [];  % scores associated with each annotation
confidences = [];  % confidence associated with each annotation
comment = '';  % comment associated with set of annotations
version = 0;  % not specified

% Parse the optional arguments, possibly overriding defaults
vidx = 1;
while vidx < length(varargin)
    switch varargin{vidx}
        case 'Comment'
            comment = varargin{vidx+1}; vidx = vidx+2;
        case 'Save'
            masks = varargin{vidx+1}; vidx = vidx+2;
            if length(masks) > 0
                savemask = uint16(0);
                for midx = 1:length(masks)
                    savemask = bitor(savemask, masks(midx), 'uint16');
                end
            else
                savemask = uint16(masks);
            end

        case 'Dialog'
            gui = varargin{vidx+1}; vidx = vidx+2;
        case 'Version'
            version = varragin{vidx+1};
            if ~isnumeric(version)
                error('integer required for version');
            end
        otherwise
            error('Bad optional argument');
    end
end

if ~isempty(scores)
    savemask = bitor(savemask, TonalHeader.SCORE);
end
if ~isempty(confidences)
    savemask = bitor(savemask, TonalHeader.CONFIDENCE);
end

% Handle graphical prompt if needed
pattern = {'*.ann', 'annotation'};
if gui
    [SaveFile, SaveDir] = uiputfile(pattern, 'Save Tonal Annotations', Filename);
    if isnumeric(SaveFile)
        return  % cancel
    end
    Filename = fullfile(SaveDir, SaveFile);
end

% open up file
tstream = TonalBinaryOutputStream(Filename, version, comment, savemask);

% Examine scores and confidences to determine what function to use
% 0 - no scores or confidences
% 1 - scores
% 2 - confidences
% 3 - scores and confidences
writeCode = bitor(bitshift(double(~isempty(confidences)), 1), double(~isempty(scores)));

% iterate through tonals
it = tonals.iterator();
count = 0;
while it.hasNext()
    count = count + 1;
    t = it.next();
    % write each tonal t
    tstream.write_tonal(t);
end
tstream.close();
