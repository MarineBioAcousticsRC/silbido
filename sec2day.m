function [days_from_secs] = sec2day(seconds2convert)
%60 seconds/ min * 60mins/ hour * 24 hours/ day
    days_from_secs = seconds2convert/(60*60*24);
end