function capture_audio(buff, Fs, frame_size, num_channels, time)
    
    % configuracao do objeto de captura de audio
    mic = audioDeviceReader('Driver', 'ASIO', ...
        'Device', "OCTA-CAPTURE", 'NumChannels', num_channels, ...
        'SamplesPerFrame', frame_size, ...
        'SampleRate', Fs, ...
        'BitDepth', '24-bit integer');

    disp("captura iniciada...");

    t=tic
    while(toc(t) < time)
        % captura um frame de audio
        [frame_data,numOverrun] = mic();   
        
        if numOverrun > 0
            totalOverrun = totalOverrun + numOverrun;
            warning(['Overrun detectado! nº: ',num2str(numOverrun)]);
        end

        if ~isempty(frame_data)
            
            buff.write(frame_data);
        else
            warning('Frames vazios!');
        end
        

    end
    
    buff.enableEndWrite();
    disp('analise concluida.');
    release(mic);
    
    if totalOverrun > 0
        warning(['Overrun detetado!!! numero total de overrun: ', num2str(totalOverrun)]);
    end


end