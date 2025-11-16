% --- Cálculo e visualização da Razão entre Picos (Peak Ratio) ---

% Carregar áudio (impacto isolado)
[x, Fs] = audioread("Bola/ball_0330.wav");

% Converter para mono se for estéreo
if size(x,2) > 1
    x = x(:,1);
end

% Valor absoluto e normalização
x_abs = abs(x);
x_abs = x_abs / max(x_abs);

% Encontrar dois maiores picos
[sortedPeaks, sortedIdx] = sort(x_abs, 'descend');
P1 = sortedPeaks(1);
P2 = sortedPeaks(2);
idx1 = sortedIdx(1);
idx2 = sortedIdx(2);

% Calcular razão entre picos
peak_ratio = P1 / P2;
disp(['Peak Ratio = ' num2str(peak_ratio)]);

% Vetor temporal
t = (0:length(x_abs)-1)/Fs * 1000; % tempo em ms

% --- Plot ---
figure('Position',[100 100 800 350]);
plot(t, x_abs, 'Color',[0 0.45 0.74], 'LineWidth', 1.3); hold on;

% Marcar os picos
plot(t(idx1), P1, 'ro', 'MarkerFaceColor','r', 'MarkerSize',7);
plot(t(idx2), P2, 'go', 'MarkerFaceColor','g', 'MarkerSize',7);

% Legenda minimalista
legend({'$|x(n)|$','Pico principal $P_1$','Segundo pico $P_2$'}, ...
       'Interpreter','latex','Location','northeast','Box','off','FontSize',10);

% Anotações diretas
text(t(idx1), P1+0.05, '$P_1$', 'Interpreter','latex', 'Color','r', 'FontSize',12);
text(t(idx2), P2+0.05, '$P_2$', 'Interpreter','latex', 'Color','g', 'FontSize',12);

xlabel('Tempo [ms]','FontSize',11);
ylabel('Amplitude normalizada $|x(n)|$','Interpreter','latex','FontSize',11);

grid on;
ax = gca;
ax.GridLineStyle = ':';
ax.GridColor = [0.6 0.6 0.6];
ax.GridAlpha = 0.3;
ax.FontSize = 10;

axis tight;
