function trkCSA_ParameterVerify(WinSamp, DeltaSamp)
% trkCSA_ParameterVerify(WinSamp, DeltaSamp)
% Verify that all parameters are multiples of the high resolution
% sampling.  This is needed for Cettolo's cumulative sum approach

base = DeltaSamp.High;

Failure = 0;

if mod(DeltaSamp.Low, base)
  error('DeltaSamp.High must be a multiple of DeltaSamp.High');
end

Fields = fieldnames(WinSamp);
for f = 1:length(Fields)
  if mod(WinSamp.(Fields{f}), base)
    error('WinSamp.%s must be a multiple of DeltaSamp.High', ...
          Fields{f});
  end
end
