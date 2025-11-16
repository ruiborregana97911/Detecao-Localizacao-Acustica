% CHECK2_PINGPONG --> verifica se se trata de um som de bola de pinpong 
%
% Sintaxe:
%   check2_pingpong(audio_data)
%   check2_pingpong(audio_data,ref_audio)
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


function is_pingpong_ball = check2_pingpong(audio_data,ref_audio)
    
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
    
    [corr,lags]=xcorr(ref_audio,audio_data);   %fazer a correlacao de ambos os sinais
    %corr= corr/max(abs(corr));    %normalizar o sinal de correlacao
  
    [max_corr]=max(abs(corr));    %maximo da correlacao     
    
    shift = lags(max_corr);  % Obtém o deslocamento correto

    % Ajustar o alinhamento dos sinais com base no shift
    if shift > 0
        ref_audio = ref_audio(shift + 1:end);
        audio_data = audio_data(1:length(ref_audio)); % Redimensiona o segundo áudio
    elseif shift < 0
        audio_data = audio_data(-shift + 1:end);
        ref_audio = ref_audio(1:length(audio_data)); % Redimensiona o primeiro áudio
    end


    % Calcula a média dos sinais
    mean_audio = mean(audio_data);
    mean_ref = mean(ref_audio);

    % Calcula o numerador (covariância)
    numerador = sum((audio_data - mean_audio) .* (ref_audio - mean_ref));

    % Calcula os denominadores (desvio padrão)
    denominador_audio = sqrt(sum((audio_data - mean_audio).^2));
    denominador_ref = sqrt(sum((ref_audio - mean_ref).^2));

    % Calcula a correlação de Pearson
    r = numerador / (denominador_audio * denominador_ref)

    if r > 0.7   %verifica se a correlacao garante o limite minimo
        is_pingpong_ball= true;
    else
        is_pingpong_ball= false;
    end
    

%     figure;
%     plot(abs(corr));
%     title('check pingpong');

end