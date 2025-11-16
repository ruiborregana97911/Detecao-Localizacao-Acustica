% --- Comparação da Waveform Length (WL) entre impacto e sinal suave ---

clear; clc; close all;

% ====== 1. Carregar impacto real ======
[x, Fs] = audioread("Bola/ball_0100.wav");  
x = x(:,1); % usar só 1 canal se for estéreo
x = x(1:round(0.05*Fs)); % usar apenas primeiros 50 ms para visualização

% Normalizar
x = x / max(abs(x));

% ====== 2. Criar sinal sinusoidal de mesma duração ======
t = (0:length(x)-1)/Fs;
sine = sin(2*pi*25*t); % 1 kHz senoide
sine = sine / max(abs(sine));

% ====== 3. Calcular Waveform Length (WL) ======
WL_impacto = sum(abs(diff(x)));
WL_sine = sum(abs(diff(sine)));

% --- Impacto da bola ---
figure('Position',[100 100 600 400]);
plot(t*1000, x, 'k', 'LineWidth', 1.5);
xlabel("Tempo [ms]");
ylabel("Amplitude Normalizada");
title(sprintf("Impacto da bola (WL = %.2f)", WL_impacto));
grid on;
axis([0 t(end)*1000+0.05 -1 1]); % mesmo eixo Y para consistência
%set(gca,'FontName','Times New Roman');

% Exportar como PNG ou SVG para LaTeX
% saveas(gcf,'waveform_impacto.png');

% --- Senoide ---
figure('Position',[100 100 600 400]);
plot(t*1000, sine, 'b', 'LineWidth', 1.5);
xlabel("Tempo [ms]");
ylabel("Amplitude Normalizada");
title(sprintf("Senoide 1 kHz (WL = %.2f)", WL_sine));
grid on;
axis([0 t(end)*1000+0.05 -1 1]); % mesmo eixo Y
%set(gca,'FontName','Times New Roman');

% Exportar como PNG ou SVG para LaTeX
% saveas(gcf,'waveform_senoide.png');
