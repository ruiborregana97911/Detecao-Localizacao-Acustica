clear; clc;

%% === CONFIGURAÇÕES ===
nome_ficheiro = 'gravacao_aris_hall_1.wav';
load('eventos_label_ball_gravacao_aris_hall_1', 'eventos'); % tempos anotados manualmente (segundos)
eventos_verdadeiros = eventos; 
tolerancia = 5e-3; % tolerância em segundos
energy_win_ms = 1; % janela de energia
cooldown_ms = 50;  % tempo mínimo entre eventos
thresholds = logspace(-6, -2, 30); % faixa de thresholds para teste (ajuste conforme os valores da energia)

%% === LER ÁUDIO ===
[audio, Fs] = audioread(nome_ficheiro);
n_canais = 4;
if size(audio,2) < n_canais
    error('Ficheiro tem menos de 4 canais.');
end

energy_win = round((energy_win_ms/1000) * Fs);
cooldown_samples = round((cooldown_ms/1000) * Fs);

% === Calcular energia média a cada 1ms ===
n_frames = floor(size(audio,1)/energy_win);
mean_eng = zeros(n_canais, n_frames);
for c = 1:n_canais
    sig = audio(:,c).^2;
    sig = reshape(sig(1:n_frames*energy_win), energy_win, n_frames);
    mean_eng(c,:) = mean(sig,1);
end

%% === Análise Pd vs Pfa ===
Pd = zeros(size(thresholds));
Pfa = zeros(size(thresholds));

for th_i = 1:length(thresholds)
    threshold = thresholds(th_i);
    eventos_detectados = [];
    last_event = -inf;
    
    for frame = 3:n_frames
        for channel = 1:n_canais
            eng = mean_eng(channel, frame);
            eng_prev = mean_eng(channel, frame-1);
            eng_prev2 = mean_eng(channel, frame-2);

            if (eng_prev > threshold && eng_prev > eng && eng_prev > eng_prev2)
                peak_position = (frame-1) * energy_win; % amostra no pico
                if (peak_position - last_event < cooldown_samples)
                    continue;
                end
                eventos_detectados(end+1) = peak_position/Fs;
                last_event = peak_position;
                break; % só considera o primeiro canal que disparar
            end
        end
    end
    
    % === Calcular Pd e Pfa ===
    % Pd: quantos eventos verdadeiros foram detectados
    tp = 0;
    for ev = eventos_verdadeiros(:)'
        if any(abs(eventos_detectados - ev) <= tolerancia)
            tp = tp + 1;
        end
    end
    Pd(th_i) = tp / numel(eventos_verdadeiros);
    
    % Pfa: eventos detectados que não correspondem a nenhum verdadeiro
    fp = 0;
    for det = eventos_detectados
        if ~any(abs(eventos_verdadeiros - det) <= tolerancia)
            fp = fp + 1;
        end
    end
    tempo_total = size(audio,1) / Fs;
    Pfa(th_i) = fp / tempo_total; % falsos por segundo
end

%% === PLOT Pd vs Pfa ===
figure;
plot(Pfa, Pd, 'o-');
xlabel('Pfa (falsos por segundo)');
ylabel('Pd (probabilidade de detecção)');
title('Curva Pd vs Pfa para diferentes thresholds');
grid on;

% Mostrar melhor threshold (exemplo: maximiza Pd - Pfa)
[~, best_idx] = max(Pd - Pfa);
fprintf('Melhor threshold = %.6f\n', thresholds(best_idx));
fprintf('Pd = %.3f, Pfa = %.3f falsos/s\n', Pd(best_idx), Pfa(best_idx));
