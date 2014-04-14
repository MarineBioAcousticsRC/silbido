function pcm = mulawtopcm(mulaw)
% pcm = mulawtopcm(mulaw)
% Coverts to 16 bit PCM from 8 bit mu-law.
% Based upon algorithm in comp.speech FAQ
% Q2.7:  How do I convert to/from mu-law format? 

exp_lut = [0,132,396,924,1980,4092,8316,16764];
bits = 8;
mantissamask = 15;
exponentmask = 7;


% Extract high bit & convert to -1/1
SignBit = bitshift(mulaw, -(bits-1)) .* 2 - 1;
mulaw = bitcmp(mulaw, 8);
exponent = bitand(bitshift(mulaw, -4), exponentmask);
base = zeros(size(exponent));
for k=0:7
  if exp_lut(k+1)
    base = base + ((exponent == k) .* exp_lut(k+1));
  end
end
mantissa = bitand(mulaw, mantissamask);
pcm = SignBit .* (base + bitshift(mantissa, exponent+3));
