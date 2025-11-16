% Script para calcular e ilustrar a frequência de roll-off (versão ajustada)
clear; close all; clc;

% === Carregar áudio ===
[x, Fs] = audioread("Bola/ball_0330.wav");
x = x(:,1); % usar apenas um canal, se estéreo

% === FFT e espectro ===
N = length(x);
X = fft(x);
P2 = abs(X/N).^2;          % densidade espectral de potência normalizada
P1 = P2(1:floor(N/2)+1);   % espectro unilateral
f = linspace(0, Fs/2, length(P1)) * 1e-3; % em kHz

% === Energia acumulada ===
energia_total = sum(P1);
energia_acum = cumsum(P1);

% Definir fração de energia (roll-off threshold)
rho = 0.90;

% Encontrar índice de roll-off
idx_rolloff = find(energia_acum >= rho * energia_total, 1, 'first');
f_rolloff = f(idx_rolloff);

% === Plot do espectro com ponto de roll-off ===
figure('Color','w','Position',[100 100 700 400]);

yyaxis left
h1 = plot(f, P1, 'LineWidth', 1.5); hold on;
plot(f_rolloff, P1(idx_rolloff), 'ro', 'MarkerFaceColor','r', 'DisplayName','Roll-off');
xlabel('Frequência [kHz]');
ylabel('Densidade Espectral de Potência');
grid on

ax = gca;
ax.GridLineStyle = ':';
ax.GridColor = [0.6 0.6 0.6];
ax.GridAlpha = 0.3;
ax.FontSize = 10;

yyaxis right
h2 = plot(f, energia_acum/energia_total, 'r--', 'LineWidth', 1.5);
ylabel('Energia acumulada (Normalizada)');
ylim([0 1.05]);

% Linha horizontal do threshold
yline(rho, '--k', '90%', 'LabelHorizontalAlignment','right');

% Linha vertical do roll-off
xline(f_rolloff, '--k');

% Texto informativo do ponto de roll-off
text(f_rolloff + 0.1, P1(idx_rolloff)*1.05, ...
    sprintf('f_{rolloff}'), ...
    'Color','k','FontWeight','bold');


% Legenda
%legend([h1 h2], {'Espectro do sinal','Energia acumulada'}, 'Location','northwest');

axis([0 24 0 1]);
xticks(0:2:24);