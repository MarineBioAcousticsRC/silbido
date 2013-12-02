function R2=ConvertSpectralCoordsToPixels(R,T,F)
% ConvertPixelsToSpectralCoords
%
% Takes a cell array of curves specified in spectral coordinates, and 
% converts them to image (pixel) coordinates.
%
% Input:
%   R - Cell array of spectral-based curves
%   T - Vector of time values for pixels (columns) in the spectrogram
%   F - Vector of frequency values for pixels (rows) in the spectrogram
%
% Output:
%   R2 - Converted cell array of curves in pixel coordinates
%

R2=[];

for n=1:length(R)
    t=R{n};
    
    x=linterp(T,1:length(T),t(:,1));
    y=linterp(F,1:length(F),t(:,2));
    R2{n}=[x' y'];
end

