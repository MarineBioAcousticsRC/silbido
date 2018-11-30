function [tonalList, metaData, Filename] = dtTonalsLoad(Filename, varargin)
% [tonalList, metaData, Filename] = dtTonalsLoad(Filename, OptionalArgs)
% Load a set of tonals from Filename.  If Filename is [], a dialog
% prompts the user for the filename.
%
% Returns a linked list of tonals and metadata about the tonals.
%
% The metaData structure contains the following fields:
%   hdr - Information about the file hdr.
%   scores - Scores associated with the tonals (empty if not in file)
%   confidences - Confidence scores associated with the tonals 
%      (empty if not in file)
% The returned Filename is only useful if the user was prompted for
%   a filename.
%
% Optional arguments:
%   'Dialog', true|false - Prompt for a filename.  Defaults to false
%       unless Filename is empty
%
% Example:
% [detections, info] = dtTonalsLoad('SomeDetectorOutputFile.ann', 'Dialog', true);
% or 
% [detections, info, fname] = dtTonalsLoad([]);

import tonals.*

metaData = [];
gui = isempty(Filename);

error(nargchk(1,Inf,nargin));
vidx = 1;
while vidx < length(varargin)
    switch varargin{vidx}
        case 'Dialog'
            gui = varargin{vidx+1}; vidx = vidx+2;
        otherwise
            error('Bad optional argument');
    end
end

if gui
    [LoadFile, LoadDir] = uigetfile(...
        {'*.ann;*.bin', 'Annotation File'
         '*.det', 'Detections'
         '*.d-', 'False Detections'
         '*_s.gt+;*_s.gt-;*_s.d+', 'Above SNR ground truth and valid detections'
         '*_a.gt+;*_a.gt-;*_a.d+', 'All ground truth and valid detections'
         '*', 'All files',
         '*.ton', 'legacy tonal format'},...
        'Load Tonals', Filename);
    
    % check for cancel
    if isnumeric(LoadFile)
        Filename = [];
        tonalList = [];
        return
    else
        Filename = fullfile(LoadDir, LoadFile);
    end
end

[path name ext] = fileparts(Filename);
if ~strcmp(ext, '.ton')
    % loads binary file
    tonalBIS = TonalBinaryInputStream(Filename);    % retrieve linked list
    tonalList = tonalBIS.getTonals(); 
    hdr = tonalBIS.getHeader();
    metaData.hdr = hdr;
    metaData.comment = char(hdr.getComment());
    metaData.version = char(hdr.getUserVersion());
else if strcmp(ext, '.ton')
        % loads objects
        tonalList = tonals.tonal.tonalsLoad(Filename);
    end
end
