function parsestirng()

% this function parse a text file and

rw = fopen('/zal/cheng/matlab/audio/tracking/automation/helper/spkrnumlist.txt', 'w');

[col1, col2] = textread('/zal/cheng/matlab/audio/tracking/automation/helper/spkrlist2.txt',...
                            '%n%5n%*[^\n]','delimiter','{', 'emptyvalue',NaN);
sd = unique(col2);                       
for i = 1:length(sd)
    fprintf(rw, '%s \n',num2str(sd(i)));
end
 