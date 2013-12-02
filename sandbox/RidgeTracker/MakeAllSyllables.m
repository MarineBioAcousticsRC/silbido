function MakeAllSyllables(window)

% spectrogram parameters
nfft=256;
if nargin<1
    window=100;
end

% ui to open wav file
[FileName,PathName] = uigetfile('*.wav','Select the wav file');
if ~isequal(FileName,0)
    
    flist=dir([PathName '/*.wav']);
    
    
    for f=1:length(flist)
        FileName=flist(f).name;
        
        fullname=fullfile(PathName,FileName);
        
        disp('Reading wav file...');
        [A,fs]=wavread(fullname);
        disp('Building spectrogram...');
        [P,~,specParams]=MakeSpectrogram(A,fs,nfft,window);
        disp('Dividing syllables...');
        
        SY=DivideSyllablesManually(P,A,specParams);
        outname=fullfile(PathName,['SY_' FileName(1:(end-4)) '.mat']);
        disp(sprintf('Saving %d syllables to %s...',length(SY),outname));
        save(outname,'SY');
        
        % write the marked syllables to a mat file
        outname=fullfile(PathName,['SY_' FileName(1:(end-4))]);
        for n=1:length(SY)
            sy=SY{n};
            wavwrite(sy.audio,sy.fs,sprintf('%s-%02d.wav',outname,n));
        end
    end
    
end
