function kml = kml_xwavloc(hdr)
% Given an xwav header, generate a KML location.


datefmt = 'yyyy-mm-ddTHH:MM:SSZ';     % Google's date format

LatLongScale = 1/1e5;
Latitude = hdr.xhd.Longitude * LatLongScale;
Longitude =  hdr.xhd.Latitude * LatLongScale;
Depth = - hdr.xhd.Depth;
kml = ge_point(Latitude, Longitude, Depth, ...
    'pointDataCell', {'Lat', sprintf('%f', Latitude);
    'Long', sprintf('%f', Longitude);
    'Depth', sprintf('%f', -Depth)}, ...
    'timeSpanStart', datestr(hdr.start.dnum+dateoffset, datefmt), ...
    'timeSpanStop', datestr(hdr.end.dnum+dateoffset, datefmt), ...
    'altitudeMode', 'relativeToGround', ...
    'name', hdr.xhd.SiteName, ...
    'description', sprintf('%s:%s', hdr.xhd.ExperimentName, ...
       hdr.xhd.SiteName));




