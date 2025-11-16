clearvars; clc;

% parametros gerais
Fs = 48000;                 % frequencia de amostragem
frame_size = 256;           % tamanho do buffer
op_time = 30;              % tempo de operacao (em segundos)
d = 50;                     % distancia entre microfones (cm)
v = 34300;                  % velocidade do som (cm/s)
threshold = 2e-6;           % limite para deteccao de impacto
tmp_analise = 0.083;        % tempo de analise em segundos
range = ceil(tmp_analise * Fs); % tamanho do frame de analise

% colocar o intervalo de analise multiplo do buffer(frame_size)
aux= rem(range,frame_size);
if(aux ~= 0)    
    range= range - aux;
    range= range + frame_size;
end    

% configuracao do objeto de captura de audio
mic = audioDeviceReader('Driver', 'ASIO', ...
    'Device', "OCTA-CAPTURE", 'NumChannels', 2, ...
    'SamplesPerFrame', frame_size, ...
    'SampleRate', Fs, ...
    'BitDepth', '24-bit integer');

% inicializar graficos para visualizacao
figure;
hold on;
plot([d/2 -d/2], [0 0], 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10); % microfones
line([d/2 -d/2], [0 0], 'Color', 'b');
title('Posicao da fonte de som');
xlabel('Posicao (cm)');
ylabel('Impacto');
grid on;

disp('inicio da analise...');

audio_data1=[];
audio_data2=[];

tic;
while toc < op_time
    % captura um frame de audio
    frame_data = mic();
    audio_data1 = [audio_data1 frame_data(:, 1)'];
    audio_data2 = [audio_data2 frame_data(:, 2)'];

    if(length(audio_data1) == range)

        % calcular energia media
        Eng_med1 = mean(audio_data1.^2);
        
            % verificar se a energia excede o limite (impacto detectado)
            if (Eng_med1 > threshold)
                % fazer a correlacao cruzada
                [cross_cor, lags] = xcorr(audio_data1, audio_data2);
                [~, k] = max(abs(cross_cor));
                delay_time = lags(k) / Fs; % atraso em segundos
        
                % calcular a posicao da fonte de som
                x = v * delay_time; % diferenca de deslocamento
                pos_sound = x / 2;  % posicao relativa ao ponto medio
        
                % exibir a posicao detectada
                if (abs(pos_sound)) <= d/2
                    plot(pos_sound, 0, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 8);
                    drawnow; % atualizar o grafico em tempo real
                    disp(['posicao detectada: ', num2str(pos_sound, '%.2f'), ' cm']);
                else
                    disp('impacto fora do intervalo esperado.');
                end
            end
        
        
        audio_data1= [];
        audio_data2= [];
        
    end
    
end

disp('analise concluida.');
release(mic);





