clearvars; clc; close all;

%prog para a versao adaptada do prof Daniel
%


%% Parâmetros
Fs = 48000;             % Frequência de amostragem
c = 343;                % Velocidade do som (m/s)
threshold = 2e-3;       % Limiar de energia
sample_range = ceil(120e-3 * Fs); % Janela de análise (20ms)
vrf_tm = ceil(1e-3 * Fs);        % Verificação de energia a cada 1ms
tol_ev = 0.01;          % Tolerância mínima entre eventos (segundos)
last_event = -inf;

%% Posições dos microfones (em metros)
mic_pos = [0, 0;
           0, 0.5;
           0.5, 0;
          0.5, 0.5];

%% 
[audio1,Fs]=audioread("grav_audio1.wav");    %mudar para o ficheiro final
audio1=audio1';

audio1=audio1(1:48000);

%criacao do segundo audio
tmp= -0.92;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio2 = circshift(audio1,tmp);

%criacao do segundo audio
tmp= -0.57;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio3 = circshift(audio1,tmp);

%criacao do segundo audio
tmp= -1.20;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio4 = circshift(audio1,tmp);


[audio_ref, ~] = audioread("ref_ball_sound.wav");
audio_ref = audio_ref(1:sample_range,1);

%% 

update_point_2D_MP_v2(0, 0, mic_pos, true);  % reset inicial
pause(1);  % evitar conflitos na primeira chamada


N = length(audio1);
mean_eng = [];
aux = 1;
disp("Início da análise...");

for i = 1:N
    
    Eng(:,i) = [audio1(i)^2; audio2(i)^2; audio3(i)^2; audio4(i)^2];

    if mod(i, vrf_tm) == 0
        for ch = 1:4
            mean_eng(ch, aux) = mean(Eng(ch, i - vrf_tm + 1:i));
        end
        aux = aux + 1;

        if aux < 4
            continue; 
        end

        for ch = 1:4
            eng     = mean_eng(ch, aux-1);
            eng_prev = mean_eng(ch, aux-2);
            eng_prev2 = mean_eng(ch, aux-3);
        
            if (eng > threshold && eng < eng_prev && eng_prev > eng_prev2)
                present_event = i / Fs;
                if present_event < last_event + tol_ev
                    continue
                end
        
                fprintf("Impacto detectado no canal %d em %.4f s\n", ch, present_event);
        
                % Cortar segmentos de todos os canais
                init = max(1, i - sample_range);
                fin  = min(N, i + sample_range);
                segs = {audio1(init:fin), audio2(init:fin), audio3(init:fin), audio4(init:fin)};
        
                % Estimar TDOAs relativos ao canal 1
                t12 = estimate_tdoa(segs{1}, segs{2}, Fs);
                t13 = estimate_tdoa(segs{1}, segs{3}, Fs);
                t14 = estimate_tdoa(segs{1}, segs{4}, Fs);

                
        
                
                tdoa=[t12;t13;t14];
                %[x_est, resnorm, f] = locate_2D_NLS(t12, t13, t14, mic_pos, c);
                x_est = localizar_2D_TDOA_ls(mic_pos', tdoa, c) ;
                
                %fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', x_est(1), x_est(2));
                %update_point_2D(x_est(1), x_est(2), mic_pos);
                
                if (pos_est(1) <= d_x+margem_mesa && pos_est(2) <= d_y+margem_mesa && ...
                        pos_est(1) >= 0-margem_mesa && pos_est(2) >= 0-margem_mesa)

                    update_point_2D_MP_v2(pos_est(1), pos_est(2), mic_pos);
                    
                else
                    disp('impacto fora do intervalo esperado!');
                    
                end
          

                last_event = present_event;
                break   % evita múltiplas detecções no mesmo instante
            end
        end
    end
end

disp("Análise concluída.");




%% 
function tdoa = estimate_tdoa(sig1, sig2, Fs)
    [c, lags] = xcorr(sig2, sig1);  
    [~, idx] = max(abs(c));
    tdoa = lags(idx) / Fs;
end

%%

function pos_est = localizar_2D_TDOA_ls(mic_pos, tdoa, c)
% LOCALIZAR_2D_TDOA_LS - Estima a posição 2D com base em TDOA e mínimos quadrados
%
% Inputs:
%   mic_pos - matriz 2xN com posições dos microfones [x; y]
%   tdoa    - vetor (N-1)x1 com diferenças de tempo em relação ao mic1 (t2-t1, t3-t1, ...)
%   c       - velocidade do som (m/s)
%
% Output:
%   pos_est - vetor 2x1 com a posição estimada [x; y] em metros

% Número de microfones
N = size(mic_pos, 2)

% Construção da matriz Ct (diferenças de posição em relação ao mic1)
Ct = mic_pos(:, 2:end)

% Diferenças de distância estimadas (baseadas nas TDOA)
delta_d = tdoa * c

% Vetor r conforme a fórmula
r = zeros(N-1, 1);
for i = 1:N-1
    Ct(:,i) = Ct(:,i) - mic_pos(:, 1)
    r(i) = 0.5 * (norm(Ct(:,i))^2 - delta_d(i)^2);
end

% Resolução por mínimos quadrados
A = (Ct*Ct')\Ct
Ar = A*r
Ad = -A*delta_d

% Resolução da equação quadrática: 
% a*d1^2 + b*d1 + c = 0

a = Ad(1).^2 + Ad(2).^2 + 1
b = 2*(Ar(1)*Ad(1) + Ar(2)*Ad(2))
c = Ar(1).^2 + Ar(2).^2

sq = sqrt(b.^2-4*a*c)
s = real(([sq -sq]-b)/(2*a))

% if D < 0
%     warning('Sem solução real!');
% 
% else
%     s1 = (-b + sqrt(D)) / (2*a)
%     s2 = (-b - sqrt(D)) / (2*a)
% 
% 
% end

% Estimar posição relativa e converter para absoluta
pos_est = Ad * s + Ar + mic_pos(:,1);
end


%% 
function [x, resnorm, f] = locate_2D_NLS(t12, t13, t14, mic_pos, c)
    x0 = mean(mic_pos);  % ponto inicial
	
    %norma eucladiana = sqrt(.^2) 
    f = @(p) [
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(2,:)) - c*t12;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(3,:)) - c*t13;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(4,:)) - c*t14
    ];

    opts = optimoptions('lsqnonlin', 'Display','iter');  
    [x, resnorm] = lsqnonlin(f, x0, [], [], opts);

    % Antes 
    f_init = f(x0);
    resnorm_init = sum(f_init.^2);
    
    % Depois 
    f_fin = f(x);
    resnorm_fin = sum(f_fin.^2);
    
    fprintf("Erro inicial: %.4e\n", resnorm_init);
    fprintf("Erro final: %.4e\n", resnorm_fin);

end









