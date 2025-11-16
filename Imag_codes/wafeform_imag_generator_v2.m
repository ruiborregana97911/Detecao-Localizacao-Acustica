clc; clearvars; close all;

%% ====== 1. WL do impacto da bola ======
[x, Fs] = audioread("Bola/ball_0330.wav");  
x = x(:,1);                     
x = x(1:round(0.05*Fs));       

% Normalizar
x = x / max(abs(x));

% Calcular WL
WL = abs(diff(x));

% Eixo temporal
t = (0:length(x)-1)/Fs*1000; % ms
t_WL = t(2:end);             % WL tem uma amostra a menos

% Plot WL apenas
figure('Position',[100 100 600 400]);
plot(t_WL, WL, 'k', 'LineWidth', 1.2);
xlabel("Tempo [ms]");
ylabel("Incremento absoluto (WL)");
grid on;
title("Waveform Length do impacto da bola");

%% sinal 2
f = 50;                 % frequência da senóide (Hz)
T = 1/f;                % um período completo
t = 0:1/Fs:T;           % vetor temporal (um período)

% Sinal suave (1 período de senóide)
sinal_suave = sin(2*pi*f*t);
sinal_suave = sinal_suave / max(abs(sinal_suave));

% Calcular Waveform Length (WL) total
WL_suave = sum(abs(diff(sinal_suave)));

% Calcular WL acumulada ao longo do tempo (para visualização)
WL_acum = cumsum(abs(diff(sinal_suave)));

% Plot do sinal original
figure('Position',[100 100 800 350]);
subplot(2,1,1);
plot(t*1000, sinal_suave, 'b', 'LineWidth', 1.2);
xlabel('Tempo [ms]');
ylabel('Amplitude Normalizada');
title('Sinal suave – 1 período de senóide');
grid on;

% Plot da WL acumulada
subplot(2,1,2);
plot(t(2:end)*1000, WL_acum, 'r', 'LineWidth', 1.2);
xlabel('Tempo [ms]');
ylabel('WL acumulada');
title(sprintf('Evolução da Waveform Length (WL = %.2f)', WL_suave));
grid on;

sgtitle('Cálculo da Waveform Length para um sinal suave');
