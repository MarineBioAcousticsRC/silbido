function trkStereoToMono(SourceData, SourceDir, TargetDir)

% Make sure directories / terminated
SourceDir = slash_terminated(SourceDir);
TargetDir = slash_terminated(TargetDir);

for idx=1:length(SourceData)
  fprintf('\n%s...', SourceData{idx});

  [pcm, info] = corReadAudio(sprintf('%ssw%s.sph', SourceDir, SourceData{idx}));

  mono = mean(pcm, 2);   % merge channels
  
  spWriteWav16(sprintf('%ssw%s.wav', TargetDir, SourceData{idx}), ...
               mono, info.SampleRate);
end


% ------------------------------------------------------------
function OutDir = slash_terminated(InDir)
% OutDir = slash_terminated(InDir)
% Return / terminated version of InDir

OutDir = InDir;
if OutDir(end) ~= '/'
    OutDir(end+1) = '/';
end
