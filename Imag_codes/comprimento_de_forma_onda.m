% === 1. Ler o sinal ===
[x, fs] = audioread('gravacao_aris_hall_3.wav');
x = x(:,1); % usa só 1 canal se for estéreo
x= x(84.7*fs:84.9*fs,:);
t = (0:length(x)-1)/fs;

% === 2. Definir parâmetros ===
win_ms = 5;                  % janela de 5 ms
Nwin = round(win_ms * fs / 1000);
hop = round(Nwin/2);         % avanço de 50%
nFrames = floor((length(x)-Nwin)/hop);

% === 3. Calcular o comprimento da forma de onda (WL) ===
WL = zeros(1, nFrames);
for k = 1:nFrames
    idx = (1:Nwin) + (k-1)*hop;
    seg = x(idx);
    WL(k) = sum(abs(diff(seg)));
end

% === 4. Vetor de tempo para o WL ===
t_WL = ((0:nFrames-1)*hop + Nwin/2)/fs;

% === 5. Normalizar para visualização ===
x_norm = x / max(abs(x));
WL_norm = WL / max(WL);

% === 6. Plot combinado ===
figure('Color','w');
plot(t*1000, x_norm, 'b', 'LineWidth', 1.1); hold on;
plot(t_WL*1000, WL_norm, 'r', 'LineWidth', 1.5);

xlabel('Tempo [ms]', 'FontSize', 11);
ylabel('Amplitude (normalizada)', 'FontSize', 11);
legend({'Sinal','Comprimento da forma de onda (WL)'}, ...
    'Location','northeast','FontSize',10);
%title('Evolução temporal do comprimento da forma de onda', 'FontSize', 12);

% === 7. Melhorias visuais ===
ax = gca;
ax.FontSize = 10;
ax.YLim = [-1.1 1.1];          % ajusta amplitude visível
ax.YTick = -1:0.5:1;           % menos valores no eixo Y
ax.XGrid = 'on';               % grelha vertical suave
ax.YGrid = 'on';
ax.GridAlpha = 0.15;           % grelha mais discreta
ax.LineWidth = 0.8;
axis tight;

box off;                       % remove moldura grossa

% === 8. (opcional) Exportar figura de alta qualidade ===
% exportgraphics(gcf, 'figures/waveform_WL.png', 'Resolution', 300);
