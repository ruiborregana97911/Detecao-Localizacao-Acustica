clearvars;
clc;
%prog para corte automatico do som de uma bola


%% PARÂMETROS GERAIS
Fs = 48000;             % Frequência de amostragem
frame_len = 256;        % Tamanho do frame
op_time = 10;           % Tempo de gravação (segundos)
num_channels = 4;       % Número de canais
min_peak_energy = 0.005; % Limiar de energia (ajuste conforme necessário)
pre_frames = 2;         % Frames antes do pico
post_frames = 5;        % Frames após o pico

%% CONFIGURAR OBJETO DE LEITURA
mic = audioDeviceReader('Driver', 'ASIO', ...
    'Device', "OCTA-CAPTURE", 'NumChannels', num_channels, ...
    'SamplesPerFrame', frame_len, ...
    'SampleRate', Fs);

disp('Gravando áudio contínuo...');
audio_data = [];
tic
while toc < op_time
    frame = mic();
    audio_data = [audio_data; frame];
end
release(mic);
disp('Gravação encerrada!');

%% SALVAR ÁUDIO COMPLETO
audiowrite('pingpong_raw.wav', audio_data, Fs);
disp('Áudio completo salvo: pingpong_raw.wav');

%% CÁLCULO DE ENERGIA (usando Canal 1)
num_frames = floor(size(audio_data,1) / frame_len);
energy = zeros(num_frames,1);
for i = 1:num_frames
    frame = audio_data((i-1)*frame_len+1:i*frame_len, 1);
    energy(i) = mean(frame.^2);
end

%% DETECÇÃO DE PICOS DE ENERGIA
[~, locs] = findpeaks(energy, ...
    'MinPeakHeight', min_peak_energy, ...
    'MinPeakDistance', 10);  % em número de frames

disp(['Impactos detectados: ', num2str(length(locs))]);

%% EXTRAÇÃO E VISUALIZAÇÃO DOS EVENTOS
mkdir('recortes');

for i = 1:length(locs)
    idx_start = max(1, (locs(i)-pre_frames)*frame_len + 1);
    idx_end   = min(size(audio_data,1), (locs(i)+post_frames)*frame_len);

    snippet = audio_data(idx_start:idx_end, :);
    t = (0:size(snippet,1)-1)/Fs;

    % Plot dos 4 canais
    figure('Name', sprintf('Impacto %d', i), 'NumberTitle', 'off');
    for ch = 1:4
        subplot(4,1,ch);
        plot(t, snippet(:,ch));
        title(['Canal ', num2str(ch)]);
        xlabel('Tempo (s)');
    end

    % Salvar o trecho em arquivo
    filename = sprintf('recortes/impacto_%03d.wav', i);
    audiowrite(filename, snippet, Fs);
    disp(['Salvo: ', filename]);
end

% Plot geral da energia
figure;
plot((0:num_frames-1)*(frame_len/Fs), energy);
xlabel('Tempo (s)');
ylabel('Energia');
title('Energia ao longo do tempo (Canal 1)');
