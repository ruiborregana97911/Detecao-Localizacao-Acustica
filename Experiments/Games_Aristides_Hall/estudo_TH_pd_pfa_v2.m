%% === Pd vs Pfa com thresholds de min:step:max (fallback se necessário) ===
clear; clc;clearvars;close all;

%faz estudo pd vs pfa para os files individuais

%% === CONFIGURAÇÃO ===
nome_ficheiro = 'gravacao_aris_hall_6.wav';
load('eventos_label_ball_gravacao_aris_hall_6.mat', 'eventos'); % tempos anotados (s)
eventos_verdadeiros = eventos(:);
tolerancia = 0.015;    % tolerância temporal (s)
energy_win_ms = 1;    % janela de energia (ms)
cooldown_ms = 50;     % cooldown para evitar múltiplos picos (ms)




%% === LEITURA DO ÁUDIO E CALCULO DE ENERGIA MÉDIA POR FRAME ===
[audio, Fs] = audioread(nome_ficheiro);
n_canais = 4;
if size(audio,2) < n_canais
    error('Ficheiro tem menos de %d canais.', n_canais);
end

%audio=audio(1:(73*Fs),:); %aris_1 !!!
%-------------------------------------------------------
%audio=audio((12*Fs):end,:); %aris_5 !!!
%eventos_verdadeiros = eventos_verdadeiros -12; 
%-------------------------------------------------------


cooldown_samples = round((cooldown_ms/1000) * Fs);

energy_win = round((energy_win_ms/1000) * Fs);
num_channels = n_canais;
EngAnl = EnergyTracker(num_channels, energy_win);

n_samples = size(audio, 1);
n_frames = floor(n_samples / energy_win);
mean_eng = zeros(num_channels, n_frames);

for i = 1:n_samples
    current_energy = audio(i,:).^2;       % energia instantânea por canal
    EngAnl.update(current_energy');
    
    % Guardar média móvel a cada frame (window)
    if mod(i, energy_win) == 0
        frame_idx = i / energy_win;
        mean_eng(:, frame_idx) = EngAnl.getAverage();
    end
end

min_eng = min(mean_eng(:));
max_eng = max(mean_eng(:));
fprintf('Energia: min = %.3e, max = %.3e\n', min_eng, max_eng);
% --- modo de gerar thresholds ---

nsteps = 10000;           % usado como fallback/alternativa
thresholds = linspace(min_eng, max_eng, nsteps);
fprintf('Número de thresholds testados: %d\n', numel(thresholds));

%% === LOOP POR CADA THRESHOLD E CÁLCULO Pd / Pfa ===
Pd = zeros(size(thresholds));
Pfa = zeros(size(thresholds));
tempo_total = size(audio,1) / Fs;

for th_i = 1:numel(thresholds)
    threshold = thresholds(th_i);
    eventos_detectados = [];
    last_event = -inf;
    
    % percorre frames (começa em 3 para poder usar frame-1 e frame-2)
    for frame = 3:n_frames
        for channel = 1:n_canais
            eng = mean_eng(channel, frame);
            eng_prev = mean_eng(channel, frame-1);
            eng_prev2 = mean_eng(channel, frame-2);

            if (eng_prev > threshold && eng_prev > eng && eng_prev > eng_prev2)
                peak_position = (frame-1) * energy_win; % amostra do pico
                if (peak_position - last_event < cooldown_samples)
                    continue;
                end
                eventos_detectados(end+1) = peak_position / Fs; %#ok<SAGROW>
                last_event = peak_position;
                break; % queremos o primeiro canal que disparar
            end
        end
    end
    
    % Pd: True positives / total eventos verdadeiros
    tp = 0;
    for ev = eventos_verdadeiros'
        if any(abs(eventos_detectados - ev) <= tolerancia)
            tp = tp + 1;
        end
    end
    Pd(th_i) = tp / numel(eventos_verdadeiros);
    
    % Pfa: falsos positivos por segundo
    fp = 0;
    for det = eventos_detectados
        if ~any(abs(eventos_verdadeiros - det) <= tolerancia)
            fp = fp + 1;
        end
    end
    Pfa(th_i) = fp / tempo_total;
end

%% === PLOTS: Pd vs Threshold, Pfa vs Threshold, Pd vs Pfa (log Pfa) ===
figure('Name','Pd vs Pfa - análise de thresholds','NumberTitle','off');

% Pd vs Threshold
subplot(3,1,1);
plot(thresholds, Pd, 'g','LineWidth',1.2,'MarkerSize',4);
xlabel('Threshold (energia)'); ylabel('Pd');
title('Pd vs Threshold');
grid minor;

% Pfa vs Threshold
subplot(3,1,2);
plot(thresholds, Pfa, 'r','LineWidth',1.2,'MarkerSize',4);
xlabel('Threshold (energia)'); ylabel('Pfa (falsos/s)');
title('Pfa vs Threshold');
grid minor;

subplot(3,1,3);
plot(Pfa, Pd, '-s', 'LineWidth', 1.2, 'MarkerSize', 6);
xlabel('Pfa (falsos por segundo)');
ylabel('Pd');
title('Curva Pd vs Pfa');
grid minor;


% Melhor threshold segundo critério simples (maximizar Pd - Pfa)
[~, best_idx] = max(Pd - Pfa);
fprintf('Melhor threshold (critério Pd - Pfa) = %.3e\n', thresholds(best_idx));
fprintf('Pd = %.3f, Pfa = %.3f falsos/s\n', Pd(best_idx), Pfa(best_idx));

% salvar resultados (opcional)
%save('pd_pfa_results.mat','thresholds','Pd','Pfa','best_idx');

figure;
plot(Pfa, Pd, 'b', 'LineWidth', 2);
hold on;

% Marca o ponto do melhor threshold
plot(Pfa(best_idx), Pd(best_idx), 'ro', 'MarkerSize', 10, 'LineWidth', 2);

xlabel('Probability of False Alarm (Pfa)');
ylabel('Probability of Detection (Pd)');
title('ROC Curve - Pd vs Pfa');
legend('Pd vs Pfa', 'Best Threshold', 'Location', 'SouthEast');
grid on;
box on;
axis([0 1 0 1]); % escala entre 0 e 1 para ambos

hold off;