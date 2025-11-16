% Script para calcular e ilustrar a frequência de roll-off
clear; close all; clc;

% === Carregar áudio ===
[audio, Fs] = audioread("Bola/ball_0040.wav");


% FFT do áudio
Y = fft(audio);
N = length(Y);
f = (0:N-1)*(Fs/N);            % eixo de frequências
halfRange = 1:floor(N/2);      % frequências até Nyquist
f_half = f(halfRange);

Y_half = Y(halfRange);
magnitude = abs(Y_half);
magnitude_norm = magnitude / max(magnitude);   % normalização

% Parâmetros para detecção de picos
num_peaks = 10;                % número de frequências dominantes a identificar
min_distance_hz = 400;         % distância mínima entre picos em Hz

% Converte distância mínima para número de bins
min_peak_distance_bins = round(min_distance_hz / (Fs/N));

% Encontra picos da FFT
[peaks, locs] = findpeaks(magnitude_norm, 'MinPeakDistance', min_peak_distance_bins);

% Ordena os picos por magnitude decrescente
[~, idx_sorted] = sort(peaks, 'descend');
locs_top = locs(idx_sorted(1:min(num_peaks, length(locs))));
freqs_top = f_half(locs_top);

% Ordena por frequência crescente para visualização
freqs_top_sorted = sort(freqs_top);

% Subset de frequências selecionadas (opcional)
idx_escolhidos = [6 7 8 9 10]; 
freqs_selected = freqs_top_sorted(idx_escolhidos);

% --- Plotagem ---
figure('Color','w','Position',[100 100 1200 350]);
plot(f_half*1e-3, magnitude_norm, 'k', 'LineWidth', 1); hold on;
plot(freqs_top*1e-3, magnitude_norm(locs_top), 'o','MarkerEdgeColor',[0.6 0.6 0.6], 'MarkerFaceColor',[0.8 0.8 0.8], 'MarkerSize',5);

% Destacar subset escolhido
plot(freqs_selected*1e-3, magnitude_norm( arrayfun(@(x) find(f_half==x,1), freqs_selected) ), ...
    's', 'MarkerEdgeColor',[0.7 0.2 0.1], 'MarkerFaceColor',[0.9 0.4 0.2], 'MarkerSize',7);

xlabel('Frequência [Hz]');
ylabel('Magnitude Normalizada');
%title('Frequências Dominantes do Impacto de Bola');
grid minor;
legend('Espectro', 'Picos não selecionados', 'Picos selecionados');
ax = gca;
ax.GridLineStyle = ':';
ax.GridColor = [0.7 0.7 0.7];
ax.GridAlpha = 0.3;
ax.FontSize = 10;

axis([0 24 0 1]);
xticks(0:2:24);
yticks(0:0.2:1);


