%ele faz uma detecao 1D para multiplos eventos

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
rec_time= 4;                    %tempo de gravacao
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


%% fazer o calculo da energia media
wind=Fs/10;
n_block=Fs/wind;

Eng_med1=zeros(num_frames,1);
%Eng_med2=zeros(num_frames,1);
for i=1:n_block
    ini_idx= (i-1) * wind + 1;
    end_idx= ini_idx + wind - 1;
    frame1= audio_data1(ini_idx:end_idx);
 %   frame2= audio_data2(ini_idx:end_idx);
    Eng_med1(i)= mean(frame1.^2);  %media do quadrado das amplitudes 
  %  Eng_med2(i)= mean(frame2.^2);  %media do quadrado das amplitudes 
end    

t_E= (0:n_block-1) * (wind / Fs);  %tempo em segundos

threshold=200e-6;
[pks,locs] = findpeaks(Eng_med1, 'MinPeakHeight', threshold);    %encontra os maximos locais na energia media 

%%

pks_time= t_E(locs);    %valor do tempo dos picos de energia
fr_pk= round(pks_time * Fs);
range= 10000; %tamanho do frame de analise
cross_cor= zeros(2*range+1,length(fr_pk));
lags= zeros(2*range+1,length(fr_pk));
delay_time= zeros(length(fr_pk),1);

for i=1:length(fr_pk)
    if(fr_pk(i)-range/2 < 1)
        [cross_cor(:,i),lags(:,i)]= xcorr(audio_data1(1:range+2),audio_data2(1:range+2));   %faz a correlacao cruzada

    else    
        [cross_cor(:,i),lags(:,i)]= xcorr(audio_data1(fr_pk(i)-range/2:fr_pk(i)+range/2),audio_data2(fr_pk(i)-range/2:fr_pk(i)+range/2));   %faz a correlacao cruzada
    end
    %encontrar o indice de atraso maximo
    [~,k]= max(abs(cross_cor(:,i)));
    %sample_delay= lags(k,i);
    delay_time(i)= lags(k,i)/Fs;
    fprintf('Atraso estimado evento nº %d: %.5f segundos\n', i, delay_time(i));
end    

%calcular posicao do foco de som
d= 50;  %cm
v= 343e2; %velocidade do som em cm/s
%posicoes dos micros
pos_mic1= d/2;
pos_mic2= -d/2;
x= zeros(length(delay_time),1);
pos_sound= zeros(length(delay_time),1);

for i=1:length(delay_time)
    x(i)= (v*delay_time(i));    %diferenca do deslocamento do som
    pos_sound(i)= x(i)/2; %posicao em relacao ao ponto medio
    fprintf('Posição do som nº %d: %.3f cm\n', i, pos_sound(i));
end




%%
%fazer plot da Energia media
figure;
semilogy(t_E,Eng_med1);
hold on;
semilogy(t_E(locs),pks,'*r');
%plot(t_E,Eng_med2);
xlabel('Tempo [s]');
ylabel('Energia Média')
grid on;
legend('canal 1');
hold off;

%% fazer plot posicao

figure;
hold on;
plot([pos_mic1 pos_mic2], [0 0], 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10); % Microfones
for i=1:length(pos_sound)
    plot(pos_sound(i), 0, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 8); % Fonte de som possível
    txt=['p', num2str(i)];
    text(pos_sound(i), 0.1, txt);
end
line([pos_mic1 pos_mic2], [0 0], 'Color', 'b');
grid on;


