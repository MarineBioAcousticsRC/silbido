function R2=ConvertPixelsToSpectralCoords(R,T,F)
% ConvertPixelsToSpectralCoords
%
% Takes a cell array of curves specified in pixel coordinates, and converts
% them to real-valued time-frequency coordinates.
%
% Input:
%   R - Cell array of pixel-based curves
%   T - Vector of time values for pixels (columns) in the spectrogram
%   F - Vector of frequency values for pixels (rows) in the spectrogram
%
% Output:
%   R2 - Converted cell array of curves in spectral coordinates
%

R2=[];

for n=1:length(R)
    t=R{n};
    
    f=find(t(:,1)<1 | t(:,1)>length(T));
    t(f,:)=[];
    
    x=linterp(1:length(T),T,t(:,1));
    y=linterp(1:length(F),F,t(:,2));
    R2{n}=[x' y'];
end

