clearvars; 
clc;
close all;

% prog com resolucao da equacoes!!!
% encontrou problemas de overrun por causa das funcoes de calculo das
% solucoes sao muito lentas!
% usa o vpasolve
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
tmp_ball_sound= 70;     %tempo do som da bola em ms(ex:120)
sample_range = ceil(tmp_ball_sound * Fs/1000); % tamanho da janela de analise
num_channels = 4;
threshold = 0.5e-3;           % limite para deteccao de impacto

%audio de ref
[ref_audio,~]=audioread("new_ref_audio.wav");
init_ref=400;   %necessario visto que o inicio nao e logo o som da bola!!!(ex:600)
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

update_point_2D(0, 0, mic_pos, true);  % reset inicial
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
                        [t12, c12, lags12] = estimate_tdoa(data1_norm, data2_norm, Fs);
                        [t13, c13, lags13] = estimate_tdoa(data1_norm, data3_norm, Fs);
                        [t14, c14, lags14] = estimate_tdoa(data1_norm, data4_norm, Fs);
                        fprintf("t12 = %.2f ms | t13 = %.2f ms | t14 = %.2f ms\n", t12*1e3, t13*1e3, t14*1e3);

                        
                        solutions = solve_hyperbola_pairs(t12, t13, t14, mic_pos, c);
                        [numRows,numCols] = size(solutions);


                        if (numRows > 1)
                            for k= 1:length(solutions)
                                fprintf("solucao %d: x= %f ,y= %f \n", k,solutions(k,1),solutions(k,2));
                            end  
                        else 
                            fprintf("solucao unica: x= %f ,y= %f \n",solutions(1),solutions(2));
                        end
                        
                     

                        pos_est = mean(solutions);
                        fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', pos_est(1), pos_est(2));
                        %update_point_2D(pos_est(1), pos_est(2), mic_pos);
                            
                        
                        if (pos_est(1) <= d_x && pos_est(2) <= d_y)
                            update_point_2D(pos_est(1), pos_est(2), mic_pos);
                            
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


%% Funtions
function [tdoa, c, lags] = estimate_tdoa(sig1, sig2, Fs)
    [c, lags] = xcorr(sig1, sig2);
    c= c ./ length(sig2);
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
function solutions = solve_hyperbola_pairs(t12, t13, t14, mic_pos, c)
    % Calcula os deslocamentos reais entre os microfones (em metros)
    digits(5);
    
    d12 = c * t12;
    d13 = c * t13;
    d14 = c * t14;

    % Soluções por par de hiperbolas
    sol12_13 = solve_pair(mic_pos(1,:), mic_pos(2,:), d12, ...
                          mic_pos(1,:), mic_pos(3,:), d13);

    sol12_14 = solve_pair(mic_pos(1,:), mic_pos(2,:), d12, ...
                          mic_pos(1,:), mic_pos(4,:), d14);

    sol13_14 = solve_pair(mic_pos(1,:), mic_pos(3,:), d13, ...
                          mic_pos(1,:), mic_pos(4,:), d14);

    % Juntar todas as soluções
    solutions = [sol12_13; sol12_14; sol13_14];
end

%%

function points = solve_pair(m1, m2, d1, m3, m4, d2)
    % Define as incógnitas
    syms x y real
    assumeAlso([x y], 'real');

    
    r1 = sqrt((x - m1(1))^2 + (y - m1(2))^2);
    r2 = sqrt((x - m2(1))^2 + (y - m2(2))^2);
    r3 = sqrt((x - m3(1))^2 + (y - m3(2))^2);
    r4 = sqrt((x - m4(1))^2 + (y - m4(2))^2);

    eq1 = r1 - r2 == d1;
    eq2 = r3 - r4 == d2;

    sol = vpasolve([eq1, eq2], [x, y]);

    points=sol;

    % Converter para matriz de pontos reais
    points = [];
    for i = 1:length(sol.x)
        xi = double(sol.x(i));
        yi = double(sol.y(i));
        if isreal(xi) && isreal(yi)
            points(end+1,:) = [xi, yi];
        end
    end
end

