function String = utToHHMMSS(Seconds)
% Convert seconds to HH:MM:SS

Hours = floor(Seconds / 3600);
Rest = Seconds - Hours * 3600;

Minutes = floor(Rest / 60);
Rest = Rest - Minutes * 60;

Seconds = floor(Rest);
Fraction = Rest - Seconds;

String = sprintf('%02d:%02d:%02d', Hours, Minutes, Seconds);
if Fraction
  Temp = sprintf('%.2f', Fraction);
  Temp(1) = [];		% remove leading zero
  String = [String, Temp];
end
