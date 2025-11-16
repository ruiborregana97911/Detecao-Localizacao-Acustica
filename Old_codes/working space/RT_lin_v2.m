clearvars; 
clc;
close all;

%  intrudocao ao predict
% 
%

% parametros gerais
Fs = 48000;                % frequencia de amostragem
frame_size = 1024;         % tamanho do buffer placa de som
op_time = 80;              % tempo de operacao (em segundos)
d_y = 60e-2;                 % distancia maxima em Y (m) (1.528)mesa de ping pong
d_x = 150e-2;                 % distancia maxima em X (m) (2.738)
c = 343;                   % velocidade do som (m/s)
max_deviation= sqrt(d_y.^2 + d_x.^2)/c;    %tempo maximo de desfasamento entre sons (s)
smp_dev= ceil(max_deviation * Fs); %anterior mas em samples
tmp_ball_sound= 50;     %tempo do som da bola em ms
sample_range = ceil(tmp_ball_sound * Fs/1000); % tamanho da janela de analise
num_channels = 4;
threshold = 6.486e-5;           % limite para deteccao de impacto 
margem_mesa = 0.02;     %margem para alem dos limites da mesa

%audio de ref
%[ref_audio,~]=audioread("ori_ball_2.wav");
[ref_audio,~]=audioread("ball_0001.wav");
%init_ref=24800;   %necessario visto que o inicio nao e logo o som da bola!!!(ex:600)
%ref_audio=ref_audio(init_ref:sample_range+init_ref-1);    %USAR ISTO PARA COMP O SINAL COM A REF

%normalizar ref
media_ref=mean(ref_audio);
dev_ref=std(ref_audio);
ref_audio_norm= (ref_audio - media_ref) ./ dev_ref;

 % configuracao do objeto de captura de audio
    mic = audioDeviceReader('Driver', 'ASIO', ...
        'Device', "OCTA-CAPTURE", 'NumChannels', num_channels, ...
        'SamplesPerFrame', frame_size, ...
        'SampleRate', Fs, ...
        'BitDepth', '24-bit integer');

%SVM e predict confs

load('SVM_CUBIC_gen2.mat');  % Carrega trainedModel para o workspace

name_features = {'ZCR','RMS','Clearence Factor','Crest Factor', ...
    'Impulse Factor','Waveform Length','Peak Ratio','Kurtosis','Skewness', ...
    'Shape Factor','Spectral Entropy','Spectral Rolloff Frequency', ...
    'Spectral Flatness','Spectral Centroid','Spectral Skewness', ...
    'Spectral Kurtosis','Spectral Variance','Spectral Bandwidth', ...
    'Rise Time','Fall Time','Energy Entropy'};
for k=1:10
    name_features{end+1} = sprintf('Peak_freq%02d', k);
end



%variaveis
energy_tm = 1; %tempo em ms
energy_tm = energy_tm * 1e-3; %conversao para s
energy_win = ceil(energy_tm * Fs); %amostras 

mean_mem= op_time/energy_tm;
mean_eng= zeros(4,mean_mem);
%mean_eng=[];
%energy_win = ceil(1e-3 * Fs);  % 1 ms de amostras (~48)
EngAnl = EnergyTracker(num_channels, energy_win);

last_event=-inf;
peak_position=0;
tol_ev= tmp_ball_sound * 1e-3;  %tolerancia em segundos (cooldown)
cooldown_samples = round(tol_ev * Fs); %cooldown em samples


%variaveis de debug


max_count = Fs * op_time;  % número máximo de amostras esperadas
sound = zeros(2, max_count);  % prealocar matriz para 2 canais

%end of debug

%buffer circular

buff_size= sample_range*4;
buffcir = CircularBuffer(num_channels, buff_size);

mic_pos = [0, 0;    % channel 1
           0, d_y;  % channel 2
           d_x, 0;  % channel 3
           d_x, d_y];%channel 4


vis = ImpactPlot2D(mic_pos);
vis.reset();  % desenha a mesa
pause(2);  % evitar conflitos na primeira chamada

%variaveis para a funcao de localizacao lin
loc = LocalizadorTDOA2D(mic_pos',c);

totalOverrun = 0;
count=1;
% max_count = Fs * op_time;  % número máximo de amostras esperadas



disp('inicio da analise...');

eng_vrf=1;
flag1=0;

t0=tic;
while toc(t0) < op_time
    
    % captura um frame de audio
    [frame_data,numOverrun] = mic();   
    
    if numOverrun > 0
        totalOverrun = totalOverrun + numOverrun;
        warning(['Overrun detectado! nº: ',num2str(numOverrun)]);
    end

    if ~isempty(frame_data)
        
        buffcir.write(frame_data');
    else
        warning('Frames vazios!');
    end
        

    while(buffcir.getAvailableSamples > sample_range)
        
        if count > max_count
            break
        end

        audio = buffcir.read(1);

        
        current_energy = audio.^2;
        EngAnl.update(current_energy);
       
        %verificacao de energia (pra ja e feita uma analise a cada 1ms)
        if mod(count, energy_win) == 0

            avg_energy = EngAnl.getAverage();  % vetor 4x1
            mean_eng(:, eng_vrf) = avg_energy;
            
            %garantir que temos info para fazer o resto do codigo
            if(eng_vrf >= 3)    
                flag1=1;
            end

            eng_vrf=eng_vrf+1;

            if(flag1 == 0)
                continue
            end


            for channel= 1:4
                eng = mean_eng(channel,eng_vrf-1);
                eng_prev = mean_eng(channel,eng_vrf-2);
                eng_prev2 = mean_eng(channel,eng_vrf-3);
                
                if(eng_prev > threshold && eng_prev > eng && eng_prev > eng_prev2)
                    
                    %verificacao de cooldown
                    peak_position = count - energy_win;
                    
                    if (peak_position - last_event < cooldown_samples)
                        continue
                    end

                    disp("evento em: " + num2str(peak_position/Fs,'%.4f') + "s");
                    disp("channel: " + num2str(channel));
                    
                    


                    if(count >= sample_range)


                        data= buffcir.peekAroundReadIndex(sample_range,sample_range);
                        %normalizar
                        media_data = mean(data, 2);
                        dev_data = std(data, 0, 2);
                        data_norm= (data - media_data) ./ dev_data; 
                            
                        % ch1 e o de referencia
                        [xc,lags] = xcorr(data_norm(channel,:), ref_audio_norm(1:sample_range));
                        xc=xc/sample_range;
                        [~,max_xc]=max(abs(xc));
                        t_lag=lags(max_xc);
                        
                        init=sample_range-t_lag;
                        fin= sample_range - init;
                        
                        %----------------------------------------------------------
                        %Predict
                        data_predict = buffcir.peekAroundReadIndex(init,fin,channel);
                        features = extarct_features_audio_v2(data_predict, Fs);

                        T_novo = array2table(features, 'VariableNames', name_features);
                    
                        % Faz a predição
                        [label_previsto,scores] = trainedModel.predictFcn(T_novo);

                        if(label_previsto == 'bola')

                            fprintf('BOLA, score: %.02f\n',scores(1));

                            data1 = buffcir.peekAroundReadIndex(init,fin+smp_dev,1);
                            data2 = buffcir.peekAroundReadIndex(init,fin+smp_dev,2);
                            data3 = buffcir.peekAroundReadIndex(init,fin+smp_dev,3);
                            data4 = buffcir.peekAroundReadIndex(init,fin+smp_dev,4);
    
                                
                            % Estimar TDOAs relativos ao canal 1
                            t12 = gccphat(data1.', data2.', Fs);
                            t13 = gccphat(data1.', data3.', Fs);
                            t14 = gccphat(data1.', data4.', Fs);
                            
                            fprintf("d12 = %.2f m | d13 = %.2f m | d14 = %.2f m\n", t12*c, t13*c, t14*c);
                            fprintf("t12 = %.2f ms | t13 = %.2f ms | t14 = %.2f ms\n", t12*1e3, t13*1e3, t14*1e3);                        
                            
                            tdoa=[t12;t13;t14];
                            pos_est = loc.localizar(tdoa);
                            
                            fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', pos_est(1), pos_est(2));
                            
                            
                            if (pos_est(1) <= d_x+margem_mesa && pos_est(2) <= d_y+margem_mesa && ...
                                    pos_est(1) >= 0-margem_mesa && pos_est(2) >= 0-margem_mesa)
    
                                vis.addImpact(pos_est(1), pos_est(2));
                            else
                                disp('impacto fora do intervalo esperado!');
                                
                            end
        
                            
                            disp("-----------------------------------------------------------")
                        else
                            fprintf('NAO BOLA!!!, score: %.02f\n',scores(1));
                            
                        end
                        %last_event= present_event;
                        last_event = peak_position;

                    end   
                end
            end
            
        end

        
        count= count + 1;    
    end
end

disp('analise concluida.');
release(mic);

if totalOverrun > 0
    warning(['Overrun detetado!!! numero total de overrun: ', num2str(totalOverrun)]);
end
 

