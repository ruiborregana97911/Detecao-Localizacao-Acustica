clearvars; clc;

% parametros gerais
Fs = 48000;                 % frequencia de amostragem
frame_size = 256;           % tamanho do buffer
op_time = 5;              % tempo de operacao (em segundos)
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


color_index = 1; 

event_cooldown = 0.1;
last_event_time = -event_cooldown;




% parametros e buffers circulares
buffer_size =  2*range;  
audio_data1 = zeros(1, buffer_size);  
audio_data2 = zeros(1, buffer_size);  
write_index = 1;  

t_a1=[];
t_a2=[];
debug_eng=[];

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

    t_a1=[t_a1 frame_data(:, 1)'];
    t_a2=[t_a2 frame_data(:, 2)'];

    % escrita no buffer circular
    audio_data1(write_index:write_index+frame_size-1)= frame_data(:, 1)';
    audio_data2(write_index:write_index+frame_size-1)= frame_data(:, 2)';
    write_index= mod(write_index+frame_size-1, buffer_size) + 1;
    
    % reproduzir som do micro
    %sound(frame_data(:, 1)',Fs,24);

    Eng_med1=mean(audio_data2.^2);
    debug_eng=[debug_eng Eng_med1];


    if (Eng_med1 > threshold)
        %Eng_med1

        eng=zeros();
        eng_div=8; % numero de frames para calcular engerfia no buffer
        for i=1:eng_div
            ini_idx= (i-1) * (buffer_size/eng_div) + 1;
            end_idx= ini_idx + (buffer_size/eng_div) - 1;
    
            aux_frame= t_a2(ini_idx:end_idx);
    
            eng(i)= mean(aux_frame.^2);  %media do quadrado das amplitudes

            %eng(i)=mean(audio_data2((i-1)*(buffer_size/eng_div)+1:i*(buffer_size/eng_div)).^2);
        end
            
        [~,k]=max(eng);
        k
        if(k==4 || k==5)
            pos_sound = calculate_pos(audio_data2, audio_data1, buffer_size/4, 3*buffer_size/4 -1, Fs, v);

        else
            %disp('fora do intervalo otimo.');
            %eng
            continue    % vai obter novas amostras caso o evento detetado fora da amotra otima de analise
        end
            
        % exibir a posicao detectada
        % Verifica período de cooldown
         current_time = toc;
            
         % && (current_time - last_event_time >= event_cooldown)
        if (abs(pos_sound) <= d/2 && last_pos ~= pos_sound )
            %color_index= print_color_pos(pos_sound,color_index);
            update_point(pos_sound);
            
            last_event_time = current_time;
            last_pos=pos_sound;
        
        %elseif(last_pos == pos_sound)    
        elseif(abs(pos_sound) > d/2)
            disp('impacto fora do intervalo esperado.');
        end
        
        

    end

end

%% plot energia 
figure;
plot(t_a1);
hold on
plot(t_a2);


wind_size=256;
wind_num=floor(length(t_a2)/wind_size);

Eng_med2=zeros(wind_num,1);
%Eng_med2=zeros(num_frames,1);
for i=1:wind_num
    ini_idx= (i-1) * wind_size + 1;
    end_idx= ini_idx + wind_size - 1;
    
    frame2= t_a2(ini_idx:end_idx);
    
    Eng_med2(i)= mean(frame2.^2);  %media do quadrado das amplitudes 
end    

t_E= (0:wind_num-1) * (wind_size / Fs);  %tempo em segundos

figure;
semilogy(t_E,Eng_med2);
grid on;


figure;
semilogy(debug_eng)

%% funções
disp('analise concluida.');
release(mic);


%---------------------------------------------------------------------------

function color_index = print_color_pos(pos_s, color_index)
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
    
    current_color = color_palette(color_index, :);
    plot(pos_s, 0, 'o', 'MarkerFaceColor', current_color, 'MarkerSize', 8);
    drawnow; % atualizar o grafico em tempo real
    disp(['posicao detectada: ', num2str(pos_s, '%.2f'), ' cm']);
    % atualizar índice de cor
    color_index = mod(color_index, size(color_palette, 1)) + 1;
end

%---------------------------------------------------------------------------

function pos_sound = calculate_pos(audio_data1, audio_data2, start_idx, end_idx, Fs, v)
    [cross_cor, lags] = xcorr(audio_data1(start_idx:end_idx), audio_data2(start_idx:end_idx));
    [~, k] = max(abs(cross_cor));
    delay_time = lags(k) / Fs; % atraso em segundos
    x = v * delay_time;       % diferença de deslocamento
    pos_sound = x / 2;        % posição relativa ao ponto médio
end

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







