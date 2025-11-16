% primeiro programa que usa o ASIO driver para 1 canal
clearvars;clc;

%inicializa os parametros de gravacao
Fs= 192000;                 %frequencia de amostragem
frame_size= 1024;           %tamanho do buffer
%configurar objeto de leitura
mic= audioDeviceReader('Driver','ASIO', ...
    'Device',"OCTA-CAPTURE",'SamplesPerFrame',frame_size, ...
    'SampleRate',Fs, ...
    'BitDepth','24-bit integer');

%configuracao da gravacao
rec_time= 4;
total_samples= Fs * rec_time; 
audio_data= zeros(total_samples, 1);
num_frames= total_samples/mic.SamplesPerFrame;  %numeros de frames a captar
num_frames=floor(num_frames);   %arredondar para -inf
index= 1;
elapsed_time=0;

disp('Gravando áudio...');

%inicia a gravacao
tic
for i=1:num_frames 
    frame_data= mic();  %captura de um frame de audio
    audio_data(index:index+mic.SamplesPerFrame-1)= frame_data;   %colocar no array completo do audio 
    index= index + mic.SamplesPerFrame; %atualizar o index
end

elapsed_time= toc;  %fim da medicao de tempo
disp('Gravação concluída');
disp(['Gravação concluída em ', num2str(elapsed_time), 'segundos']);

release(mic)


%% fazer plot do audio
figure(1);
t = linspace(0, rec_time, length(audio_data));  %vetor de tempo
plot(t,audio_data);
xlabel('Tempo [s]');
ylabel('Amplitude')
grid on;

%fazer plot da Energia
figure(2);
Eng1= (audio_data).^2;
plot(t,Eng1);
xlabel('Tempo [s]');
ylabel('Energia')
grid on;

%fazer o calculo da energia media
Eng_med=zeros(num_frames,1);
for i=1:num_frames
    ini_idx= (i-1) * frame_size + 1;
    end_idx= ini_idx + frame_size - 1;
    frame= audio_data(ini_idx:end_idx);
    Eng_med(i)= mean(frame.^2);  %media do quadrado das amplitudes 
end    

threshold=0.5e-5;
[pks,locs] = findpeaks(Eng_med, 'MinPeakHeight', threshold);    %encontra os maximos locais na energia media 



t_E= (0:num_frames-1) * (frame_size / Fs);  %tempo em segundos

%fazer plot da Energia media
figure(3);
plot(t_E,Eng_med);
hold on;
plot(t_E(locs),pks,'*r');
xlabel('Tempo [s]');
ylabel('Energia Média')
grid on;











