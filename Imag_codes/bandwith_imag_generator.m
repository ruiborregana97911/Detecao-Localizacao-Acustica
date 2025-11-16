%% Demonstração de Largura de Banda Espectral (Spectral Bandwidth)
clear; close all; clc;

fs = 8000;      % frequência de amostragem
N = 2048;
freqs = linspace(0, fs/2, N/2);

% === Espectro 1: pico concentrado (banda estreita) ===
P1 = exp(-0.5*((freqs - 1500)/120).^2);  % gaussiana estreita
P1 = P1 / max(P1);

% === Espectro 2: energia dispersa (banda larga) ===
P2 = exp(-0.5*((freqs - 1500)/500).^2);  % gaussiana larga
P2 = P2 / max(P2);

% === Funções ===
spectral_centroid = @(P,f) sum(f.*P)/sum(P);
spectral_bandwidth = @(P,f) sqrt(sum(((f - spectral_centroid(P,f)).^2).*P)/sum(P));

% === Cálculo dos parâmetros ===
fcent1 = spectral_centroid(P1, freqs);
BW1 = spectral_bandwidth(P1, freqs);

fcent2 = spectral_centroid(P2, freqs);
BW2 = spectral_bandwidth(P2, freqs);

% === Figura 1: Banda estreita ===
figure('Position',[100 100 450 400],'Color','w');
plot(freqs, P1, 'Color',[0.8500 0.3250 0.0980], 'LineWidth',2); hold on;
xline(fcent1,'--k','LineWidth',1.3);
fill([fcent1-BW1, fcent1+BW1, fcent1+BW1, fcent1-BW1],...
     [0 0 0.55 0.55]*max(P1)*0.9, [0.9290 0.6940 0.1250], ...
     'FaceAlpha',0.25, 'EdgeColor','none');
xlabel('Frequência (Hz)'); ylabel('Densidade espectral de potência');
%title(sprintf('Banda estreita — BW = %.0f Hz', BW1));
grid on; box on;
ylim([0 1.05]);
ax = gca; ax.FontSize = 10;
ax.GridLineStyle = ':'; ax.GridColor = [0.6 0.6 0.6]; ax.GridAlpha = 0.3;

% === Figura 2: Banda larga ===
figure('Position',[600 100 450 400],'Color','w');
plot(freqs, P2, 'Color',[0 0.4470 0.7410], 'LineWidth',2); hold on;
xline(fcent2,'--k','LineWidth',1.3);
fill([fcent2-BW2, fcent2+BW2, fcent2+BW2, fcent2-BW2],...
     [0 0 0.55 0.55]*max(P2)*0.9, [0.3010 0.7450 0.9330], ...
     'FaceAlpha',0.25, 'EdgeColor','none');
xlabel('Frequência (Hz)'); ylabel('Densidade espectral de potência');
%title(sprintf('Banda larga — BW = %.0f Hz', BW2));
grid on; box on;
ylim([0 1.05]);
ax = gca; ax.FontSize = 10;
ax.GridLineStyle = ':'; ax.GridColor = [0.6 0.6 0.6]; ax.GridAlpha = 0.3;

