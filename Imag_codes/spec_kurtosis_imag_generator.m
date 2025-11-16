%% Demonstração de Curtose Espectral com cores académicas e labels em português
fs = 2000;
N = 2048;
freqs = linspace(0, fs/2, N/2);

% --- Funções ---
spectral_centroid = @(P,f) sum(f.*P)/sum(P);
spectral_kurtosis = @(P,f) deal(sum(((f-spectral_centroid(P,f)).^4).* (P/sum(P))) / ...
                                (sum(((f-spectral_centroid(P,f)).^2).* (P/sum(P))).^2), spectral_centroid(P,f));

% --- Sinal 1: impacto (energia concentrada, alta SK) ---
P1 = zeros(1, N/2);

% deslocar o pico para o centro (~500 Hz) e dar-lhe uma largura maior
center = 500 / (fs/2) * (N/2); % índice correspondente a 500 Hz
P1(round(center-3:center+3)) = [0.4 0.7 1 1 0.7 0.4 0.2];  % forma tipo sino
P1 = P1 + 1e-6; 
P1 = P1 / max(P1);

[SK1, fcent1] = spectral_kurtosis(P1, freqs);

figure('Position',[100 100 450 400],'Color','w');
plot(freqs, P1, 'LineWidth', 2, 'Color', [0.85 0.6 0.1]); hold on;
xline(fcent1, '--k', 'LineWidth',1.5);
xlabel('Frequência (Hz)');
ylabel('Densidade espectral de potência');
%title(sprintf('Impacto (alta curtose) - SK = %.2f', SK1));
ylim([0 1.1]); grid on;
ax = gca;
ax.GridLineStyle = ':';
ax.GridColor = [0.6 0.6 0.6];
ax.GridAlpha = 0.3;
ax.FontSize = 10;

% --- Sinal 2: ruído branco (energia dispersa, baixa SK) ---
rng(0);
P2 = rand(1, N/2) + 1e-6;
P2 = P2 / max(P2);
[SK2, fcent2] = spectral_kurtosis(P2, freqs);

figure('Position',[600 100 450 400],'Color','w');
plot(freqs, P2, 'LineWidth', 2, 'Color', [0.85 0.6 0.1]); hold on;
xline(fcent2, '--k', 'LineWidth',1.5);
xlabel('Frequência (Hz)');
ylabel('Densidade espectral de potência');
%title(sprintf('Ruído branco (baixa curtose) - SK = %.2f', SK2));
ylim([0 1.1]); grid on;
ax = gca;
ax.GridLineStyle = ':';
ax.GridColor = [0.6 0.6 0.6];
ax.GridAlpha = 0.3;
ax.FontSize = 10;

