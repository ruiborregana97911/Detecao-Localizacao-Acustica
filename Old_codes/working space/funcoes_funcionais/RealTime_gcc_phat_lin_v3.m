clearvars; 
clc;
close all;

%  versao com implementacao da funcao adaptada funcional!!!!
% 
%

% parametros gerais
Fs = 48000;                % frequencia de amostragem
frame_size = 1024;         % tamanho do buffer placa de som
op_time = 45;              % tempo de operacao (em segundos)
d_y = 152.8e10-2;                 % distancia maxima em Y (m)
d_x = 273.8e10-2;                 % distancia maxima em X (m)
c = 343;                   % velocidade do som (m/s)
max_deviation= sqrt(d_y.^2 + d_x.^2)/c;    %tempo maximo de desfasamento entre sons (s)
smp_dev= ceil(max_deviation * Fs); %anterior mas em samples
tmp_ball_sound= 50;     %tempo do som da bola em ms
sample_range = ceil(tmp_ball_sound * Fs/1000); % tamanho da janela de analise
num_channels = 4;
threshold = 0.2e-3;           % limite para deteccao de impacto (0.2e-4)!!!
margem_mesa = 0.02;     %margem para alem dos limites da mesa

%audio de ref
[ref_audio,~]=audioread("ori_ball_2.wav");
init_ref=24800;   %necessario visto que o inicio nao e logo o som da bola!!!(ex:600)
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

update_point_2D_MP_v2(0, 0, mic_pos, true);  % reset inicial
pause(1);  % evitar conflitos na primeira chamada

totalOverrun = 0;
count=1;
% max_count = Fs * op_time;  % número máximo de amostras esperadas

%variaveis para a funcao de localizacao lin


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
                    
                    %em principio o codigo de detecao entra aqui!


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

                        
                        data1 = buffcir.peekAroundReadIndex(init,fin+smp_dev,1);
                        data2 = buffcir.peekAroundReadIndex(init,fin+smp_dev,2);
                        data3 = buffcir.peekAroundReadIndex(init,fin+smp_dev,3);
                        data4 = buffcir.peekAroundReadIndex(init,fin+smp_dev,4);

                        % data1_norm = DataNorm(data1);
                        % data2_norm = DataNorm(data2);
                        % data3_norm = DataNorm(data3);
                        % data4_norm = DataNorm(data4);
                        % 
                            
                        % Estimar TDOAs relativos ao canal 1
                        t12 = gccphat(data1.', data2.', Fs);
                        t13 = gccphat(data1.', data3.', Fs);
                        t14 = gccphat(data1.', data4.', Fs);
                        
                        fprintf("d12 = %.2f m | d13 = %.2f m | d14 = %.2f m\n", t12*c, t13*c, t14*c);
                        fprintf("t12 = %.2f ms | t13 = %.2f ms | t14 = %.2f ms\n", t12*1e3, t13*1e3, t14*1e3);                        
                        
                        tdoa=[t12;t13;t14];
                        pos_est = localizar_2D_TDOA_ls(mic_pos', tdoa, c);
                        %[pos_est, resnorm, f] = locate_2D_NLS(t12, t13, t14, mic_pos, c);
                        fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', pos_est(1), pos_est(2));
                        

                        
                        if (pos_est(1) <= d_x+margem_mesa && pos_est(2) <= d_y+margem_mesa && ...
                                pos_est(1) >= 0-margem_mesa && pos_est(2) >= 0-margem_mesa)

                            update_point_2D_MP_v2(pos_est(1), pos_est(2), mic_pos);
                            
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

        
        count= count + 1;    
    end
end

disp('analise concluida.');
release(mic);

if totalOverrun > 0
    warning(['Overrun detetado!!! numero total de overrun: ', num2str(totalOverrun)]);
end

%% plots



%% Funtions

function data_norm = DataNorm(data)

    %normalizar
    media_data = mean(data);
    dev_data = std(data);
    data_norm= (data - media_data) ./ dev_data; 
end  

%% funcao de localizacao

    
function pos_est = localizar_2D_TDOA_ls(mic_pos, tdoa, c)
    %nesta funcao o mic_pos tem de estar em transposto
    
    % Número de microfones
    N = size(mic_pos, 2);
    
    % Construção da matriz Ct (diferenças de posição em relação ao mic1)
    Ct = mic_pos(:, 2:end);
    
    % Diferenças de distância estimadas (baseadas nas TDOA)
    delta_d = tdoa * c;
    
    
    % Vetor r conforme a fórmula
    r = zeros(N-1, 1);
    for i = 1:N-1
        Ct(:,i) = Ct(:,i) - mic_pos(:, 1);
        r(i) = 0.5 * (norm(Ct(:,i))^2 - delta_d(i)^2);
    end
    
    % Resolução por mínimos quadrados
    A = (Ct * Ct') \ Ct;
    Ar = A * r;
    Ad = -A * delta_d;
    
    % Resolução da equação quadrática: 
    % a*d1^2 + b*d1 + c = 0
    
    a = Ad(1).^2 + Ad(2).^2 - 1;
    b = 2*(Ar(1)*Ad(1) + Ar(2)*Ad(2));
    c = Ar(1).^2 + Ar(2).^2;
    
    sq = sqrt(b.^2-4*a*c);
    s = real(([sq -sq]-b)/(2*a));
    
    
    % Estimar posição relativa e converter para absoluta
    pos_cands = Ad * s + Ar + mic_pos(:,1);
    
    err = zeros(1, 2);
    for i = 1:2
        dists = vecnorm(pos_cands(:,i) - mic_pos, 2, 1);   % distâncias para cada mic
        de_est = dists(1) - dists(2:end);                 % diferenças em relação ao mic1
        err(i) = norm(de_est(:) - delta_d(:));            % erro em relação aos delta_d reais
    end
    
    
    % Escolher a solução com menor erro
    [~, idx_best] = min(err);
    pos_est = pos_cands(:, idx_best);
    
end
% outra forma de fazer a escolha do cadidato certo
    % err = zeros(1, 2); % vetor para guardar o erro de cada solução
    % 
    % for i=1:2
    %     d(i,1) = sqrt((pos_cands(1,i)-mic_pos(1,1)).^2+(pos_cands(2,i)-mic_pos(2,1)).^2);
    %     for j=2:4
    %         d(i,j) = sqrt((pos_cands(1,i)-mic_pos(1,j)).^2+(pos_cands(2,i)-mic_pos(2,j)).^2);
    %        de_est(i,j-1) = (d(i,1) - d(i,j));
    %     end
    % 
    %     err(i) = norm(de_est(i,:) - delta_d(:));
    % 
    % end