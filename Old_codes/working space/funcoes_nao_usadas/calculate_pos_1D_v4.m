% CALCULATE_POS_1D_V3 --> Calcula a posição de um evento entre 2 microfone
%
% Sintaxe:
%   calculate_pos_1D_v2(audio_data1, audio_data2, start_idx, end_idx, Fs, v)
%   
% Entradas:
%   audio_data1  - dados do microfone 1
%   audio_data2  - dados do microfone 2
%   start_idx - index de inicio da analise dos arrays de dados dos microfones
%   end_idx - index de fim da analise dos arrays de dados dos microfones
%   Fs - frequência de amostragem dos dados
%   v - velocidade do som (m\s)
%
% Saídas:
%   pos_sound - valor da posicao do evento entre os microfones em cm
%
% Esta função calcula com base em dois sinais de diferentes microfones a
% posição em 1 dimensão de um evento entre dois microfones.
%
% Autor: [Rui Borregana]
% Data: [16/04/2025]


function [pos_sound, cross_cor, lags] = calculate_pos_1D_v3(audio_data1, audio_data2, Fs, v)

    % Normalizar os sinais
    media_1= mean(audio_data1);
    dev_1= std(audio_data1);
    audio1_norm= (audio_data1 - media_1) ./ dev_1;

    media_2= mean(audio_data2);
    dev_2= std(audio_data2);
    audio2_norm= (audio_data2 - media_2) ./ dev_2;
    
    % Calcular a correlação cruzada e os lags correspondentes
    [cross_cor, lags] = xcorr(audio1_norm, audio2_norm);
    
    % Encontrar o pico da correlação cruzada
    [~, k] = max(abs(cross_cor));
    
    
    if k > 1 && k < length(cross_cor)
        y1 = cross_cor(k-1);
        y2 = cross_cor(k);
        y3 = cross_cor(k+1);
        delta = 0.5 * (y1 - y3) / (y1 - 2*y2 + y3);
        lag_interp = lags(k) + delta;
    else
        lag_interp = lags(k);
    end
    delay_time = lag_interp / Fs;


    % % Calcular o tempo de atraso
    % delay_time = lags(k) / Fs; % Tempo em segundos

    % Converter atraso em posição da fonte de som
    x = (v*100) * delay_time;       % diferença de deslocamento
    pos_sound = x / 2;        % posição relativa ao ponto médio
end