clearvars; clc; close all;

[audio,Fs]=audioread("grav_aris_hall/gravacao_aris_hall_6.wav");
num_channels = 4;
audio = audio.';  % transpor -> canais x amostras
num_samples = size(audio,2);

frame_size = 1024; % como se fosse o tamanho do buffer
op_time = num_samples/Fs;

d_y = 1.528;                 
d_x = 2.738;                 
c = 343;                   
max_deviation= sqrt(d_y.^2 + d_x.^2)/c;    
smp_dev= ceil(max_deviation * Fs); 
tmp_ball_sound= 50;     
sample_range = ceil(tmp_ball_sound * Fs/1000); 
threshold = 6.486e-5;           
margem_mesa = 0.02;     

% audio de referencia
[ref_audio,~]=audioread("ball_0001.wav");
ref_audio = ref_audio(:,1); % caso stereo
ref_audio = ref_audio(1:sample_range); 
ref_audio = (ref_audio-mean(ref_audio))/std(ref_audio);

% energia
energy_tm = 1e-3; 
energy_win = ceil(energy_tm * Fs); 
EngAnl = EnergyTracker(num_channels, energy_win);

% mic positions
mic_pos = [0, 0; 0, d_y; d_x, 0; d_x, d_y];
vis = ImpactPlot2D(mic_pos); vis.reset();
pause(1);

loc = LocalizadorTDOA2D(mic_pos',c);

last_event=-inf;
tol_ev= tmp_ball_sound * 1e-3;
cooldown_samples = round(tol_ev * Fs);

%classificador
load('modelo_Boosted_Trees.mat','trainedModel');    

% Features usadas no treino
name_features = {'RMS','Waveform Length','Peak Ratio','Skewness', ...
    'Spectral Rolloff Frequency','Spectral Flatness', ...
    'Spectral Kurtosis','Spectral Bandwidth', ...
    'Rise Time','Fall Time'};

% Pré-alocar espaço para as 5 novas features
extra_features = cell(1,5);
for k = 6:10
    extra_features{k-5} = sprintf('Peak_freq%02d', k);
end

% Concatenar
name_features = [name_features, extra_features];


num_features = length(name_features);
features_vec = zeros(1, num_features);  % pré-alocado


count=1;
eng_vrf=1; flag1=0;
mean_eng=zeros(num_channels,ceil(num_samples/energy_win));

tempo_total=0; tempo_max=0;
tempo_totalP=0; tempo_maxP=0;
event_count = 0;
pred_count = 0;
loc_count = 0;

disp('Início da análise...');

for idx = 1:num_samples
    % simula captura amostra a amostra
    current_energy = audio(:,idx).^2;
    EngAnl.update(current_energy);

    if mod(count,energy_win)==0
        avg_energy = EngAnl.getAverage();
        mean_eng(:,eng_vrf)=avg_energy;

        if eng_vrf>=3, flag1=1; end
        eng_vrf=eng_vrf+1;
        if ~flag1, count=count+1; continue; end

        for channel=1:num_channels
            eng = mean_eng(channel,eng_vrf-1);
            eng_prev = mean_eng(channel,eng_vrf-2);
            eng_prev2 = mean_eng(channel,eng_vrf-3);

            if (eng_prev > threshold && eng_prev > eng && eng_prev > eng_prev2)
                peak_position = count - energy_win;

                if (peak_position - last_event < cooldown_samples)
                    continue
                end

                disp("evento em: " + num2str(peak_position/Fs,'%.4f') + "s");
                disp("channel: " + num2str(channel));
                event_count = event_count + 1;

                if count >= sample_range
                    % em vez de buffcir -> indexação direta
                    ini = max(1, peak_position-sample_range);
                    fin = min(num_samples, peak_position+sample_range);

                    data = audio(:,ini:fin);
                    data = (data - mean(data,2)) ./ std(data,0,2);

                    % cross-corr com ref
                    [xc,lags] = xcorr(data(channel,:), ref_audio);
                    [~,max_xc] = max(abs(xc));
                    t_lag = lags(max_xc);

                    ini = max(1, fin - sample_range - t_lag);
                    fin = min(num_samples, ini + sample_range + smp_dev);

                    data1 = audio(1,ini:fin);
                    data2 = audio(2,ini:fin);
                    data3 = audio(3,ini:fin);
                    data4 = audio(4,ini:fin);

                    tic;
                    t12 = gccphat(data1.', data2.', Fs);
                    t13 = gccphat(data1.', data3.', Fs);
                    t14 = gccphat(data1.', data4.', Fs);

                    tdoa=[t12;t13;t14];
                    pos_est = loc.localizar(tdoa);
                    tempo_inst=toc;
                    tempo_total=tempo_total+tempo_inst;
                    tempo_max=max(tempo_max,tempo_inst);

                    %fprintf('-> Posição estimada: (x=%.2f, y=%.2f)\n',pos_est(1),pos_est(2));

                    if (pos_est(1) <= d_x+margem_mesa && pos_est(2) <= d_y+margem_mesa && ...
                        pos_est(1) >= -margem_mesa && pos_est(2) >= -margem_mesa)
                            
                            loc_count = loc_count +1;
                         %----------------------------------------------------------
                            %Predict
                            %data_predict = buffcir.peekAroundReadIndex(init,fin,channel);
                            data_predict =  audio(channel,ini:fin);
                            tic;
                            features_vec(:) = extract_features_audio_v3(data_predict, Fs);
    
                            T_novo = array2table(features_vec, 'VariableNames', name_features);
                        
                            % Faz a predição
                            [label_previsto,scores] = trainedModel.predictFcn(T_novo);
                            tempo_instP=toc;
                            tempo_totalP=tempo_totalP+tempo_instP;
                            tempo_maxP=max(tempo_maxP,tempo_instP);

                            if(label_previsto == "bola_mesa")
                                fprintf('BOLA, score: %.02f\n',scores(1));
                                fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', pos_est(1), pos_est(2));
                                pred_count = pred_count +1;
                                %plot localizacao
                                vis.addImpact(pos_est(1), pos_est(2));
                            else
                                fprintf('NAO BOLA!!!, score: %.02f\n',scores(1));
                            end
                    else
                        disp('impacto fora do intervalo esperado!');
                    end
                    disp("-----------------------------------------------------------")

                    last_event=peak_position;
                end
            end
        end
    end
    count=count+1;
end

tempo_medio = tempo_total / event_count;           %eng_vrf
tempo_medioP = tempo_totalP / loc_count;
fprintf('Tempo médio loc: %.8f s\n', tempo_medio);
fprintf('Tempo máximo loc: %.8f s\n', tempo_max);
fprintf('Tempo médio pred: %.8f s\n', tempo_medioP);
fprintf('Tempo máximo pred: %.8f s\n', tempo_maxP);
fprintf('Numero de detecoes de energia: %.0f \n', event_count);
fprintf('Numero de localizacoes: %.0f \n', loc_count);
fprintf('Numero de predicoes: %.0f \n', pred_count);
