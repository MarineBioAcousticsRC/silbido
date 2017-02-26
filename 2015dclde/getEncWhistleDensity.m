function [encWhistleDensityVector] = getEncWhistleDensity(wDensity, ...
                                       projName,siteName,startTime,endTime)

% getEncWhistleDensity
% Description:
% Finds all the associated whistle density (wDensity) counts for a given
% range of time at a particular project and site of DCLDE
% Returns:
% A vector of 

% gets all of the possible whistle density files for a specific project and
% site
projSite = [projName '_' siteName];
siteFiles = fields(wDensity.(projSite));
fileparts = regexp(siteFiles, '_', 'split');
fileStarts = zeros(size(fileparts,1),1);
for fIdx = 1:size(fileparts,1)
    fileStart = [fileparts{fIdx}{3} fileparts{fIdx}{4}];
    fs = regexp(fileStart,['(?<year>\d\d)(?<month>\d\d)(?<day>\d\d)' ...
        '(?<hour>\d\d)(?<min>\d\d)(?<sec>\d\d)'],'names');
    fs2nums = cellfun(@str2num,...
        {fs.year,fs.month,fs.day,fs.hour,fs.min,fs.sec});
    fs2nums(1) = fs2nums(1)+2000;
    fileStarts(fIdx) = datenum(fs2nums);
end

% finds the whistle density files associated specified range of encounter 
filesEnc = intersect(find(startTime < fileStarts) -1, ...
           find(endTime > fileStarts));

% merges whistle density histogram counts into one for files associated in
% given range 
allFileDensities = [];
numFiles = size(filesEnc,1);
for fIdx = 1:numFiles
    allFileDensities = [allFileDensities ...
    wDensity.(projSite).(siteFiles{filesEnc(fIdx)}).wDensity];
end

% calculates the total duration of encounter in seconds
SECONDS_PER_DAY = 60*60*24;
timeDiffDays = endTime-startTime;
timeDiffSecs = timeDiffDays*SECONDS_PER_DAY;

% trims off the beginning and ends of the allFileDensities to keep the bins
% that are associated with the encounter start and end times
fileOffset = (startTime - fileStarts(filesEnc(1)) ) * SECONDS_PER_DAY; 
fileOffset = floor(fileOffset);
encWhistleDensityVector = allFileDensities(fileOffset:fileOffset+timeDiffSecs);

end