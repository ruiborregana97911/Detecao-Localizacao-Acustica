clearvars; 
clc;


% funciona mas so para quando o evento aparece primeiro no audio 1
%

% parametros gerais
Fs = 48000;                 % frequencia de amostragem

[audio1,Fs]=audioread("grav_audio1.wav");    %mudar para o ficheiro final
audio1=audio1';


audio1=audio1(1:48000);

%criacao do segundo audio
tmp= 1;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio2 = circshift(audio1,tmp);

d = 50;                     % distancia entre microfones (cm)
v = 343;                  % velocidade do som (m/s)
threshold = 2e-3;           % limite para deteccao de impacto
tmp_ball_sound= 20;     %tempo do som da bola em ms
max_deviation= (d/v)*10;    %tempo maximo de desfasamento entre sons (ms)
smp_dev= max_deviation*(Fs/1000);
%tmp_analise = tmp_ball_sound + 2*max_deviation; % tempo de analise em ms 
sample_range = ceil(tmp_ball_sound * Fs/1000); % tamanho da janela de analise

%audio de ref
[ref_audio,~]=audioread("ref_ball_sound.wav");
ref_audio=ref_audio(1:sample_range);    %USAR ISTO PARA COMP O SINAL COM A REF

Eng_1=[];
Eng_2=[];
vrf_tm=1;   %1ms
vrf_tm=vrf_tm * 1e-3 * Fs;   %conversao para amostras

mean_eng=[];


%variaveis de debug


update_point_1D(0,d,true);  %dar reset ás variaveis internas desta funcao

pause(1);   %necessario colocar porque causava overrun na captacao do som!


disp('inicio da analise...');

aux=1;
flag1=0;
for i=1:length(audio1) 

    
    Eng_1(i)=audio1(i).^2;
    Eng_2(i)=audio2(i).^2;
    
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
       
        if(mean_eng(1,indx) > threshold && mean_eng(1,indx) < mean_eng(1,indx-1))
            
            if(mean_eng(1,indx-2) > mean_eng(1,indx-1))
                %disp("ignorado por pico de evento recente.");
                continue
            end
            
            disp("evento em: " + num2str(i/Fs,'%.4f') + "s");

            %encontrar o sinal aqui(talvez a correlacao com o sinal de ref???)
            if(i < sample_range)
                [c,lags] = xcorr(audio1(1:i),ref_audio(1:sample_range));
                %neste caso na realidade nao faço nada!
            else
                init=i-sample_range;
                fin=i+sample_range;
                [c,lags] = xcorr(audio1(init:fin),ref_audio(1:sample_range));
                [~,max_c]=max(abs(c));
                t_lag=lags(max_c);
                
%                 figure;
%                 plot(audio1(i-sample_range:i+sample_range));
%                 figure;
%                 plot(audio1(init+t_lag:init+t_lag+sample_range));
                
                %calculo da distancia e plot    
                pos_s=calculate_pos_1D_v2(audio1(init+t_lag:init+t_lag+sample_range),audio2(init+t_lag:init+t_lag+sample_range+max_deviation),Fs,v);

                if (abs(pos_s) <= d/2)
    
                    update_point_1D(pos_s,d);
                    pos_s

                else
                    disp('impacto fora do intervalo esperado.');
                    pos_s
                    
                end
                                    
                            
                
            end
           
 
        end
 
    end
 
end


disp('analise concluida.');


%% sound plot

figure;
final_t= length(audio1) / Fs;
t= linspace(0,final_t,length(audio1));
plot(t,audio1);
hold on
plot(t,audio2);
grid on
xlabel("tempo (segundos)");
title("audio original e deslocado");

% % energy
% figure;
% plot(t,Eng_1);
% hold on
% plot(t,Eng_2);
% grid on
% xlabel("tempo (segundos)");
% title("energia dos sinais")

%mean eng
figure;
t_e=linspace(0,final_t,length(mean_eng(1,:)));
plot(t_e,mean_eng(1,:));
hold on
plot(t_e,mean_eng(2,:));
grid on
xlabel("tempo (segundos)");
title("energia media");

%corelacao da ref
figure
plot(lags,abs(c));
title("corelacao com ref");

