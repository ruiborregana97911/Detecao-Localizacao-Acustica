clearvars;
clc;

% Parâmetros gerais
Fs = 48000;                 % Frequência de amostragem
frame_size = 256;           % Tamanho do buffer
op_time = 2;                % Tempo de operação (segundos)

% Configuração do objeto de captura de áudio
mic = audioDeviceReader('Driver', 'ASIO', ...
    'Device', "OCTA-CAPTURE", 'NumChannels', 4, ...
    'SamplesPerFrame', frame_size, ...
    'SampleRate', Fs, ...
    'BitDepth', '24-bit integer');

% Inicializa variável para armazenar os dados
audio_data = []; 

disp('Início da gravação...');

tic
while toc < op_time
    frame_data = mic(); % Captura um frame de áudio
    audio_data = [audio_data frame_data']; % Armazena canal 1
end

disp('Fim da gravação!');

release(mic);


% % Salvar áudio em um arquivo .wav
% filename = 'audio_tst/grav_audio_tst1.wav';
% audiowrite(filename, audio_data, Fs);
% disp(['Áudio salvo como: ', filename]);
% 

%% leitura e analise dos ficheiros

% % Ler o arquivo de áudio multicanal
% [audio_data, Fs] = audioread('audio_tst/grav_audio_tst1.wav');
% 
% % Verificar se tem 4 canais
 [num_channels, num_samples] = size(audio_data);
% if num_channels ~= 4
%     error('O arquivo não tem 4 canais. Encontrados: %d', num_channels);
% end

% Separar os canais
canal1 = audio_data(1, :);
canal2 = audio_data(2, :);
canal3 = audio_data(3, :);
canal4 = audio_data(4, :);

% % Opcional: mostrar duração e gráficos
% disp(['Número de amostras: ', num2str(num_samples)]);
% disp(['Frequência de amostragem: ', num2str(Fs), ' Hz']);

% Plot (opcional)
t = (0:num_samples-1) / Fs;
figure;
subplot(4,1,1); plot(t, canal1); title('Canal 1'); xlabel('Tempo (s)');
subplot(4,1,2); plot(t, canal2); title('Canal 2'); xlabel('Tempo (s)');
subplot(4,1,3); plot(t, canal3); title('Canal 3'); xlabel('Tempo (s)');
subplot(4,1,4); plot(t, canal4); title('Canal 4'); xlabel('Tempo (s)');



