function power_dB = dtSpectrogramNoiseComp(power_dB, Method, useP) 
% snr_power = dtSpectrogramNoiseComp(power_dB, Method, useP) 
% Compensate for noise.  
% The argument useP is a logical index that indicates which time slices
% of the spectrogram power_dB should be used.  Not all noise compensation
% techniques make use of this.

region = [3 3];
switch Method
    case 'none'
        % do nothing
        
    case 'wiener'
        power_dB = wiener2(power_dB, region);
        % follow up by means subtraction
        power_dB = dtSNR_meanssub(power_dB, useP);
        
    case 'median'
        power_dB = medfilt2(power_dB, region);
        % follow up by means subtraction
        
%        [~,power_dB] = MallawaarachchiFilter(power_dB,1,1,4);
        
%         for idx = 1:length(power_dB)
%             if(useP(idx) == 1);
%                 frame = power_dB(:,idx);
%                 m = mean(frame);
%                 power_dB(:,idx) = frame - m;
%             end
%         end
        
        power_dB = dtSNR_meanssub(power_dB, useP); 
    
    case 'meansub'
        % Mean for specific time
        power_dB = dtSNR_meanssub(power_dB, useP);
    
    case 'ma'
        power_dB = medfilt2(power_dB, region);
        
        % moving average means subtraction
        % Assume 2 ms advance and 3 s MA
        N = round(3/.002);
        if mod(N, 2)
            N = N - 1;  % ensure odd
        end
        Shift = (N-1)/2;
        snr_power_dB = stMARestricted(power_dB', N, double(useP), Shift);
        snr_power_dB = snr_power_dB';
        power_dB = power_dB - snr_power_dB;
        
    case 'psmf'
        % progressive switching median filter
        power_dB = PSMF(power_dB);
        power_dB = dtSNR_meanssub(power_dB, useP);
        
    case 'kovesi'
        % Requires:
        % P. D. Kovesi.  
        % MATLAB and Octave Functions for Computer Vision and Image Processing.
        % School of Computer Science & Software Engineering,
        % The University of Western Australia.   Available from:
        % <http://www.csse.uwa.edu.au/~pk/research/matlabfns/>
        % Last accessed May 12, 2009.
        power_dB = noisecomp(power_dB, 3, 6, 2.5, 6, 1);
        
    case 'minstat'
        % Minimum statistics noise estimation
        % Requires voicebox:
        % http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html
        
        error('minstat noise subtraction not currently implemented');
        % would need to update for current variables, not worth it as
        % doesn't seem to work well
        
        % failed miserably - might be better with tuning but it does
        % not seem worth investing much time in for now.
        if StartBlock_s == Start_s
            % first invocation
            [noise_dB_T, noise_state] = estnoisem(power_dB', Advance_s);
        else
            [noise_dB_T, noise_state] = estnoisem(power_dB', noise_state);
        end
        power_dB = power_dB - noise_dB_T';
        
    case 'rt'
         
        [power_dB,~] = CalculateFilter(power_dB, ...
            10, ... %HPF
            10, ... %LPF
            1, ... %ISD
            0, ... %ADAPTIVE
            0,... %BANDPASS
            1,... %CLICK
            0); %MASK
        power_dB = dtSNR_meanssub(power_dB, useP);
    otherwise
        error('unknown noise subtraction technique')
end