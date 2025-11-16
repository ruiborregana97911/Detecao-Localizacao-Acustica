clc; clear; close all;

% correlacao classica

fs = 100;           % Frequência de amostragem
t = 0:1/fs:0.5;      % Vetor de tempo

% Criar sinal triangular isolado com decaimento exponencial
width = 0.05;  % largura do pico triangular (s)
A=2.5;
sig1 = A .* max(0, 1 - abs(t-0.1)/width) ;  % Triangular centrada em 0.1 s  %.* exp(-5*t)
A=2;
sig2 = A .* max(0, 1 - abs(t-0.2)/width) ; % Triangular deslocada para 0.15 s

% Calcular correlação cruzada
[xc, lags] = xcorr(sig2, sig1);

% Plot da correlação
figure;
plot((lags/fs)*1e3, xc, 'LineWidth', 2);
xlabel('Atraso (ms)');
ylabel('Correlação cruzada');
legend('R_i_j(\tau)')
axis([-50 250 0 18]);

grid on;
% Configurar estilo da grid
ax = gca;                   % pegar no axes atual
ax.GridLineStyle = ':';     % traço tracejado
ax.GridAlpha = 0.25;          % transparência / leveza do traço (0 = invisível, 1 = opaco)
ax.MinorGridAlpha = 0.1;     % se usar minor grid, traço ainda mais leve
ax.LineWidth = 1;            % espessura do eixo (opcional)

%%
%sinais ori
figure;
p1=plot(t*1e3, sig1, 'LineWidth', 2);
hold on;
p2=plot(t*1e3, sig2, 'LineWidth', 2);
xline(100,'k--');
xline(200,'k--');
axis([0 350 0 3]);
hold off;
legend([p1 p2],{'x_i(t)','x_j(t)'});
xlabel('tempo (ms)');
ylabel('Ampitude');

%%

clc; clear; close all;

% Parâmetros
fs = 48000;  % valor default caso o áudio não forneça taxa

% Carregar áudio
[sig1, fs1] = audioread('Bola/ball_0300.wav');  % substitua pelo seu arquivo
%[sig2, fs2] = audioread('Bola/ball_0300.wav');  % pode ser outro arquivo ou mesmo
sig1 = sig1(:,1);           % caso seja estéreo, pega só um canal

delay_sec = 0.002;          % atraso em segundos (2 ms, por exemplo)
delay_samp = round(delay_sec*fs);  % converter para amostras

% criar o segundo sinal atrasado
sig2 = [zeros(delay_samp,1); sig1];    % adiciona zeros no início
sig2 = sig2(1:length(sig1));           % mantém o mesmo tamanho


fs = fs1;

%GCC clássico
[xc, lags] = xcorr(sig2, sig1);

% Plot GCC clássico
figure;
plot(lags/fs*1e3, abs(xc), 'LineWidth', 1.5);
grid on;
xlabel('Lag (ms)');
ylabel('Amplitude');
title('GCC clássico');

% GCC-PHAT usando a função gccphat()
[tau,R,lag] = gccphat(sig1, sig2, fs);  % deve retornar [corr, lags]

% Plot GCC-PHAT
figure;
plot(lag*1e3, abs(R), 'LineWidth', 1.5);
grid on;
xlabel('Lag (ms)');
ylabel('Amplitude');
title('GCC-PHAT');

%som ori
figure;
subplot(1,2,1);
plot(sig1);
subplot(1,2,2);
plot(sig2);

%% versao para gcc phat que vou usar!!

clc; clear; close all;

% Carregar áudio
[sig1, fs] = audioread('extra_files/gravacao_aris_hall_1.wav');

max_t=(length(sig1)/fs) - (1/fs);

t=0:1/fs:max_t;
% 
% figure;
% plot(t,sig1);
% grid minor;

tol= 100 * 1e-3;
init = round(11.94*fs); %inicio do sinal no sinal original
fin = round(init + tol*fs);
val_sig = sig1(init:fin,:);

s1=1;    %canal
s2=3;

max_tval=(length(val_sig)/fs) - (1/fs);

t_val=0:1/fs:max_tval;
figure;
plot(t_val*1e3, val_sig(:,s2));
xlabel('Tempo (ms)'); ylabel('Amplitude');
grid on;
ax = gca; % pega handle do eixo atual
ax.GridLineStyle = ':';       % linhas pontilhadas
ax.GridAlpha = 0.25;           % transparência (0=invisível, 1=opaco)

figure;
plot(t_val*1e3, val_sig(:,s1),'r');
xlabel('Tempo (ms)'); ylabel('Amplitude');
grid on;
ax = gca; % pega handle do eixo atual
ax.GridLineStyle = ':';       % linhas pontilhadas
ax.GridAlpha = 0.25;           % transparência (0=invisível, 1=opaco)

axis([0 100 -0.02 0.02]);

%% repruzir isto so depois de usar a parte de cima!!

%GCC clássico
[xc, lags] = xcorr(val_sig(:,s1), val_sig(:,s2));

% Plot GCC clássico
figure;
plot(lags/fs*1e3, abs(xc),'k','LineWidth', 1);

xlabel('Atraso \tau (ms)');
ylabel('Amplitude');
%max_y= max(abs(xc)) + 0.1*max(abs(xc));
max_y = 3.5e-3;
axis([-5 5  0 max_y]);
         % transparência (0=invisível, 1=opaco)



[tau,R,lag] = gccphat(val_sig(:,s1), val_sig(:,s2), fs);  % deve retornar [corr, lags]

% Plot GCC-PHAT
figure;
plot(lag*1e3, abs(R),'k','LineWidth', 1);

xlabel('Atraso \tau (ms)');
ylabel('Amplitude');
%max_y= max(abs(R)) + 0.1*max(abs(R));
max_y = 0.45;
axis([-5 5  0 max_y]);

