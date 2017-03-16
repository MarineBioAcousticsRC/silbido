% use the develfiles struct to find the start and end times of found
% click encounters. Then calls on getEncWhistleDensity to check if 

encStruct = struct;

numSpecies = size(develfiles,2);
for spIdx = 1:numSpecies
    numEncs = size(develfiles(spIdx).clickTimes,2);
    encStruct.(develfiles(spIdx).species) = cell(numEncs,1);
    for encIdx = 1:numEncs
        fileName = develfiles(spIdx).files(encIdx);
        fp = regexp(fileName, '(?<project>\D+)_(?<site>\D+)_(?<startTime>[^_]+)_(?<endTime>[^_]+)','names');
        
        
%         clickTimes = develfiles(spIdx).clickTimes(encIdx);
%         clickTimes = clickTimes{:};
        encProj  = fp{:}.project;
        encSite  = fp{:}.site;
        encStart = dbISO8601toSerialDate(fp{:}.startTime);
        encEnd   = dbISO8601toSerialDate(fp{:}.endTime);
        
        
        encWdensity = getEncWhistleDensity(wDensityStruct, encProj, ...
            encSite, encStart, encEnd);
        MIN_WHISTLE_DENSITY = 10;
        MIN_WHISTLE_COUNTS  = 10;
        %MIN_ENC_WHISTLE_DENSITY = .01;
%         
%         encStruct.(develfiles(spIdx).species){encIdx} = 0;
%         if (size(find(encWdensity>MIN_WHISTLE_DENSITY),2)/ ...
%                 size(encWdensity,2) > MIN_ENC_WHISTLE_DENSITY)
%             encStruct.(develfiles(spIdx).species){encIdx} = 1;
%         end
%         
        % Save the click encounter as one with whistles if there is at
        % least one second with the MIN_WHISTLE_DENSITY
        % currently set to 10 whistles per second
        encStruct.(develfiles(spIdx).species){encIdx} = ...
            logical(sum(size(find(encWdensity>MIN_WHISTLE_DENSITY)),2)>...
                                          MIN_WHISTLE_COUNTS);

        
%          encStruct.(develfiles(spIdx).species){encIdx} = encWdensity;
    end

end
% 
% encDensities = struct;
% for spIdx = 1:size(fields(encStruct),1)
%     
%     numEnc = size(encStruct.(develfiles(spIdx).species),1);
%     for encIdx = 1: numEnc
%         MIN_WHISTLE_DENSITY = 10;
%         MIN_ENC_WHISTLE_DENSITY = .01;
%         
%         
%         encDensities.(develfiles(spIdx).species){encIdx} = ...
%             size(find(encWdensity>MIN_WHISTLE_DENSITY),2)/ ...
%             size(encWdensity,2) > MIN_ENC_WHISTLE_DENSITY;
%         
%     end
% end

% for each encounter determine if there are whistles by looking at the
% whistle density values within the encounter times