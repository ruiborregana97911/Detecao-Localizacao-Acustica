close all;
%% Carregar áudio
[audio, fs] = audioread('Bola/ball_0330.wav');

% Normalizar
audio = audio / max(abs(audio));

% Criar eixo temporal
t = (0:length(audio)-1) / fs;

%% === Figura 1: Forma de onda temporal ===
figure('Color', 'w');
plot(t*1000, audio, 'k', 'LineWidth', 1);
xlabel('Tempo [ms]');
ylabel('Amplitude normalizada');
xlim([0 max(t)*1000+0.05]);
grid on;
box off;

ax = gca; % obter o eixo atual
ax.GridLineStyle = ':';      % tipo de linha (':', '--', '-.', '-')
ax.GridColor = [0.5 0.5 0.5]; % cor RGB (aqui, cinzento)
ax.GridAlpha = 0.4;          % transparência (0 = invisível, 1 = opaco)

%% === Figura 2: Envolvente de energia ===
frameLength = round(0.001 * fs); % janela de 1 ms
energy = movmean(audio.^2, frameLength);
energy = energy / max(energy); % normalizar

figure('Color', 'w');
plot(t*1000, energy, 'k', 'LineWidth', 1);
xlabel('Tempo [ms]');
ylabel('Energia normalizada');
xlim([0 max(t)*1000+0.05]);
grid on;
box off;

ax = gca; % obter o eixo atual
ax.GridLineStyle = ':';      % tipo de linha (':', '--', '-.', '-')
ax.GridColor = [0.5 0.5 0.5]; % cor RGB (aqui, cinzento)
ax.GridAlpha = 0.4;          % transparência (0 = invisível, 1 = opaco)

%% === Figura 3: Espectro ===
NFFT = 2^nextpow2(length(audio));
f = (0:NFFT/2-1) * (fs/NFFT);
S = abs(fft(audio, NFFT));
S = S(1:NFFT/2);
S = S / max(S); % normalizar

figure('Color', 'w');
plot(f/1000, S, 'k', 'LineWidth', 1);
xlabel('Frequência [kHz]');
ylabel('Magnitude normalizada');
xlim([0 fs/2000]);
grid on;
box off;

xticks(0:2:24); % de 0 a 20 kHz

ax = gca; % obter o eixo atual
ax.GridLineStyle = ':';      % tipo de linha (':', '--', '-.', '-')
ax.GridColor = [0.5 0.5 0.5]; % cor RGB (aqui, cinzento)
ax.GridAlpha = 0.4;          % transparência (0 = invisível, 1 = opaco)
