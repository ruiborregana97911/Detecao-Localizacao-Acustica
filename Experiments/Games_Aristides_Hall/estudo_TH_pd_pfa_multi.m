%% estudo_pd_pfa_multifiles.m
% Estudo Pd vs Pfa combinado para vários ficheiros .wav + .mat de labels.
% Usa EnergyTracker para calcular energia média móvel (mesma lógica do realtime).
% Permite configurar intervalo por ficheiro, shift nas labels e remoção de eventos
% muito próximos (min_event_sep) para ignorar toques secundários.

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

% Parâmetros do detector / estudo
energy_win_ms = 1;    % janela média móvel (ms)
cooldown_ms = 50;     % cooldown entre eventos (ms)
tolerancia = 25e-3;   % tolerância temporal para casar deteções com labels (s)
n_thresholds = 10000;  % número de thresholds (linspace) - podes aumentar
global_thresholds = true; % true -> thresholds definidos por min/max global; false -> por ficheiro
verbose = true;
usarExclusoes = true; % <-- mudar para false para usar todos os eventos(rede!)

%% === PROCESSAR CADA FICHEIRO: calcular mean_eng por frame e carregar labels ===
nFiles = numel(fileList);
fileData = struct(); % guardamos info por ficheiro

for f = 1:nFiles
    cfg = fileList(f);
    wavpath = fullfile(pasta, cfg.wav);
    labpath = fullfile(pasta, cfg.lab);
    if verbose, fprintf('-> Processando %s\n', cfg.wav); end

    % ler audio
    if ~isfile(wavpath), error('WAV não encontrado: %s', wavpath); end
    [audio, Fs] = audioread(wavpath);
    n_channels = size(audio,2);
    if n_channels < 4
        warning('Ficheiro %s tem %d canais (esperado 4). Usando %d canais.', cfg.wav, n_channels, n_channels);
    end

    % cortar pelo intervalo pedido
    t_start = max(0, cfg.t_range(1));
    t_end = cfg.t_range(2);
    if isinf(t_end), t_end = size(audio,1)/Fs; end
    samp_start = max(1, floor(t_start*Fs)+1);
    samp_end = min(size(audio,1), ceil(t_end*Fs));
    audio_cut = audio(samp_start:samp_end, :);

    % carregar labels
    if ~isfile(labpath)
        warning('Labels não encontradas para %s: %s. Mantendo labels vazias.', cfg.wav, cfg.lab);
        eventos = [];
    else
        S = load(labpath);
        if isfield(S,'eventos')
            eventos = S.eventos(:);
        else
            % tenta extrair primeira variável vetorial
            fn = fieldnames(S);
            found = false;
            for k=1:numel(fn)
                v = S.(fn{k});
                if isnumeric(v) && isvector(v)
                    eventos = v(:); found = true; break;
                end
            end
            if ~found
                eventos = [];
                warning('Não encontrei vetor "eventos" no %s. Deixando vazio.', cfg.lab);
            end
        end
    end

    % ajustar labels: shift e recortar para o intervalo analisado
    eventos = eventos + cfg.label_shift;
    eventos = eventos(eventos >= t_start & eventos <= t_end);
    % ajustar para tempo relativo à audio_cut (subtrair t_start)
    eventos = eventos - t_start;

    % filtrar eventos muito próximos (manter apenas primeiro de cada cluster)
    if ~isempty(eventos) && cfg.min_event_sep > 0
        eventos = sort(eventos(:));
        kept = eventos(1);
        for k = 2:numel(eventos)
            if eventos(k) - kept(end) >= cfg.min_event_sep
                kept(end+1,1) = eventos(k); %#ok<SAGROW>
            end
        end
        eventos = kept;
    end
    
    % excluir sons marcados nos eventos
    if usarExclusoes && ~isempty(eventos)
        exc= exclusoes(f);
        for k = length(exc.idx) :-1:1 %for tem de ser invertido!!!
            %fprintf('\n%f\n',length(eventos));
            eventos(exc.idx(k)) = []; 
        end
    end

    % calcular energia média por frame usando EnergyTracker (amostra-a-amostra)
    energy_win = round((energy_win_ms/1000) * Fs);
    EngAnl = EnergyTracker(n_channels, energy_win);
    n_samples = size(audio_cut,1);
    n_frames = floor(n_samples / energy_win);
    mean_eng = zeros(n_channels, n_frames);

    frame_idx = 0;
    for ii = 1:n_samples
        current_energy = audio_cut(ii,:).^2;
        EngAnl.update(current_energy(:));
        if mod(ii, energy_win) == 0
            frame_idx = frame_idx + 1;
            mean_eng(:, frame_idx) = EngAnl.getAverage();
        end
    end

    % Guardar tudo
    fileData(f).name = cfg.wav;
    fileData(f).Fs = Fs;
    fileData(f).n_channels = n_channels;
    fileData(f).mean_eng = mean_eng;    % n_channels x n_frames
    fileData(f).n_frames = n_frames;
    fileData(f).audio_seconds = n_samples / Fs;
    fileData(f).eventos = eventos;      % tempos relativos ao início do corte [s]
    fileData(f).t_start = t_start;
    fileData(f).t_end = t_end;
    fileData(f).energy_win = energy_win;
    fileData(f).cooldown_samples = round((cooldown_ms/1000) * Fs);

    if verbose
        fprintf('  frames=%d, duração=%.2fs, eventos anotados=%d\n', n_frames, fileData(f).audio_seconds, numel(eventos));
    end
end

%% === DETERMINAR THRESHOLDS (GLOBAL OU POR FICHEIRO) ===
if global_thresholds
    all_min = inf; all_max = -inf;
    for f = 1:nFiles
        all_min = min(all_min, min(fileData(f).mean_eng(:)));
        all_max = max(all_max, max(fileData(f).mean_eng(:)));
    end
    th_min = all_min; th_max = all_max;
    thresholds = linspace(th_min, th_max, n_thresholds);
    if verbose, fprintf('Thresholds globais: min=%.3e max=%.3e (%d pontos)\n',th_min, th_max, numel(thresholds)); end
else
    % alternativa: poderia criar thresholds por ficheiro (não implementado aqui por simplicidade)
    error('opção global_thresholds=false não implementada nesta versão.');
end

%% === LOOP PARA CALCULAR Pd e Pfa COMBINADOS EM TODOS OS FICHEIROS ===
Pd = zeros(size(thresholds));
Pfa = zeros(size(thresholds));

total_events_all = sum(arrayfun(@(x) numel(x.eventos), fileData));
total_duration_all = sum([fileData.audio_seconds]);

if total_events_all == 0
    error('Não há eventos anotados em nenhum ficheiro. Verifica os .mat');
end

if verbose, fprintf('Executando sweep de thresholds e calculando Pd/Pfa combinados...\n'); end

for t_i = 1:numel(thresholds)
    th = thresholds(t_i);
    tp_tot = 0;
    fp_tot = 0;

    for f = 1:nFiles
        data = fileData(f);
        mean_eng = data.mean_eng;
        n_frames = data.n_frames;
        Fs_f = data.Fs;
        cooldown_samples = data.cooldown_samples;
        eventos_verd = data.eventos(:)';
        detections = []; % times em s relativos ao inicio do ficheiro cortado

        last_event = -inf;
        for frame = 3:n_frames
            triggered = false;
            for c = 1:data.n_channels
                eng = mean_eng(c, frame);
                eng_prev = mean_eng(c, frame-1);
                eng_prev2 = mean_eng(c, frame-2);
                if (eng_prev > th && eng_prev > eng && eng_prev > eng_prev2)
                    peak_position = (frame-1) * data.energy_win; % em amostras relativas ao ficheiro
                    if (peak_position - last_event < cooldown_samples)
                        triggered = true; % ignora, mas faz break p/ next frame
                        break;
                    end
                    detections(end+1) = peak_position / Fs_f; %#ok<SAGROW> % segundos
                    last_event = peak_position;
                    triggered = true;
                    break; % só primeiro canal a detetar!
                end
            end
            % continua para próximo frame
        end
       
        % calcular TP por ficheiro (cada evento verdadeiro contado no máximo 1x)
        tp_f = 0;
        for ev = eventos_verd
            if any(abs(detections - ev) <= tolerancia)
                tp_f = tp_f + 1;
            end
        end

        % calcular FP: detecções que não mapeiam para nenhum evento verdadeiro
        fp_f = 0;
        for d = detections
            if ~any(abs(eventos_verd - d) <= tolerancia)
                fp_f = fp_f + 1;
            end
        end

        tp_tot = tp_tot + tp_f;
        fp_tot = fp_tot + fp_f;
    end

    Pd(t_i) = tp_tot / total_events_all;
    Pfa(t_i) = fp_tot / total_duration_all; % falsos por segundo (todos os ficheiros)
    if verbose && mod(t_i, round(numel(thresholds)/10))==0
        fprintf('  progresso: %.1f%%\n', 100*t_i/numel(thresholds));
    end
end

%% === Encontrar thresholds ótimos com vários critérios ===

disp('-----------------------------------------------------------------------');

% 1) Critério simples: maximizar Pd - Pfa
crit1 = Pd - Pfa;
[~, idx1] = max(crit1);
th1 = thresholds(idx1);
fprintf('Critério Pd - Pfa:\n  Threshold = %.3e, Pd = %.3f, Pfa = %.3f falsos/s\n', ...
    th1, Pd(idx1), Pfa(idx1));

% 2) Critério ponderado: maximizar Pd - alpha*Pfa
alpha = 1.5; % ajustável
crit2 = Pd - alpha*Pfa;
[~, idx2] = max(crit2);
th2 = thresholds(idx2);
fprintf('Critério Pd - alpha*Pfa (alpha=%.1f):\n  Threshold = %.3e, Pd = %.3f, Pfa = %.3f falsos/s\n', ...
    alpha, th2, Pd(idx2), Pfa(idx2));

% 3) Critério com limite máximo de falsos positivos
Pfa_max = 0.4; % falsos/s
valid = Pfa <= Pfa_max;
if any(valid)
    [~, best_idx] = max(Pd(valid));
    idx_valid = find(valid);
    th3 = thresholds(idx_valid(best_idx));
    fprintf('Critério Pd máximo com Pfa <= %.2f:\n  Threshold = %.3e, Pd = %.3f, Pfa = %.3f falsos/s\n', ...
        Pfa_max, th3, Pd(idx_valid(best_idx)), Pfa(idx_valid(best_idx)));
else
    warning('Nenhum threshold cumpre o limite de Pfa definido (%.2f).', Pfa_max);
end

% 4) Critério de mínima distância ao ponto ideal (Pd=1, Pfa=0)
dist = sqrt((1 - Pd).^2 + Pfa.^2);
[~, idx4] = min(dist);
th4 = thresholds(idx4);
fprintf('Critério distância ao ponto ideal (Pd=1,Pfa=0):\n  Threshold = %.3e, Pd = %.3f, Pfa = %.3f falsos/s\n', ...
    th4, Pd(idx4), Pfa(idx4));

disp('-----------------------------------------------------------------------');

%% === PLOTS ===

figure('Name','Pd/Pfa - Multi-file study','NumberTitle','off','Units','normalized','Position',[0.1 0.1 0.7 0.7]);

subplot(3,1,1);
plot(thresholds, Pd, 'b-', 'LineWidth', 1.5); hold on;
xline(th1, '--k');
xlabel('Limiar (energia)'); ylabel('Pd');  grid minor;
ax = gca;
ax.GridAlpha = 1;             % transparência (0 = invisível, 1 = opaco)
ax.MinorGridAlpha = 0.25;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
legend('Pd vs Limiar','Limiar de Energia');

yticks(0:0.2:1);
xlim([0 5e-4]);
hold off;

subplot(3,1,2);
plot(thresholds, Pfa, 'r-', 'LineWidth', 1.5); hold on;
xline(th1, '--k');
xlabel('Limiar (energia)'); ylabel('Pfa (falsos/s)'); grid minor;
ax = gca;
ax.GridAlpha = 1;             % transparência (0 = invisível, 1 = opaco)
ax.MinorGridAlpha = 0.25;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
legend('Pfa vs Limiar','Limiar de Energia');

xlim([0 1e-4]);
ylim([0 1.5]);
hold off;

subplot(3,1,3);
plot(Pfa, Pd, 'k-', 'LineWidth', 1.5); hold on;
plot(Pfa(idx1), Pd(idx1), 'ro', 'MarkerSize',8,'LineWidth',1.6);
xlabel('Pfa (falsos por segundo)'); ylabel('Pd');  grid minor;
ax = gca;
ax.GridAlpha = 1;             % transparência (0 = invisível, 1 = opaco)
ax.MinorGridAlpha = 0.25;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';
legend('curva ROC','Ponto Óptimo');


xlim([0 0.4]);
yticks(0:0.2:1);
hold off;

