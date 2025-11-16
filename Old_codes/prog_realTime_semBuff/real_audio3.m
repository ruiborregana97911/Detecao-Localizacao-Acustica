clearvars; clc;

% parametros gerais
Fs = 48000;                 % frequencia de amostragem
frame_size = 256;           % tamanho do buffer
op_time = 10;              % tempo de operacao (em segundos)
d = 50;                     % distancia entre microfones (cm)
v = 34300;                  % velocidade do som (cm/s)
threshold = 0.8e-6;           % limite para deteccao de impacto
tmp_analise = 0.083;        % tempo de analise em segundos
range = ceil(tmp_analise * Fs); % tamanho do frame de analise

% colocar o intervalo de analise multiplo do buffer(frame_size)
aux= rem(range,frame_size);
if(aux ~= 0)    
    range= range - aux;
    range= range + frame_size;
end    

% beep
dur=0.25;
t=linspace(0,dur,round(dur*Fs));
y = 0.2*sin(2*pi*440*t);


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

% paleta de cores
color_palette = [
    1, 0, 0;   % vermelho
    0, 1, 0;   % verde
    0, 0, 1;   % azul
    1, 1, 0;   % amarelo
    0, 1, 1;   % ciano
    1, 0, 1;   % magenta
    0.5, 0.5, 0.5; % cinza
];
color_index = 1; 



% parametros e buffers circulares
buffer_size =  2*range;  
audio_data1 = zeros(1, buffer_size);  
audio_data2 = zeros(1, buffer_size);  
write_index = 1;  



disp('inicio da analise...');

last_pos=100;

p_time=0;
tic;
while p_time < op_time
    p_time=toc;
    % captura um frame de audio
    frame_data = mic();   
    
    % escrita no buffer circular
    audio_data1(write_index:write_index+frame_size-1)= frame_data(:, 1)';
    audio_data2(write_index:write_index+frame_size-1)= frame_data(:, 2)';
    write_index= mod(write_index+frame_size-1, buffer_size) + 1;
    
    % reproduzir som do micro
    %sound(frame_data(:, 1)',Fs,24);

    Eng_med1=mean(audio_data2.^2);
        
    if (Eng_med1 > threshold)
        %Eng_med1
        
        eng=zeros();
        for i=1:8
            eng(i)=mean(audio_data2((i-1)*(buffer_size/8)+1:i*(buffer_size/8)).^2);
        end
            
        [~,k]=max(eng);

        if(k==4 || k==5)
            % fazer a correlacao cruzada
            [cross_cor, lags] = xcorr(audio_data1(buffer_size/4:3*buffer_size/4 -1), audio_data2(buffer_size/4:3*buffer_size/4 -1));
            [~, k] = max(abs(cross_cor));
            delay_time = lags(k) / Fs; % atraso em segundos
    
            % calcular a posicao da fonte de som
            x = v * delay_time; % diferenca de deslocamento
            pos_sound = x / 2;  % posicao relativa ao ponto medio
            
            % exibir a posicao detectada
            if (abs(pos_sound) <= d/2 && last_pos ~= pos_sound)
                current_color = color_palette(color_index, :);
                plot(pos_sound, 0, 'o', 'MarkerFaceColor', current_color, 'MarkerSize', 8);
                drawnow; % atualizar o grafico em tempo real
                disp(['posicao detectada: ', num2str(pos_sound, '%.2f'), ' cm']);
                % atualizar índice de cor
                color_index = mod(color_index, size(color_palette, 1)) + 1;
                Eng_med1
                eng
            elseif(last_pos == pos_sound)
            
            else
                disp('impacto fora do intervalo esperado.');
                pos_sound
            end
            last_pos=pos_sound;
        
        elseif(k==3)
            % fazer a correlacao cruzada
            [cross_cor, lags] = xcorr(audio_data1(buffer_size/8:4*buffer_size/8 -1), audio_data2(buffer_size/8:4*buffer_size/8 -1));
            [~, k] = max(abs(cross_cor));
            delay_time = lags(k) / Fs; % atraso em segundos
    
            % calcular a posicao da fonte de som
            x = v * delay_time; % diferenca de deslocamento
            pos_sound = x / 2;  % posicao relativa ao ponto medio
            
            % exibir a posicao detectada
            if (abs(pos_sound) <= d/2 && last_pos ~= pos_sound)
                current_color = color_palette(color_index, :);
                plot(pos_sound, 0, 'o', 'MarkerFaceColor', current_color, 'MarkerSize', 8);
                drawnow; % atualizar o grafico em tempo real
                disp(['posicao detectada: ', num2str(pos_sound, '%.2f'), ' cm']);
                % atualizar índice de cor
                color_index = mod(color_index, size(color_palette, 1)) + 1;
                Eng_med1
                eng
            elseif(last_pos == pos_sound)
            
            else
                disp('impacto fora do intervalo esperado.');
                pos_sound
            end
            last_pos=pos_sound;
        
        
        elseif(k==6)
            % fazer a correlacao cruzada
            [cross_cor, lags] = xcorr(audio_data1(4*buffer_size/8:7*buffer_size/8 -1), audio_data2(4*buffer_size/8:7*buffer_size/8 -1));
            [~, k] = max(abs(cross_cor));
            delay_time = lags(k) / Fs; % atraso em segundos
    
            % calcular a posicao da fonte de som
            x = v * delay_time; % diferenca de deslocamento
            pos_sound = x / 2;  % posicao relativa ao ponto medio
            
            % exibir a posicao detectada
            if (abs(pos_sound) <= d/2 && last_pos ~= pos_sound)
                current_color = color_palette(color_index, :);
                plot(pos_sound, 0, 'o', 'MarkerFaceColor', current_color, 'MarkerSize', 8);
                drawnow; % atualizar o grafico em tempo real
                disp(['posicao detectada: ', num2str(pos_sound, '%.2f'), ' cm']);
                % atualizar índice de cor
                color_index = mod(color_index, size(color_palette, 1)) + 1;
                Eng_med1
                eng
            elseif(last_pos == pos_sound)
            
            else
                disp('impacto fora do intervalo esperado.');
                pos_sound
            end
            last_pos=pos_sound;
        
        
        end
            
    end
end


disp('analise concluida.');
release(mic);


%---------------------------------------------------------------------------





