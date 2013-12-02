function OutStruct = utScaleStruct(InStruct, Scale)
% OutputStruct = utScaleStruct(InputStruct, ScaleFactor)
% Scale all fields of a structure by ScaleFactor.

OutStruct = InStruct;
Fields = fieldnames(OutStruct);
for f = 1:length(Fields)
  OutStruct.(Fields{f}) = OutStruct.(Fields{f}) * Scale;
end
