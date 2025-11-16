% clc; close all; clearvars;
% 
% [audio, fs] = audioread("Bola\ball_0001.wav");
% 
% % duplicar sinal
% audio_v2 = [audio; audio];
% 
% %% --- Energia média em janelas de 1 ms ---
% Nwin = round(fs/1000);                 % nº de amostras por 1 ms
% numWins = floor(length(audio_v2)/Nwin);
% 
% energia_ms = zeros(numWins,1);
% for k = 1:numWins
%     idx = (k-1)*Nwin+1 : k*Nwin;
%     frame = audio_v2(idx);
%     energia_ms(k) = mean(frame.^2);    % energia média (potência)
% end
% 
% % eixo temporal (em segundos, centro das janelas)
% t_energia = ( (1:numWins)*Nwin - Nwin/2 ) / fs;
% 
% %% --- Correlação cruzada ---
% [xc,lags] = xcorr(audio_v2, audio);
% t_corr = lags/fs;   % converter lags para tempo em segundos
% 
% %% --- Plots ---
% figure;
% subplot(3,1,1);
% plot((1:length(audio_v2))/fs, audio_v2);
% xlabel("Tempo [s]");
% ylabel("Amplitude");
% title("Sinal duplicado (audio\_v2)");
% 
% subplot(3,1,2);
% plot(t_energia, energia_ms, "-o");
% xlabel("Tempo [s]");
% ylabel("Energia média (1 ms)");
% title("Energia média por janela de 1 ms");
% 
% subplot(3,1,3);
% plot(t_corr, xc);
% xlabel("Atraso [s]");
% ylabel("Correlação cruzada");
% title("xcorr(audio\_v2, audio)");
%%

clear; clc; close all;

%% === CONFIGURAÇÃO GERAL ===
% Pasta onde estão os wavs e .mat
pasta = pwd; % ou 'C:\meus_dados\pingpong'
addpath(pasta);

% Lista de ficheiros e parâmetros por ficheiro.
% Para cada ficheiro, defina:
%   wav  - nome do ficheiro .wav
%   lab  - nome do .mat que contém 'eventos' (vector de tempos em s)
%   t_range - [t_start, t_end] em s dentro do wav a analisar (use [0 Inf] para todo)
%   label_shift - (s) adicionar/subtrair a labels (ex.: se recortares audio)
%   min_event_sep - (s) compacta/ignorara eventos que ocorram mais próximos (ex.: 0.05)
%

fileList = [
    struct('wav','gravacao_aris_hall_1.wav','lab','eventos_label_ball_gravacao_aris_hall_1.mat',...
           't_range',[10.3 73],'label_shift',0,'min_event_sep',0.0)
    struct('wav','gravacao_aris_hall_2.wav','lab','eventos_label_ball_gravacao_aris_hall_2.mat',...
           't_range',[10.5 Inf],'label_shift',0,'min_event_sep',0.0)
    struct('wav','gravacao_aris_hall_3.wav','lab','eventos_label_ball_gravacao_aris_hall_3.mat',...
           't_range',[17.2 Inf],'label_shift',0,'min_event_sep',0.0)
    struct('wav','gravacao_aris_hall_4.wav','lab','eventos_label_ball_gravacao_aris_hall_4.mat',...
           't_range',[8.8 Inf],'label_shift',0,'min_event_sep',0.0)
    struct('wav','gravacao_aris_hall_5.wav','lab','eventos_label_ball_gravacao_aris_hall_5.mat',...
           't_range',[12 Inf],'label_shift',0,'min_event_sep',0.0)
    struct('wav','gravacao_aris_hall_6.wav','lab','eventos_label_ball_gravacao_aris_hall_6.mat',...
           't_range',[8.8 Inf],'label_shift',0,'min_event_sep',0.0)
    
           % ... acrescenta as tuas outras entradas ...
];

% Lista de exclusões por ficheiro
exclusoes = [
    struct('idx', [43,44,45]);
    struct('idx', [60,61,62,63]);
    struct('idx', [63,64,65,66,67,68,69,70,71]);
    struct('idx', [27,28,29,30,63,64]);
    struct('idx', [34,35,36,37,76,77,78,79,80,81]);
    struct('idx', [43,44,45,46,47,48,63,64,65,66,67,103,104,105,106,117,118,119,120]);
];

%% === ANÁLISE DE CADÊNCIA DE TOQUE DE BOLA ===

resultados = []; % para guardar resultados por ficheiro

for k = 1:numel(fileList)
    f = fileList(k);
    excl = exclusoes(k).idx;

    fprintf('\n--- Ficheiro %d: %s ---\n', k, f.wav);

    % === Carregar labels (eventos) ===
    dados = load(fullfile(pasta, f.lab)); % deve conter variável "eventos"
    if ~isfield(dados,'eventos')
        warning('Ficheiro %s não contém variável "eventos".', f.lab);
        continue;
    end
    eventos = dados.eventos(:) + f.label_shift; % garantir coluna + aplicar shift

    % === Restringir ao intervalo de interesse ===
    eventos = eventos(eventos >= f.t_range(1) & eventos <= f.t_range(2));

    % === Remover eventos excluídos (índices definidos acima) ===
    if ~isempty(excl) && max(excl) <= numel(eventos)
        eventos(excl) = [];
    end

    % === Compactar eventos muito próximos (opcional) ===
    if f.min_event_sep > 0
        diffs = diff(eventos);
        keep = [true; diffs > f.min_event_sep];
        eventos = eventos(keep);
    end

    % === Calcular diferenças de tempo entre eventos ===
    if numel(eventos) >= 2
        dt = diff(eventos);               % tempo entre toques consecutivos [s]
        cadencia_media = 1 / mean(dt);    % toques por segundo
        fprintf('  Nº de toques: %d\n', numel(eventos));
        fprintf('  Tempo médio entre toques: %.3f s\n', mean(dt));
        fprintf('  Cadência média: %.2f toques/s\n', cadencia_media);

        % Guardar no vetor de resultados
        resultados(k).wav = f.wav;
        resultados(k).num_eventos = numel(eventos);
        resultados(k).tempo_medio = mean(dt);
        resultados(k).cadencia = cadencia_media;
        resultados(k).dt = dt;
    else
        warning('Poucos eventos em %s.', f.wav);
        resultados(k).wav = f.wav;
        resultados(k).num_eventos = numel(eventos);
        resultados(k).tempo_medio = NaN;
        resultados(k).cadencia = NaN;
        resultados(k).dt = [];
    end

    % === Plot dos intervalos (visualização opcional) ===
    figure;
    stem(dt, 'filled');
    xlabel('Índice do intervalo');
    ylabel('Δt [s]');
    title(sprintf('Intervalos entre toques – %s', f.wav), 'Interpreter','none');
    grid on;
end

%% === Resumo geral ===
fprintf('\n===== RESULTADOS GERAIS =====\n');
for k = 1:numel(resultados)
    if isnan(resultados(k).cadencia), continue; end
    fprintf('%-25s  %.2f toques/s (%.3f s entre toques)\n', ...
        resultados(k).wav, resultados(k).cadencia, resultados(k).tempo_medio);
end

% (Opcional) visualizar resumo em tabela
T = struct2table(resultados);
disp(T);


