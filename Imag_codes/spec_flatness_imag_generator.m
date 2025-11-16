%% Exemplo ilustrativo de Spectral Flatness
clear; close all; clc;

% === Carregar áudio de impacto ===
[audio, Fs] = audioread("Bola/ball_0330.wav");
audio = audio(:,1);                      % Usar apenas um canal
audio = audio(1:round(0.05*Fs));         % 50 ms para visualização

% === Gerar sinal de ruído branco ===
t = (0:length(audio)-1)/Fs;
noise_signal = randn(size(t));           % Ruído branco
tone = 0.1*sin(2*pi*500*t);             % Pequeno componente tonal
adjusted_noise = noise_signal + tone;   % Mistura

% === Lista de sinais e legendas ===
signals = {audio, adjusted_noise};
labels = {'Impacto da bola', 'Ruído branco'};
colors = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980]};

for i = 1:2
    x = signals{i};
    N = length(x);

    % FFT e potência espectral
    X = fft(x);
    P = abs(X(1:floor(N/2))).^2;
    P_norm = P / max(P);

    % Calcular Spectral Flatness
    mean_arith = mean(P_norm);
    mean_geom = exp(mean(log(P_norm + eps)));
    SF = mean_geom / mean_arith;

    % === Plot ===
    figure('Position',[100 100 450 400],'Color','w');

    bar(P_norm, 'FaceColor', colors{i}, 'EdgeColor','none');
    xlabel('Bin de frequência');
    ylabel('Densidade espectral de potência (normalizada)');
    %title(sprintf('%s  (SF = %.3f)', labels{i}, SF));
    grid on; 
    ax = gca;
    ax.GridLineStyle = ':';
    ax.GridColor = [0.6 0.6 0.6];
    ax.GridAlpha = 0.3;
    ax.FontSize = 10;

    box off;
    axis([0 1200 0 1]);
    xticks(0:200:1200);
    yticks(0:0.2:1);

end
