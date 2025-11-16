clearvars; 
clc;
close all;

% testar para ver se o adicionar a normalizacao vai ajudar!!!!!
% 
%

% parametros gerais
Fs = 48000;                 % frequencia de amostragem
frame_size = 1024;           % tamanho do buffer
op_time = 5;              % tempo de operacao (em segundos)
d = 50;                     % distancia entre microfones (cm)
v = 343;                  % velocidade do som (m/s)
threshold = 0.5e-3;           % limite para deteccao de impacto
tmp_ball_sound= 10;     %tempo do som da bola em ms
max_deviation= (d/v)*10;    %tempo maximo de desfasamento entre sons (ms)
smp_dev= ceil(max_deviation*(Fs/1000)); %anterior mas em samples
sample_range = ceil(tmp_ball_sound * Fs/1000); % tamanho da janela de analise
num_channels = 2;

%audio de ref
[ref_audio,~]=audioread("ref_ball_sound.wav");
ref_audio=ref_audio(1:sample_range);    %USAR ISTO PARA COMP O SINAL COM A REF

%normalizar(padronizado)
media_ref=mean(ref_audio);
dev_ref=std(ref_audio);
ref_audio_norm= (ref_audio - media_ref)/dev_ref;

 % configuracao do objeto de captura de audio
    mic = audioDeviceReader('Driver', 'ASIO', ...
        'Device', "OCTA-CAPTURE", 'NumChannels', num_channels, ...
        'SamplesPerFrame', frame_size, ...
        'SampleRate', Fs, ...
        'BitDepth', '24-bit integer');



  
%variaveis
Eng_1=[];
Eng_2=[];
vrf_tm=1;   %1ms
vrf_tm= vrf_tm * 1e-3 * Fs;   %conversao para amostras

mean_eng=[];

last_event=-inf;
peak_position=0;
tol_ev= tmp_ball_sound * 1e-3;  %tolerancia em segundos (cooldown)
cooldown_samples = round(tol_ev * Fs); %cooldown em samples


%variaveis de debug
enable_debub= true; 

array_corr=[];
array_lags=[];
k_index=1;

array_corr2=[]; %corr da posicao
array_lags2=[];
k_index2=1;
c2=0;
lags2=0;

array_sound=[];
debug_aux=1;

max_count = Fs * op_time;  % número máximo de amostras esperadas
sound = zeros(2, max_count);  % prealocar matriz para 2 canais


%end of debug

%buffer circular

buff_size= 8192;
buffcir = CircularBuffer(num_channels, buff_size);


update_point_1D(0,d,true);  %dar reset ás variaveis internas desta funcao

pause(1);   %necessario colocar porque causava overrun na captacao do som!

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
        if enable_debub
            sound(:, count) = audio;  % cada coluna é uma amostra estéreo
        end
            
        Eng_1(count)=audio(1).^2;
        Eng_2(count)=audio(2).^2;
        
        %verificacao de energia (pra ja e feita uma analise a cada 1ms)
        if(rem(count,vrf_tm) == 0)
            mean_eng(1,eng_vrf)= mean(Eng_1(count-vrf_tm+1:count));
            mean_eng(2,eng_vrf)= mean(Eng_2(count-vrf_tm+1:count));
            
            %garantir que temos info para fazer o resto do codigo
            if(eng_vrf == 3)    
                flag1=1;
            end
            
            eng_vrf=eng_vrf+1;
    
            if(flag1 == 0)
                continue
            end
        
            indx=length(mean_eng(1,:)); %index para energia

            for channel= 1:2
                eng= mean_eng(channel,indx);
                eng_prev= mean_eng(channel,indx-1);
                eng_prev2= mean_eng(channel,indx-2);
                
                if(eng_prev > threshold && eng_prev > eng && eng_prev > eng_prev2)
                    
                    %verificacao de cooldown
                    peak_position = count - vrf_tm;
                    
                    if (peak_position - last_event < cooldown_samples)
                        continue
                    end

                    disp("evento em: " + num2str(count/Fs,'%.4f') + "s");
                    disp("channel: " + num2str(channel));
    
                    if(count >= sample_range)


                        data= buffcir.peekAroundReadIndex(sample_range,sample_range);
                        %normalizar
                        media_data = mean(data, 2);
                        dev_data = std(data, 0, 2);
                        data_norm= (data - media_data) ./ dev_data; 
                            
                        if(channel == 1)
                            [c,lags] = xcorr(data_norm(1,:),ref_audio_norm(1:sample_range));
                            [~,max_c]=max(abs(c));
                            t_lag=lags(max_c);
                            
                            init=sample_range-t_lag;
                            fin= sample_range - init;
                            data1 = buffcir.peekAroundReadIndex(init,fin,1);
                            data2 = buffcir.peekAroundReadIndex(init,fin+smp_dev,2);

                            %calculo da distancia e plot    
                            [pos_s, c2, lags2]=calculate_pos_1D_v3(data1, data2, Fs, v, smp_dev);   
                        else
                            [c,lags] = xcorr(data(2,:),ref_audio(1:sample_range));
                            [~,max_c]=max(abs(c));
                            t_lag=lags(max_c);
                            
                            init=sample_range-t_lag;
                            fin= sample_range - init;
                            data1 = buffcir.peekAroundReadIndex(init,fin+smp_dev,1);
                            data2 = buffcir.peekAroundReadIndex(init,fin,2);

                            %calculo da distancia e plot    
                            [pos_s, c2, lags2]=calculate_pos_1D_v3(data1, data2, Fs, v, smp_dev);
                        end
                        
                        if (abs(pos_s) <= d/2)
                            update_point_1D(pos_s,d);
                            %pos_s
                            disp("posicao do evento: " + num2str(pos_s));
                        else
                            disp('impacto fora do intervalo esperado.');
                            %pos_s
                            disp("posicao do evento: " + num2str(pos_s));
                        end
    
                        if enable_debub
                            %debug vectors
                            array_corr(k_index,:)=c;
                            array_lags(k_index,:)=lags;
                            k_index= k_index+1;
                            
                            array_corr2(k_index2,:)=c2;
                            array_lags2(k_index2,:)=lags2;
                            k_index2= k_index2+1;

                            array_sound(debug_aux,:)=buffcir.peekAroundReadIndex(init,fin+smp_dev,1);
                            debug_aux=debug_aux+1;
                            array_sound(debug_aux,:)=buffcir.peekAroundReadIndex(init,fin+smp_dev,2);
                            debug_aux=debug_aux+1;

                            
                        end
                        disp("-----------------------------------------------------------")        
                        %last_event= present_event;
                        last_event = peak_position;

                    end   
                end
            end

        end

        
        count= count +1;    
    end
end

disp('analise concluida.');
release(mic);

if totalOverrun > 0
    warning(['Overrun detetado!!! numero total de overrun: ', num2str(totalOverrun)]);
end


%% sound plot

if enable_debub

    figure;
    final_t= length(sound(1,:)) / Fs;
    %t= linspace(0,final_t,length(sound(1,:)));
    t = linspace(0, size(sound,2)/Fs, size(sound,2));
    plot(t,sound(1,:));
    hold on
    plot(t,sound(2,:));
    grid on
    xlabel("tempo (segundos)");
    title("audio original e deslocado");
    
    
    %mean eng
    figure;
    t_e=linspace(0,final_t,length(mean_eng(1,:)));
    plot(t_e,mean_eng(1,:));
    hold on
    plot(t_e,mean_eng(2,:));
    grid on
    xlabel("tempo (segundos)");
    title("energia media");
    
    
    %correlacao da ref
    for i=1:k_index-1
        figure;
        plot(array_lags(i,:), abs(array_corr(i,:)));
        grid on;
        title("correlacao com a referencia")
    end
    
    %correlacao da posicao
    for i=1:k_index2-1
        figure;
        plot(array_lags2(i,:), abs(array_corr2(i,:)));
        grid on;
        title("correlacao da posicao")
    end
    
    %windowed sound
    j=1;
    for i=1:(debug_aux-1)/2
        figure;
        plot(array_sound(j,:));
        j=j+1;
        hold on;
        plot(array_sound(j,:));
        j=j+1;
    end

end