figure;
allEncDensities = [];

for spIdx = 1:size(fields(encStruct),1) 
    numEnc = size(encStruct.(develfiles(spIdx).species),1);
    subplot(2,7,spIdx+7);
    hold on;
    for encIdx = 1: numEnc
        
        fileName = develfiles(spIdx).files(encIdx);
        fp = regexp(fileName, '(?<project>\D+)_(?<site>\D+)_(?<startTime>[^_]+)_(?<endTime>[^_]+)','names');


        encProj  = fp{:}.project;
        encSite  = fp{:}.site;
        encStart = dbISO8601toSerialDate(fp{:}.startTime);
        encEnd   = dbISO8601toSerialDate(fp{:}.endTime);

        encWdensity = getEncWhistleDensity(wDensityStruct, encProj, ...
            encSite, encStart, encEnd);
        allEncDensities = [allEncDensities encWdensity];
        
        MIN_WHISTLE_DENSITY = 10;
        
        encDensities.(develfiles(spIdx).species){encIdx} = ...
            size(find(encWdensity>MIN_WHISTLE_DENSITY),2)/ ...
            size(encWdensity,2);
        
        plot(size(encWdensity,2),...
            encDensities.(develfiles(spIdx).species){encIdx},'+');
    end
    hold off;
    subplot(2,7,spIdx);
    boxplot([encDensities.(develfiles(spIdx).species){:}]);
    title(develfiles(spIdx).species);
end