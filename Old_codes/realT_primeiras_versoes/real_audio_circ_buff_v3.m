clearvars; 
clc;

% depois de varias horas perdidas percebi que o buffer circular esta mal
% feito!!!!!!!!
%

% parametros gerais
Fs = 48000;                 % frequencia de amostragem
frame_size = 256;           % tamanho do buffer
op_time = 5;              % tempo de operacao (em segundos)
d = 50;                     % distancia entre microfones (cm)
v = 34300;                  % velocidade do som (cm/s)
threshold = 9e-8;           % limite para deteccao de impacto
tmp_analise = 83;        % tempo de analise em ms
range = ceil(tmp_analise * Fs/1000); % tamanho do frame de analise

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


sound_tst1=[];
sound_tst2=[];
mean_Eng=[];
save_count=[];

disp('inicio da analise...');

last_pos=100;

count=0;    %contador geral
skip_analysis=0;     %semaforo 1, caso nao exista info significante para processamento
skip_count=0;   %contador semaforo 1
cooldown_active=0; 
cooldown_end=0;

debug_aux=1;
debug_vector=[];

update_point(0, true);  %dar reset as variaveis internas desta funcao
numOverrun=0;

p_time=0;
tic;
while p_time < op_time
    p_time=toc;
    % captura um frame de audio
    [frame_data,numOverrun] = mic();   
    
    if isempty(frame_data)
        continue; % pular iteração se os dados forem inválidos
    end


    % escrita no buffer circular
    audio_data1(write_index:write_index+frame_size-1)= frame_data(:, 1)';
    audio_data2(write_index:write_index+frame_size-1)= frame_data(:, 2)';
    write_index= mod(write_index+frame_size-1, buffer_size) + 1;
    count= count+1;
    
    sound_tst1=[sound_tst1 frame_data(:,1)'];
    sound_tst2=[sound_tst2 frame_data(:,2)'];

    if(count < ((3*buffer_size)/(4*frame_size)))    %garantir que comeco a analise com buffer com dados ate 3/4 do buffer
        continue
    end
    
    if(skip_analysis==0 && cooldown_active==0)
    Eng_med1=mean(audio_data2(buffer_size/4:3*buffer_size/4 -1).^2);
    
    mean_Eng=[mean_Eng Eng_med1];   %debbuging

        if (Eng_med1 >= threshold)
            Eng_med1
            
            
            eng=zeros();
            indx_eng_init=0;
            indx_eng_end=0;    
            for i=1:8
              
                indx_eng_init=(i-1)*(range/8)+buffer_size/4;
                indx_eng_end=i*(range/8)+buffer_size/4;   
                eng(i)=mean(audio_data2(indx_eng_init:indx_eng_end).^2);
            end

            [~,k]=max(eng);
    
            r=buffer_size/4 + (k*frame_size) - frame_size/2; %identificador do centro de maxima energia
            init= (r - range/4); %identificador inicial
            fin= (r + 3*range/4) -1; %identificador final     
            
            pos_sound = calculate_pos(audio_data1, audio_data2, init, fin, Fs, v);
            
            debug_vector(debug_aux,:)=audio_data1(init:fin);
            debug_vector(debug_aux+1,:)=audio_data2(init:fin);
            debug_aux=debug_aux+2;
            save_count=[save_count count];

            % exibir a posicao detectada
            if (abs(pos_sound) <= d/2)

                update_point(pos_sound);
                pos_sound

            else
                disp('impacto fora do intervalo esperado.');
                pos_sound
            end
            
            %atu= (3*buffer_size/4 -1) - init;
            atu= buffer_size - init;
            atu= ceil(atu/frame_size);
            cooldown_active=1
            cooldown_end= ceil(count + atu);  
       
        else
            skip_analysis=1;
        end
    else
        
        if(cooldown_active==1)
            if(cooldown_end > count)
                continue
            else
                cooldown_active=0
            end    

        elseif(skip_analysis==1)
            
            if(skip_count < (buffer_size/2)/frame_size)  %vou saltar 8 iteracoes para poupar processamento e perdas de info e nao repetir analise de dados
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

disp('menu de cores:');
disp('1 -> Vermelho');
disp('2 -> Verde');
disp('3 -> Azul');
disp('4 -> Amarelo');
disp('5 -> Ciano');
disp('6 -> Magenta');
disp('7 -> Cinza');

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

%% sound plot

figure
plot(sound_tst1)
hold on
plot(sound_tst2)

%% energy plot

figure
plot(mean_Eng)


%% functions

%---------------------------------------------------------------------------
function update_point(pos_s, reset)
    persistent positions colors color_palette
    
    if nargin > 1 && reset
        % Redefinir variáveis persistentes
        positions = [];
        colors = [];
        color_palette = [];
        return; % Termina a execução da função
    end

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




