clearvars; 
clc;
close all;

% 
% 
%

% parametros gerais
Fs = 48000;                % frequencia de amostragem
frame_size = 1024;         % tamanho do buffer placa de som
op_time = 10;              % tempo de operacao (em segundos)
d_y = 0.5;                 % distancia maxima em Y (m)
d_x = 0.5;                 % distancia maxima em X (m)
c = 343;                   % velocidade do som (m/s)
max_deviation= sqrt(d_y.^2 + d_x.^2)/c;    %tempo maximo de desfasamento entre sons (s)
smp_dev= ceil(max_deviation * Fs); %anterior mas em samples
tmp_ball_sound= 100;     %tempo do som da bola em ms(ex:120)
sample_range = ceil(tmp_ball_sound * Fs/1000); % tamanho da janela de analise
num_channels = 4;
threshold = 0.5e-3;           % limite para deteccao de impacto

%audio de ref
[ref_audio,~]=audioread("new_ref_audio.wav");
init_ref=600;   %necessario visto que o inicio nao e logo o som da bola!!!(ex:600)
ref_audio=ref_audio(init_ref:sample_range+init_ref-1);    %USAR ISTO PARA COMP O SINAL COM A REF

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


%variaveis
Eng=[];

vrf_tm = ceil(1e-3 * Fs); %tempo em ms 

mean_eng=[];

last_event=-inf;
peak_position=0;
tol_ev= tmp_ball_sound * 1e-3;  %tolerancia em segundos (cooldown)
cooldown_samples = round(tol_ev * Fs); %cooldown em samples


%variaveis de debug
enable_debub= false; 

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

buff_size= sample_range*3;
buffcir = CircularBuffer(num_channels, buff_size);

mic_pos = [0, 0;    % channel 1
           0, d_y;  % channel 2
           d_x, 0;  % channel 3
           d_x, d_y];%channel 4

update_point_2D_v2(0, 0, mic_pos, true);  % reset inicial
pause(1);  % evitar conflitos na primeira chamada

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
            sound(:, count) = audio;  % cada coluna é uma amostra de audio diferente
        end
        
        Eng(:,count) = [audio(1)^2; audio(2)^2; audio(3)^2; audio(4)^2];

       
        %verificacao de energia (pra ja e feita uma analise a cada 1ms)
        if mod(count, vrf_tm) == 0
            for ch = 1:4
                mean_eng(ch, eng_vrf) = mean(Eng(ch, count - vrf_tm + 1:count));
            end
            %garantir que temos info para fazer o resto do codigo
            if(eng_vrf == 3)    
                flag1=1;
            end
            
            eng_vrf=eng_vrf+1;
    
            if(flag1 == 0)
                continue
            end
        
            %indx=length(mean_eng(1,:)); %index para energia

            for channel= 1:4
                eng = mean_eng(channel,eng_vrf-1);
                eng_prev = mean_eng(channel,eng_vrf-2);
                eng_prev2 = mean_eng(channel,eng_vrf-3);
                
                if(eng_prev > threshold && eng_prev > eng && eng_prev > eng_prev2)
                    
                    %verificacao de cooldown
                    peak_position = count - vrf_tm;
                    
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


                        switch channel
                            case 1
                                data1 = buffcir.peekAroundReadIndex(init,fin,1);
                                data2 = buffcir.peekAroundReadIndex(init,fin+smp_dev,2);
                                data3 = buffcir.peekAroundReadIndex(init,fin+smp_dev,3);
                                data4 = buffcir.peekAroundReadIndex(init,fin+smp_dev,4);
                            case 2
                                data1 = buffcir.peekAroundReadIndex(init,fin+smp_dev,1);
                                data2 = buffcir.peekAroundReadIndex(init,fin,2);
                                data3 = buffcir.peekAroundReadIndex(init,fin+smp_dev,3);
                                data4 = buffcir.peekAroundReadIndex(init,fin+smp_dev,4);
                            case 3
                                data1 = buffcir.peekAroundReadIndex(init,fin+smp_dev,1);
                                data2 = buffcir.peekAroundReadIndex(init,fin+smp_dev,2);
                                data3 = buffcir.peekAroundReadIndex(init,fin,3);
                                data4 = buffcir.peekAroundReadIndex(init,fin+smp_dev,4);
                            case 4
                                data1 = buffcir.peekAroundReadIndex(init,fin+smp_dev,1);
                                data2 = buffcir.peekAroundReadIndex(init,fin+smp_dev,2);
                                data3 = buffcir.peekAroundReadIndex(init,fin+smp_dev,3);
                                data4 = buffcir.peekAroundReadIndex(init,fin,4);
                        end

                        data1_norm = DataNorm(data1);
                        data2_norm = DataNorm(data2);
                        data3_norm = DataNorm(data3);
                        data4_norm = DataNorm(data4);
 
                            
                        % Estimar TDOAs relativos ao canal 1
                        t12 = estimate_tdoa(data1_norm, data2_norm, Fs);
                        t13 = estimate_tdoa(data1_norm, data3_norm, Fs);
                        t14 = estimate_tdoa(data1_norm, data4_norm, Fs);
                                        
                        [pos_est, resnorm, f] = locate_2D_NLS(t12, t13, t14, mic_pos, c);
                        fprintf("t12 = %.2f ms | t13 = %.2f ms | t14 = %.2f ms\n", t12*1e3, t13*1e3, t14*1e3);
                        fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', pos_est(1), pos_est(2));
                        %update_point_2D(pos_est(1), pos_est(2), mic_pos);
                            
                        
                        if (pos_est(1) <= d_x && pos_est(2) <= d_y)
                            update_point_2D_v2(pos_est(1), pos_est(2), mic_pos);
                            
                        else
                            disp('impacto fora do intervalo esperado!');
                            
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

%% plots

figure;

subplot(4,1,1); plot(data1_norm); title('Canal 1'); xlabel('Tempo (s)');
subplot(4,1,2); plot(data2_norm); title('Canal 2'); xlabel('Tempo (s)');
subplot(4,1,3); plot(data3_norm); title('Canal 3'); xlabel('Tempo (s)');
subplot(4,1,4); plot(data4_norm); title('Canal 4'); xlabel('Tempo (s)');

figure;
plot(data1_norm,'DisplayName', 'channel 1');
hold on;
plot(data2_norm,'DisplayName', 'channel 2');
hold on;
plot(data3_norm,'DisplayName', 'channel 3');
hold on;
plot(data4_norm,'DisplayName', 'channel 4');
hold off;
legend show;





%% Funtions
function tdoa = estimate_tdoa(sig1, sig2, Fs)
    [c, lags] = xcorr(sig1, sig2);  
    [~, idx] = max(abs(c));
    tdoa = lags(idx) / Fs;
end

%%
function data_norm = DataNorm(data)

    %normalizar
    media_data = mean(data);
    dev_data = std(data);
    data_norm= (data - media_data) ./ dev_data; 
end                        

%% 
function [x, resnorm, f] = locate_2D_NLS(t12, t13, t14, mic_pos, c)
    x0 = mean(mic_pos);  % ponto inicial

    %norma eucladiana = sqrt(.^2) 
    f = @(p) [
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(2,:)) - c*t12;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(3,:)) - c*t13;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(4,:)) - c*t14
    ];

    opts = optimoptions('lsqnonlin', 'Display','iter');  
    [x, resnorm] = lsqnonlin(f, x0, mic_pos(1,:), mic_pos(4,:), opts);
    
    %debug
    fprintf("Estimativa inicial: [%.2f, %.2f]\n", x0(1), x0(2));
    fprintf("Posição estimada: [%.2f, %.2f]\n", x(1), x(2));
    fprintf("Erro final: %.4e\n", resnorm);

end
%%

function [x, resnorm, f] = locate_2D_NLS2(t12, t13, t14, mic_pos, c, mic)
  
   % Começa na posição do microfone que detectou primeiro
    pos_est = mic_pos(mic, :);

    % Calcula o vetor médio para os outros microfones
    dir_vec = mean(mic_pos - pos_est, 1);

    % Fator de deslocamento para afastar a estimativa inicial um pouco
    desloc_factor = 0.5;

    % Estimativa inicial ajustada
    x0 = pos_est + desloc_factor * dir_vec;
    %norma eucladiana = sqrt(.^2) 
    f = @(p) [
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(2,:)) - c*t12;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(3,:)) - c*t13;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(4,:)) - c*t14
    ];

    opts = optimoptions('lsqnonlin', 'Display','iter');  
    [x, resnorm] = lsqnonlin(f, x0, [], [], opts);

    %debug
    fprintf("Estimativa inicial: [%.2f, %.2f]\n", x0(1), x0(2));
    fprintf("Posição estimada: [%.2f, %.2f]\n", x(1), x(2));
    fprintf("Erro final: %.4e\n", resnorm);

end
    
