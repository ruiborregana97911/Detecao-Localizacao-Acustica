clearvars; 
clc;

% 
% 
%

% parametros gerais
Fs = 48000;                 % frequencia de amostragem
frame_size = 1024;           % tamanho do buffer
op_time = 5;              % tempo de operacao (em segundos)
d = 50;                     % distancia entre microfones (cm)
v = 343;                  % velocidade do som (m/s)
threshold = 2e-3;           % limite para deteccao de impacto
tmp_ball_sound= 20;     %tempo do som da bola em ms
max_deviation= (d/v)*10;    %tempo maximo de desfasamento entre sons (ms)
smp_dev= ceil(max_deviation*(Fs/1000)); %anterior mas em samples
sample_range = ceil(tmp_ball_sound * Fs/1000); % tamanho da janela de analise

%audio de ref
[ref_audio,~]=audioread("ref_ball_sound.wav");
ref_audio=ref_audio(1:sample_range);    %USAR ISTO PARA COMP O SINAL COM A REF

  
%variaveis
Eng_1=[];
Eng_2=[];
vrf_tm=1;   %1ms
vrf_tm= vrf_tm * 1e-3 * Fs;   %conversao para amostras

mean_eng=[];

last_event=-inf;
present_event=0;
tol_ev= max_deviation*1e-3 + 1e-3;  %tolerancia em segundos (cooldown)


%variaveis de debug
enable_debub= true; 

array_corr=[];
array_lags=[];
k_index=1;

array_sound=[];
debug_aux=1;

%end of debug

%buffer circular
nun_ch = 2;
buff_size= 8192;
buffcir = CircularBuffer(nun_ch, buff_size);

f = parfeval(@capture_audio, 0, buffcir, Fs, frame_size, nun_ch, op_time);


update_point_1D(0,d,true);  %dar reset ás variaveis internas desta funcao

pause(1);   %necessario colocar porque causava overrun na captacao do som!


count=1;

disp('inicio da analise...');

aux=1;
flag1=0;

%t0=tic;
%while toc(t0) < op_time
while (buffcir.getEndWrite == false)
    
    if(buffcir.getAvailableSamples > sample_range)
        audio = buffcir.read(1);
            
        Eng_1(count)=audio(1,count).^2;
        Eng_2(count)=audio(2,count).^2;
        
        %verificacao de energia (pra ja e feita uma analise a cada 1ms)
        if(rem(i,vrf_tm) == 0)
            mean_eng(1,aux)= mean(Eng_1(i-vrf_tm+1:i));
            mean_eng(2,aux)= mean(Eng_2(i-vrf_tm+1:i));
            
            %garantir que temos info para fazer o resto do codigo
            if(aux == 3)    
                flag1=1;
            end
            
            aux=aux+1;
    
            if(flag1 == 0)
                continue
            end
        
            indx=length(mean_eng(1,:)); %index para energia

            for channel= 1:2
                eng= mean_eng(channel,indx);
                eng_prev= mean_eng(channel,indx-1);
                eng_prev2= mean_eng(channel,indx-2);
                
                if(eng > threshold && eng < eng_prev && eng_prev > eng_prev2)
                    
                    %verificacao de cooldown
                    present_event= count/Fs;
                    if(present_event < last_event+tol_ev)
                        continue
                    end
                    
                    disp("evento em: " + num2str(count/Fs,'%.4f') + "s");
    
                    if(count >= sample_range)
                        %init= buffcir.readIndex - sample_range;
                        %fin= ;

                        data= buffcir.peekAroundReadIndex(sample_range,sample_range);
                            
                        if(channel == 1)
                            [c,lags] = xcorr(data(1,:),ref_audio(1:sample_range));
                            [~,max_c]=max(abs(c));
                            t_lag=lags(max_c);
                            
                            init=sample_range-t_lag;
                            fin= sample_range - init;
                            data1 = buffcir.peekAroundReadIndex(init,fin,1);
                            data2 = buffcir.peekAroundReadIndex(init,fin+smp_dev,2);

                            %calculo da distancia e plot    
                            pos_s=calculate_pos_1D_v2(data1, data2, Fs, v);
                        else
                            [c,lags] = xcorr(data(2,:),ref_audio(1:sample_range));
                            [~,max_c]=max(abs(c));
                            t_lag=lags(max_c);
                            
                            init=sample_range-t_lag;
                            fin= sample_range - init;
                            data1 = buffcir.peekAroundReadIndex(init,fin+smp_dev,1);
                            data2 = buffcir.peekAroundReadIndex(init,fin,2);

                            %calculo da distancia e plot    
                            pos_s=calculate_pos_1D_v2(data1, data2, Fs, v);
                        end
                        
                        if (abs(pos_s) <= d/2)
                            update_point_1D(pos_s,d);
                            pos_s
                        else
                            disp('impacto fora do intervalo esperado.');
                            pos_s   
                        end
    
                        if enable_debub
                            %debug vectors
                            array_corr(k_index,:)=c;
                            array_lags(k_index,:)=lags;
                            k_index= k_index+1;
            
                            array_sound(debug_aux,:)=buffcir.peekAroundReadIndex(init,fin+smp_dev,1);
                            debug_aux=debug_aux+1;
                            array_sound(debug_aux,:)=buffcir.peekAroundReadIndex(init,fin+smp_dev,2);
                            debug_aux=debug_aux+1;
                        end
                                
                        last_event= present_event;
                    end   
                end
            end


        end

        
        count= count +1;
    
    else
        %caso a analise seja mais rapido que a captura, dar tempo a captura
        pause(0.005);
    end
end

disp('analise concluida.');

%% sound plot

% figure;
% final_t= length(audio1) / Fs;
% t= linspace(0,final_t,length(audio1));
% plot(t,audio1);
% hold on
% plot(t,audio2);
% grid on
% xlabel("tempo (segundos)");
% title("audio original e deslocado");


%mean eng
figure;
t_e=linspace(0,final_t,length(mean_eng(1,:)));
plot(t_e,mean_eng(1,:));
hold on
plot(t_e,mean_eng(2,:));
grid on
xlabel("tempo (segundos)");
title("energia media");


%correlacao
for i=1:k_index-1
    figure;
    plot(array_lags(i,:), abs(array_corr(i,:)));
    grid on;
end

%windowed sound
j=1;
for i=1:(debug_aux-1)/2
    figure;
    plot(array_sound(j,:));
    j=j+1;
    hold on;
    plot(array_sound(j,:));
    j=j+1;
end



