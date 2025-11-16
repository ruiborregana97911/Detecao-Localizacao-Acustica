clear; close all; clc;

Fs = 1000;                 % frequência de amostragem
t = linspace(0,1,Fs);      % vetor temporal

%% --- Gerar sinais com diferentes skewness ---
half_sine = sin(pi*t);     % meia-senoide

% Skewness positiva (cauda longa à direita)
decay_pos = exp(-5*t);
x_pos = half_sine .* decay_pos;
x_pos = x_pos / max(abs(x_pos));

% Skewness negativa (cauda longa à esquerda)
decay_neg = exp(-5*(1-t));
x_neg = half_sine .* decay_neg;
x_neg = x_neg / max(abs(x_neg));

% Skewness nula (simétrica)
x_zero = half_sine;
x_zero = x_zero / max(abs(x_zero));

%% --- Configurações de plot ---
fontName = 'Arial'; fontSize = 12;
w = 350; h = 350;
y_limits = [-0.1 1.1];

mid_t = 500; % posição central (ms)

%% --- Plot Skewness positiva ---
figure('Position',[100 100 w h],'Color','w');
plot(t*1000, x_pos,'Color',[0.3 0.6 0.9],'LineWidth',1.5); hold on;
xline(t(mid_t)*1000,'--k');
xlabel('Tempo'); ylabel('Amplitude');
xlim([0 1000]); ylim(y_limits);
set(gca,'FontName',fontName,'FontSize',fontSize);

%% --- Plot Skewness negativa ---
figure('Position',[150 150 w h],'Color','w');
plot(t*1000, x_neg,'Color',[0.9 0.4 0.4],'LineWidth',1.5); hold on;
xline(t(mid_t)*1000,'--k');
xlabel('Tempo'); ylabel('Amplitude');
xlim([0 1000]); ylim(y_limits);
set(gca,'FontName',fontName,'FontSize',fontSize);

%% --- Plot Skewness nula ---
figure('Position',[200 200 w h],'Color','w');
plot(t*1000, x_zero,'Color',[0.4 0.9 0.4],'LineWidth',1.5); hold on;
xline(t(mid_t)*1000,'--k');
xlabel('Tempo'); ylabel('Amplitude');
xlim([0 1000]); ylim(y_limits);
set(gca,'FontName',fontName,'FontSize',fontSize);
