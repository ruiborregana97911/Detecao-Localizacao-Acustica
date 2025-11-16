%% Plot de deteção de energia a partir de um ficheiro WAV
clear; clc; close all;

% === 1. Ler ficheiro de áudio ===
[signal, fs] = audioread('gravacao_aris_hall_2.wav'); % <-- substitui pelo teu ficheiro
signal = signal(:,1); % usa apenas um canal, se houver mais
signal = signal(42.5*fs : 44*fs);

% === 2. Calcular energia por janelas curtas ===
win_ms = 1;                          % janela de 1 ms
win = round(fs * win_ms / 1000);     % tamanho em amostras
num_frames = floor(length(signal)/win);

energia = zeros(num_frames,1);
for i = 1:num_frames
    idx = (i-1)*win + (1:win);
    energia(i) = sum(signal(idx).^2);
end

t_sinal = (0:length(signal)-1)/fs;
t_energia = (0:num_frames-1)*win/fs;

% === 3. Definir limiar de deteção ===
limiar = 6.486e-5;

% === 4. Deteção de picos acima do limiar com período refratário ===
[picos_val, picos_idx] = findpeaks(energia, ...
    'MinPeakHeight', limiar, ...     % apenas picos acima do limiar
    'MinPeakDistance', round(0.05 / (win/fs))); % 50 ms de espaçamento mínimo

t_picos = t_energia(picos_idx);

% === 5. Plot final ===
figure('Position',[100 100 800 500]);

subplot(2,1,1);
plot(t_sinal*1000, signal);
xlabel('Tempo [ms]'); ylabel('Amplitude');
%title('Sinal captado');
grid on;



subplot(2,1,2);
plot(t_energia*1000, energia, 'k'); hold on;
yline(limiar, 'r--');
plot(t_picos*1000, picos_val, 'ro', 'MarkerFaceColor','r');
xlabel('Tempo [ms]'); ylabel('Energia');
%title('Energia do sinal e deteção de picos');
legend('Energia','Limiar','Deteções','Location','best');
grid on;

% === 6. Ajustar estilo de grelha discreto ===
subplots = findobj(gcf, 'Type', 'Axes');
for ax = subplots'
    ax.GridLineStyle = ':';        % linhas pontilhadas
    ax.GridAlpha = 0.3;            % transparência do grid (0–1)
    ax.LineWidth = 1;              % eixos finos
end