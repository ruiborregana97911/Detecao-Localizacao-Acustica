clearvars; clc;

% parametros gerais
Fs = 48000;                 % frequencia de amostragem
frame_size = 256;           % tamanho do buffer
op_time = 15;              % tempo de operacao (em segundos)
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


event_cooldown = tmp_analise;
last_event_time = 0;


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
    
    if isempty(frame_data)
        continue; % pular iteração se os dados forem inválidos
    end


    % escrita no buffer circular
    audio_data1(write_index:write_index+frame_size-1)= frame_data(:, 1)';
    audio_data2(write_index:write_index+frame_size-1)= frame_data(:, 2)';
    write_index= mod(write_index+frame_size-1, buffer_size) + 1;
    
    % reproduzir som do micro
    %sound(frame_data(:, 1)',Fs,24);

    Eng_med1=mean(audio_data2.^2);
        
    if (Eng_med1 > threshold)
        %Eng_med1
        
        % Verifica período de cooldown
        current_time = toc;
        if (current_time - last_event_time < event_cooldown)
            continue; % ignora detecções repetidas
        end



        eng=zeros();
        for i=1:8
            eng(i)=mean(audio_data2((i-1)*(buffer_size/8)+1:i*(buffer_size/8)).^2);
        end
            
        [~,k]=max(eng);

        if(k==4 || k==5)

            pos_sound = calculate_pos(audio_data1, audio_data2, buffer_size/4, 3*buffer_size/4 -1, Fs, v);

            
            % exibir a posicao detectada
            if (abs(pos_sound) <= d/2 && last_pos ~= pos_sound)
                %color_index= print_color_pos(pos_sound,color_index);
                update_point(pos_sound);
                Eng_med1
                eng
            %elseif(last_pos == pos_sound)
            
            else
                disp('impacto fora do intervalo esperado.');
                pos_sound
            end
            last_pos=pos_sound;
            last_event_time = current_time;
        
        elseif(k==3)
           
            pos_sound = calculate_pos(audio_data1, audio_data2, buffer_size/8, 4*buffer_size/8 -1, Fs, v);

            % exibir a posicao detectada
            if (abs(pos_sound) <= d/2 && last_pos ~= pos_sound)
                %color_index= print_color_pos(pos_sound,color_index);
                update_point(pos_sound);
                Eng_med1
                eng
            %elseif(last_pos == pos_sound)
            
            else
                disp('impacto fora do intervalo esperado.');
                pos_sound
            end
            last_pos=pos_sound;
            last_event_time = current_time;
        
        
        elseif(k==6)
         
            pos_sound = calculate_pos(audio_data1, audio_data2, 4*buffer_size/8, 7*buffer_size/8 -1, Fs, v);

            % exibir a posicao detectada
            if (abs(pos_sound) <= d/2 && last_pos ~= pos_sound)
                %color_index= print_color_pos(pos_sound,color_index);
                update_point(pos_sound);
                Eng_med1
                eng
            %elseif(last_pos == pos_sound)
            
            else
                disp('impacto fora do intervalo esperado.');
                pos_sound
            end
            last_pos=pos_sound;
            last_event_time = current_time;
        
        
        end
            
    end
end


disp('analise concluida.');
release(mic);


%---------------------------------------------------------------------------
function update_point(pos_s)
    persistent positions colors color_palette
    
    % Definir número máximo de pontos e cores
    max_points = 7;  
    if isempty(color_palette)
        color_palette = [
            1, 0, 0;   % vermelho
            0, 1, 0;   % verde
            0, 0, 1;   % azul
            1, 1, 0;   % amarelo
            0, 1, 1;   % ciano
            1, 0, 1;   % magenta
            0.5, 0.5, 0.5; % cinza
        ];
    end
    
    % Inicializar cores e posições
    if isempty(positions)
        positions = [];
        colors = [];
    end
    
    % Adicionar nova posição e cor
    if length(positions) < max_points
        positions = [positions, pos_s];
        colors = [colors; color_palette(length(positions), :)];
    else
        % Substituir o ponto mais antigo
        positions = [positions(2:end), pos_s];
        colors = [colors(2:end, :); colors(1, :)];
    end
    
    % Limpar e redesenhar todos os pontos
    cla; % Limpar gráfico atual
    hold on;
    plot([25 -25], [0 0], 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10); % Microfones
    line([25 -25], [0 0], 'Color', 'b'); % Linha dos microfones
    for i = 1:length(positions)
        plot(positions(i), 0, 'o', 'MarkerFaceColor', colors(i, :), 'MarkerSize', 8);
    end
    drawnow; % Atualizar o gráfico
end



%---------------------------------------------------------------------------

function pos_sound = calculate_pos(audio_data1, audio_data2, start_idx, end_idx, Fs, v)
    [cross_cor, lags] = xcorr(audio_data1(start_idx:end_idx), audio_data2(start_idx:end_idx));
    [~, k] = max(abs(cross_cor));
    delay_time = lags(k) / Fs; % atraso em segundos
    x = v * delay_time;       % diferença de deslocamento
    pos_sound = x / 2;        % posição relativa ao ponto médio
end


