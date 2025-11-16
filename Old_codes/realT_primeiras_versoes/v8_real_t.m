clearvars; 
clc;

% nesta versao foi colocado a funcao de comparacao com um som de referencia
% 
%

% parametros gerais
Fs = 48000;                 % frequencia de amostragem
frame_size = 512;           % tamanho do buffer
op_time = 5;              % tempo de operacao (em segundos)
d = 50;                     % distancia entre microfones (cm)
v = 343;                  % velocidade do som (m/s)
threshold = 1e-6;           % limite para deteccao de impacto
tmp_ball_sound= 40;     %tempo do som da bola em ms
max_deviation= (d/v)*10;    %tempo maximo de desfasamento entre sons (ms)
tmp_analise = tmp_ball_sound + 2*max_deviation; % tempo de analise em ms 
range = ceil(tmp_analise * Fs/1000); % tamanho do frame de analise
   

% configuracao do objeto de captura de audio
mic = audioDeviceReader('Driver', 'ASIO', ...
    'Device', "OCTA-CAPTURE", 'NumChannels', 2, ...
    'SamplesPerFrame', frame_size, ...
    'SampleRate', Fs, ...
    'BitDepth', '24-bit integer');

event_cooldown = tmp_analise;   

% parametros e buffers circulares
buffer_size =  2*range;  %tamanho do buffer circular

if buffer_size < range
    error('buffer circular menor que janela de analise!');
end    


audio_data1 = zeros(1, buffer_size);  %buffer circular do microfone 1
audio_data2 = zeros(1, buffer_size);  %buffer circular do microfone 2
range_init= buffer_size/2 - range/2;    %index do inicio da janela de analise
range_end= buffer_size/2 + range/2; %index do fim da janela de analise

%variaveis de debug
sound_tst1=[];
sound_tst2=[];
mean_Eng=[];
save_count=[];
debug_aux=1;
debug_vector=[];    % aqui guardo as janelas analisadas com eventos
Y=[];
freq=[];
ultra_debug_idx=1;
aux_freq=0;
aux_Y=0;
debug_time=0;


count=0;    %contador geral
skip_analysis=0;     %semaforo 1, caso nao exista info significante para processamento
skip_count=0;   %contador semaforo 1
cooldown_active=0; 
cooldown_end=0;

Eng_med1=0;
eng=zeros(1,range);     %array de energia na janela de analise
eng_div=8;  %numero de divisoes da janela de enegia
eng_r=floor(range/eng_div);    %numero de frames numa divisao
%por causa deste floor posso ter info que nao e analisada!!!!

update_point_1D(0,d,true);  %dar reset ás variaveis internas desta funcao

pause(1);   %necessario colocar porque causava overrun na captacao do som!

numOverrun=0;
totalOverrun=0;
frame_data=zeros(2,frame_size);

%ultrasonic_flag;

p_time=0;

disp('inicio da analise...');
tic;
while p_time < op_time
    p_time=toc;
    % captura um frame de audio
    [frame_data,numOverrun] = mic();   
    
    if isempty(frame_data)
        warning('Frames vazios!');
        continue;
    end
    
    if numOverrun > 0
        totalOverrun = totalOverrun + numOverrun;
        warning(['Overrun detectado! nº: ',num2str(numOverrun)]);
    end

    % escrita no buffer circular
    
    audio_data1=[audio_data1(frame_size+1:end) frame_data(:, 1)'];
    audio_data2=[audio_data2(frame_size+1:end) frame_data(:, 2)'];
    count= count+1;
    
    sound_tst1=[sound_tst1 frame_data(:,1)'];
    sound_tst2=[sound_tst2 frame_data(:,2)'];

    if(count < (range_end/frame_size))    %garantir que existe dados na janela de analise no começo do programa
        continue
    end
    
    if(skip_analysis==0 && cooldown_active==0)
        Eng_med1=mean(audio_data2(range_init:range_end -1).^2);
    
        mean_Eng=[mean_Eng Eng_med1];   %debbuging

        if (Eng_med1 >= threshold)
            Eng_med1
            

            %eng=zeros();
            indx_eng_init=0;
            indx_eng_end=0;    
            for i=1:eng_div
              
                indx_eng_init=(i-1)*(eng_r)+range_init;
                indx_eng_end=i*(eng_r)+range_init;   
                eng(i)=mean(audio_data2(indx_eng_init:indx_eng_end).^2);
            end

            [~,k]=max(eng);
            %k
            if(k>=4)
                continue
            end    
            
            %detecao da componente ultrasonica
            ultra_flag=ultrasonic_comp(audio_data2(range_init:range_end -1),Fs);
            
            if ultra_flag==false
                disp('detecao ignorada por falta de componente ultrasonica');
                skip_analysis=1;  
                debug_time=toc
                continue
            end
            
            %comparacao com som de referencia
            is_ping=check_pingpong(audio_data2(range_init:range_end -1));
            
            if is_ping==false
                disp('detecao ignorada por falta de similaridade com som de bola');
                skip_analysis=1;  
                debug_time=toc
                continue
            end


            pos_sound = calculate_pos_1D(audio_data1, audio_data2, range_init, range_end -1, Fs, v);
            
            debug_vector(debug_aux,:)=audio_data1(range_init:range_end -1);
            debug_vector(debug_aux+1,:)=audio_data2(range_init:range_end -1);
            debug_aux=debug_aux+2;
            save_count=[save_count count];

            % exibir a posicao detectada
            if (abs(pos_sound) <= d/2)

                update_point_1D(pos_sound,d);
                pos_sound
                debug_time=toc

            else
                disp('impacto fora do intervalo esperado.');
                pos_sound
                debug_time=toc
            end
            
            
            atu= buffer_size - range_init;
            atu= ceil(atu/frame_size);
            cooldown_active=1;
            cooldown_end= ceil(count + atu);  
       
        else
            skip_analysis=1;
        end
    else
        % nesta parte do codigo garanto que depois de uma detecao vou ter
        % uma analise so com info nova
        if(cooldown_active==1)
            if(cooldown_end > count)
                continue
            else
                cooldown_active=0;
            end    
        % nesta parte vou saltar iteracoes para poupar processamento e perdas de info e nao repetir analise de dados 
        elseif(skip_analysis==1)
            
            if(skip_count < (range_init)/frame_size)  
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

if totalOverrun > 0
    warning(['Overrun detetado!!! numero total de overrun: ', num2str(totalOverrun)]);
end

% disp('menu de cores:');
% disp('1 -> Vermelho');
% disp('2 -> Verde');
% disp('3 -> Azul');
% disp('4 -> Amarelo');
% disp('5 -> Ciano');
% disp('6 -> Magenta');
% disp('7 -> Cinza');

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

t=linspace(0,5,length(sound_tst1));
figure
plot(t,sound_tst1)
hold on
plot(t,sound_tst2)

%% energy plot

figure
plot(mean_Eng)
