% CHECK_PINGPONG --> verifica se se trata de um som de bola de pinpong 
%
% Sintaxe:
%   check_pingpong(audio_data)
%   check_pingpong(audio_data,ref_audio)
%
% Entradas:
%   audio_data  - dados de audio
%   ref_audio - (opcinal) audio de refencia para comparação
%   
%
% Saídas:
%   is_pingpong_ball - Booleano de confirmacao de som de bola de pingpong
%
% 
% faz a correlacao cruzada entre um som de referencia e o som que se quer
% analizar e devolve um booleano que indica se os sons sao semelhantes ou
% nao
%  
%
% Autor: [Rui Borregana]
% Data: [27/02/2025]


function is_pingpong_ball = check_pingpong(audio_data,ref_audio)
    
    if nargin < 2 || isempty(ref_audio)
        [ref_audio,~]=audioread("ref_ball_sound.wav");  %no caso de nao usar uma referencia externa tenho este exemplo
        %CUIDADO!!!! : esta amostra foi feita a 48KHz
    end
    
    audio_data= audio_data/max(abs(audio_data));    %normalização dos dados de audio
    sample_length= length(audio_data);  %vericar o numero de amostras do audio
    
    if sample_length > length(ref_audio)
        error('dados de do audio maior que a referencia!');
    end

    ref_audio = ref_audio(1:sample_length); %garantir que ref_audio e audio_data sao do mesmo tamanho
    ref_audio= ref_audio/max(abs(ref_audio));    %normalização dos dados de referencia
    
    corr=xcorr(audio_data,ref_audio);   %fazer a correlacao de ambos os sinais
    corr= corr/max(abs(corr));    %normalizar o sinal de correlacao
    
    mean_corr= mean(abs(corr)); %media da correlacao
    max_corr=max(abs(corr));    %maximo da correlacao 
    std_corr= std(abs(corr));   %desvio padrao da correlacao

    z_score= (max_corr - mean_corr)/std_corr    %standart score

    if z_score > 9.5   %verifica se a correlacao garante o limite minimo
        is_pingpong_ball= true;
    else
        is_pingpong_ball= false;
    end


%     figure;
%     plot(abs(corr));
%     title('check pingpong');

end








