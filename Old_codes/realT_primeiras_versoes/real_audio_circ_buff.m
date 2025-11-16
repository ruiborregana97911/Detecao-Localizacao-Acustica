clearvars; 
clc;

% acho que neste o buffer de analise seja muito grande, e nao sei porque
% ele repete uma analise que nao devia existir, acho que e provavel que o
% meu semaforo de cooldown nao esta a funcionar corretamente
%
%

% parametros gerais
Fs = 48000;                 % frequencia de amostragem
frame_size = 256;           % tamanho do buffer
op_time = 5;              % tempo de operacao (em segundos)
d = 50;                     % distancia entre microfones (cm)
v = 34300;                  % velocidade do som (cm/s)
threshold = 1e-6;           % limite para deteccao de impacto
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


sound_tst=[];

disp('inicio da analise...');

last_pos=100;

count=0;    %contador geral
skip_analysis=0;     %semaforo 1, caso nao haja info significante para processamento
skip_count=0;   %contador semaforo 1
cooldown_active=0; 
cooldown_end=0;

debug_aux=1;
debug_vector=[];

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
    count= count+1;
    sound_tst=[sound_tst frame_data(:,2)'];

    if(count < 24)
        continue
    end
    
    if(skip_analysis==0 && cooldown_active==0)
    Eng_med1=mean(audio_data2(buffer_size/4:3*buffer_size/4 -1).^2);
        
        if (Eng_med1 > threshold)
            Eng_med1
            
            
            eng=zeros();
            for i=1:8
                eng(i)=mean(audio_data2((i-1)*(buffer_size/8)+1:i*(buffer_size/8)).^2);
            end
                
            [~,k]=max(eng);
    
            r=2048+(k*512)-256; %identificador do centro de maxima energia
            init= (r-2048); %identificador inicial
            fin= (r+2048) -1; %identificador final     
            
            pos_sound = calculate_pos(audio_data1, audio_data2, init, fin, Fs, v);
            
            debug_vector(debug_aux,:)=audio_data1(init:fin);
            debug_vector(debug_aux+1,:)=audio_data2(init:fin);
            debug_aux=debug_aux+2;

            % exibir a posicao detectada
            if (abs(pos_sound) <= d/2)

                update_point(pos_sound);
                pos_sound

            else
                disp('impacto fora do intervalo esperado.');
                pos_sound
            end
            
            atu= (3*buffer_size/4 -1) - init;
            atu= atu/256;
            cooldown_active=1;
            cooldown_end= ceil(count + atu);
       
        else
            skip_analysis=1;
        end
    else
        
        if(cooldown_active==1)
            if(cooldown_end > count)
                continue
            else
                cooldown_active=0;
            end    

        else
            
            if(skip_count < 16)  %vou saltar 16 iteracoes para poupar processamento e perdas de info e nao repetir analise de dados
                skip_count=skip_count + 1;
                continue
            else
                %reset das variaveis
                skip_count=0;
                skip_analysis=0;
            end
        end
    end
end


disp('analise concluida.');
release(mic);




%% debug plot

j=1;
for i=1:debug_aux/2

    figure;
    plot(debug_vector(j,:));
    hold on;
    j=j+1;
    plot(debug_vector(j,:));
    j=j+1;
end    


%% functions

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



