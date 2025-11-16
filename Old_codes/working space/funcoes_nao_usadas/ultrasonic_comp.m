% ULTRASONIC_COMP --> Deteta se existe componente ultrasonica num audio 
%
% Sintaxe:
%   ultrasonic_comp(audio_data, Fs)
%   
% Entradas:
%   audio_data  - dados de audio
%   Fs - frequência de amostragem dos dados
%   
%
% Saídas:
%   ultra_flag - Booleano de detecao de componete ultrasonica
%
% Esta função deteta a presenca significativa de componente acima dos 15KHz
% por base do calculo da fft do sinal de audio
%  
%
% Autor: [Rui Borregana]
% Data: [25/02/2025]


function ultra_flag = ultrasonic_comp(audio_data, Fs)
    N = length(audio_data);
    
    Y = fft(audio_data);
    Y = abs(Y(1:N/2)); 
    
    freq = (0:N/2-1) * (Fs/N); 
    %freq = freq(1:N/2);
    
    % Verifica a energia no espectro ultrassonico (>15 kHz)
    ultrasonic_range = freq > 15000; 
    ultrasonic_mean_int = mean(Y(ultrasonic_range))

    threshold_ultra= 0.05; %limite para a detecao
    ultra_flag= ultrasonic_mean_int >= threshold_ultra;


%      figure;
%      plot(freq,Y);
%      grid on;



end


















