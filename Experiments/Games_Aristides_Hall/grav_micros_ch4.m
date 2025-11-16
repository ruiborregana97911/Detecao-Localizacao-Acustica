clearvars;
clc;
close all;

% --- Parâmetros gerais ---
Fs = 48000;                 % Frequência de amostragem
frame_size = 1024;          % Tamanho do buffer (em amostras)
op_time =90;               % Tempo total de gravação (segundos)
num_channels = 4;           % Número de canais (microfones)

% --- Configuração do objeto de captura ---
mic = audioDeviceReader('Driver', 'ASIO', ...
    'Device', "OCTA-CAPTURE", ...
    'NumChannels', num_channels, ...
    'SamplesPerFrame', frame_size, ...
    'SampleRate', Fs, ...
    'BitDepth', '24-bit integer');

% --- Inicializa variável para guardar os dados ---
%audio_data = zeros(0, num_channels);
total_samples = round(Fs * op_time);
audio_data = zeros(total_samples, num_channels);  % pré-alocação eficiente
totalOverrun = 0;

disp('Início da gravação...');
max_count = ceil((op_time * Fs) / frame_size);
count_time = 0;
tic

% --- Loop de gravação ---
while toc < op_time
    [frame_data, numOverrun] = mic(); % Captura um frame de todos os canais
    audio_data = [audio_data; frame_data]; %#ok<AGROW>

    count_time = count_time + 1;

    if numOverrun > 0
        totalOverrun = totalOverrun + numOverrun;
        actual_time = (op_time * count_time) / max_count;
        warning(['Overrun detectado! nº: ', num2str(numOverrun)]);
        fprintf("Tempo estimado do overrun: %.2f s\n", actual_time);
    end
end

disp('Fim da gravação!');
release(mic);

% --- Salvar áudio multicanal ---
filename = 'gravacao_aris_hall_1.wav';
audiowrite(filename, audio_data, Fs);
disp(['Áudio salvo como: ', filename]);

% --- Plot opcional dos canais ---
t = (0:size(audio_data,1)-1)/Fs;
figure;
for ch = 1:num_channels
    subplot(num_channels,1,ch);
    plot(t, audio_data(:,ch));
    title(['Canal ', num2str(ch)]);
    xlabel('Tempo [s]');
end

%%

clearvars;
clc;
close all;

% --- Parâmetros gerais ---
Fs = 48000;                 % Frequência de amostragem
frame_size = 1024;          % Tamanho do buffer
op_time = 90;               % Tempo total de gravação (s)
num_channels = 4;           % Número de microfones

% --- Inicialização do dispositivo de gravação ---
mic = audioDeviceReader('Driver', 'ASIO', ...
    'Device', "OCTA-CAPTURE", ...
    'NumChannels', num_channels, ...
    'SamplesPerFrame', frame_size, ...
    'SampleRate', Fs, ...
    'BitDepth', '24-bit integer');

% --- Pré-alocação da matriz de áudio ---
total_samples = round(Fs * op_time);
audio_data = zeros(total_samples, num_channels);  % pré-alocação
totalOverrun = 0;

disp('Início da gravação...');
current_sample = 1;
tic

while toc < op_time
    [frame_data, numOverrun] = mic();  % Lê bloco de dados
    samples_this_frame = size(frame_data, 1);

    % Protege contra extrapolação do vetor pré-alocado
    if current_sample + samples_this_frame - 1 > total_samples
        samples_this_frame = total_samples - current_sample + 1;
        frame_data = frame_data(1:samples_this_frame, :);
    end

    % Armazena os dados no local apropriado
    audio_data(current_sample:current_sample + samples_this_frame - 1, :) = frame_data;
    current_sample = current_sample + samples_this_frame;

    % Detecção de overrun
    if numOverrun > 0
        totalOverrun = totalOverrun + numOverrun;
        fprintf("Overrun detectado! Nº: %d | Tempo: %.2f s\n", numOverrun, toc);
    end
end

disp('Fim da gravação!');
release(mic);

% --- Salvar arquivo .wav multicanal ---
filename = 'gravacao_aris_hall_6.wav';
audiowrite(filename, audio_data, Fs);
disp(['Áudio salvo como: ', filename]);






%% 
% --- Nome do ficheiro .wav com vários canais ---
filename = 'gravacao_aris_hall_6.wav';

% --- Leitura do ficheiro ---
[audio_data, Fs] = audioread(filename);  % audio_data será uma matriz N x C
[num_samples, num_channels] = size(audio_data);

fprintf('Áudio carregado com %d canais, %d amostras, Fs = %d Hz\n', ...
        num_channels, num_samples, Fs);

% --- Eixo do tempo (para plot) ---
t = (0:num_samples - 1) / Fs;

% --- Plot dos canais ---
figure;
for ch = 1:num_channels
    subplot(num_channels, 1, ch);
    plot(t, audio_data(:, ch));
    title(['Canal ', num2str(ch)]);
    xlabel('Tempo [s]');
    ylabel('Amplitude');
end
sgtitle('Sinais dos Microfones');

% --- Acesso individual aos canais (se quiseres processar separadamente) ---
canal1 = audio_data(:, 1);
canal2 = audio_data(:, 2);
canal3 = audio_data(:, 3);
canal4 = audio_data(:, 4);

% Exemplo: calcular duração total
duracao = num_samples / Fs;
fprintf('Duração total: %.2f segundos\n', duracao);








