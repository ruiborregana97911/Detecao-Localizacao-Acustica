%% Parâmetros

clear; clc; close all;
Fs = 48000;                % Frequência de amostragem
recorte_ms = 50;           % duração do recorte em ms
recorte_samples = round(recorte_ms/1000*Fs);

num_channels = 4;          % número de canais
wav_files = {'gravacao_aris_hall_1.wav','gravacao_aris_hall_2.wav','gravacao_aris_hall_3.wav', ...
    'gravacao_aris_hall_4.wav','gravacao_aris_hall_5.wav','gravacao_aris_hall_6.wav'};

mat_files = {'eventos_label_ball_gravacao_aris_hall_1.mat','eventos_label_ball_gravacao_aris_hall_2.mat', ...
    'eventos_label_ball_gravacao_aris_hall_3.mat','eventos_label_ball_gravacao_aris_hall_4.mat', ...
    'eventos_label_ball_gravacao_aris_hall_5.mat','eventos_label_ball_gravacao_aris_hall_6.mat'};

% Lista de exclusões por ficheiro
exclusoes = {
    [43,44,45];
    [60,61,62,63];
    [63,64,65,66,67,68,69,70,71];
    [27,28,29,30,63,64];
    [34,35,36,37,76,77,78,79,80,81];
    [43,44,45,46,47,48,63,64,65,66,67,103,104,105,106,117,118,119,120];
};

output_folder = 'recortes_ball_3'; % Pode mudar para o que quiser
if ~exist(output_folder,'dir')
    mkdir(output_folder);
end


usarExclusoes = true; % ativar ou desativar exclusões

% Carregar referência normalizada (usar primeiro canal se stereo)
[ref_audio,~] = audioread("ball_0001.wav");
if size(ref_audio,2) > 1
    ref_audio = ref_audio(:,1);
end
ref_audio_norm = (ref_audio - mean(ref_audio)) ./ std(ref_audio);

% Loop por cada arquivo wav
count=1;
for i = 1:length(wav_files)
    
    % Carregar áudio
    [audio_data, Fs_file] = audioread(wav_files{i});  % [num_samples x num_channels]
    audio_data = audio_data';                           % [num_channels x num_samples]
    
    % Carregar eventos do .mat
    mat = load(mat_files{i}); 
    eventos = mat.eventos; % suposição: a variável no .mat chama-se event_times
    
    % Aplicar exclusões se necessário
    if usarExclusoes && ~isempty(exclusoes{i})
        eventos(exclusoes{i}) = [];
    end
    
    % Converter tempos para samples
    event_samples = round(eventos * Fs_file);
    
    for j = 1:length(event_samples)
        % Intervalo inicial para cálculo de energia (pode ser +/- 5ms do evento)
        win_samples = round(0.01*Fs_file);  % 10ms
        start_idx = max(1, event_samples(j) - win_samples);
        end_idx   = min(size(audio_data,2), event_samples(j) + win_samples);
        
        event_data = audio_data(:, start_idx:end_idx);
        
        % 1. Calcular energia por canal
        channel_energy = sum(event_data.^2, 2);
        %[~, best_channel] = max(channel_energy); % primeiro mais energetico

        [sorted_energy, sorted_idx] = sort(channel_energy, 'descend');
        %best_channel  = sorted_idx(2);  % segundo mais energético

        best_channel = sorted_idx(3);
        
        % 2. Correlação com referência para ponto inicial refinado
        data_ch = event_data(best_channel, :);
        data_ch_norm = (data_ch - mean(data_ch)) / std(data_ch);
        [xc, lags] = xcorr(data_ch_norm, ref_audio_norm);
        [~, max_idx] = max(abs(xc));
        t_lag = lags(max_idx);
        
        % Ponto inicial preciso
        recorte_start = start_idx + t_lag;
        recorte_end   = recorte_start + recorte_samples - 1;
        
        % Garantir limites
        recorte_start = max(1, recorte_start);
        recorte_end   = min(size(audio_data,2), recorte_end);
        
        % 3. Recortar 50ms em todos os canais
        %final_clip = audio_data(:, recorte_start:recorte_end);
        final_clip = audio_data(best_channel, recorte_start:recorte_end);


        % Salvar ou processar
        fprintf('Arquivo %d, evento %d, recorte: %.2f a %.2f s, channel: %d\n', i, j, recorte_start/Fs, recorte_end/Fs, best_channel);
        % filename_out = sprintf('recorte_file%d_event%d.wav', i, j);
        % audiowrite(filename_out, final_clip', Fs_file);
        filename_out = fullfile(output_folder, sprintf('ball_game3_%04d.wav',count));
        audiowrite(filename_out, final_clip', Fs_file);
        count = count + 1;

    end
end

%% PLOT
% Plot de todos os recortes salvos
recortes_salvos = dir(fullfile(output_folder, '*.wav'));
numPlots = min(10, length(recortes_salvos)); % mostra no máx. 10
for k = 1:numPlots
    figure;
    [y, Fs_plot] = audioread(fullfile(output_folder, recortes_salvos(k).name));
    t = (0:length(y)-1)/Fs_plot;

    plot(t, y);
    grid minor;
    xlabel('Tempo (s)');
    ylabel('Amplitude');
end



