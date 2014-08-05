function String = trkReportStat(Numerator, Denominator, Complement)
% ResultString = Stat(Numerator, Denominator, Complement)
% Format string (N/D) = N/D

if nargin < 3
  Complement = 0;
end
if Denominator == 0
  String = sprintf('N/A\t\t');
else
  if Complement
    % Use 1 - percentage instead of percentage
    Numerator = Denominator - Numerator;
  end

  Percent = Numerator / Denominator * 100;

  % format with leading spaces such that whole number portion
  % always takes three digits
  if Percent < 100
    if Percent < 10
      LeadSpaces = '  ';
    else
      LeadSpaces = ' ';
    end
  else
    LeadSpaces = '';
  end

  String = sprintf('(%3d/%3d)=%s%.2f%%', Numerator, Denominator, ...
                   LeadSpaces, Percent);
end
