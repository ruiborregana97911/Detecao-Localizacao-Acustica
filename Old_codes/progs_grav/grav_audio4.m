%programa para leitura de dois canais com o ASIO
%ele faz uma detecao 1D para um so evento, para multiplos ele mostra o
%evento com maior valor na corelacao cruzada, pois estou a fazer a
%corelacao cruzada do sinal todo, sem detecao de eventos distintos
clearvars;clc;

%inicializa os parametros de gravacao
Fs= 192000;                 %frequencia de amostragem
frame_size= 1024;           %tamanho do buffer
%configurar objeto de leitura
mic= audioDeviceReader('Driver','ASIO', ...
    'Device',"OCTA-CAPTURE",'NumChannels',2, ...
    'SamplesPerFrame',frame_size, ...
    'SampleRate',Fs, ...
    'BitDepth','24-bit integer');

%configuracao da gravacao
rec_time= 2;                    %tempo de gravacao
total_samples= Fs * rec_time; 
audio_data1= zeros(total_samples, 1);
audio_data2= zeros(total_samples, 1);
num_frames= total_samples/mic.SamplesPerFrame;  %numeros de frames a captar
num_frames=floor(num_frames);   %arredondar para -inf
index= 1;
elapsed_time=0;

disp('Gravando áudio...');

%inicia a gravacao
tic
for i=1:num_frames 
    frame_data= mic();  %captura de um frame de audio
    audio_data1(index:index+mic.SamplesPerFrame-1)= frame_data(:,1);   %colocar no array completo do audio 
    audio_data2(index:index+mic.SamplesPerFrame-1)= frame_data(:,2);    
    index= index + mic.SamplesPerFrame; %atualizar o index
end

elapsed_time= toc;  %fim da medicao de tempo
disp('Gravação concluída');
disp(['Gravação concluída em ', num2str(elapsed_time), 'segundos']);

release(mic)

[cross_cor,lags]= xcorr(audio_data1,audio_data2);   %faz a correlacao cruzada

%encontrar o indice de atraso maximo
[~,k]= max(abs(cross_cor));
sample_delay= lags(k);
delay_time= lags(k)/Fs;
fprintf('Atraso estimado: %.5f segundos\n', delay_time);

%calcular posicao do foco de som
d= 50;  %cm
v= 343e2; %velocidade do som em m/s

x= (v*delay_time);    %diferenca do deslocamento do som

%posicoes dos micros e do foco de som
pos_mic1= d/2;
pos_mic2= -d/2;
pos_sound= x/2; %posicao em relacao ao ponto medio
fprintf('Posição do som: %.3f cm\n', pos_sound);

%% fazer plot do audio
figure(1);
t = linspace(0, rec_time, length(audio_data1));  %vetor de tempo
plot(t,audio_data1);
xlabel('Tempo [s]');
ylabel('Amplitude')
grid on;
hold on;
plot(t,audio_data2);
legend('canal 1','canal 2');

%% fazer plot correlacao cruzada
figure(2);
plot(lags/Fs,cross_cor)
xlabel('Tempo [s]');
ylabel('Correlação Cruzada')
grid on;

%% fazer plot posicao

figure(4);
hold on;
plot([pos_mic1 pos_mic2], [0 0], 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10); % Microfones
plot(pos_sound, 0, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 8); % Fonte de som possível
line([pos_mic1 pos_sound], [0 0], 'Color', 'b', 'LineStyle', '--'); % Linha mic1-fonte
line([pos_mic2 pos_sound], [0 0], 'Color', 'r', 'LineStyle', '--'); % Linha mic2-fonte



%% fazer o calculo da energia media
Eng_med1=zeros(num_frames,1);
Eng_med2=zeros(num_frames,1);
for i=1:num_frames
    ini_idx= (i-1) * frame_size + 1;
    end_idx= ini_idx + frame_size - 1;
    frame1= audio_data1(ini_idx:end_idx);
    frame2= audio_data2(ini_idx:end_idx);
    Eng_med1(i)= mean(frame1.^2);  %media do quadrado das amplitudes 
    Eng_med2(i)= mean(frame2.^2);  %media do quadrado das amplitudes 
end    

t_E= (0:num_frames-1) * (frame_size / Fs);  %tempo em segundos

%fazer plot da Energia media
figure(3);
plot(t_E,Eng_med1);
hold on;
plot(t_E,Eng_med2);
xlabel('Tempo [s]');
ylabel('Energia Média')
grid on;
legend('canal 1','canal 2');














