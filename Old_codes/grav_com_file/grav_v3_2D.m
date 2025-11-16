clearvars; clc; close all;

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
tmp= -2.67;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio2 = circshift(audio1,tmp);

%criacao do segundo audio
tmp= -0.81;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio3 = circshift(audio1,tmp);

%criacao do segundo audio
tmp= -1.40;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio4 = circshift(audio1,tmp);


[audio_ref, ~] = audioread("ref_ball_sound.wav");
audio_ref = audio_ref(1:sample_range,1);

%% 

% update_point_2D(0, 0, mic_pos, true);  % reset inicial
% pause(1);  % evitar conflitos na primeira chamada
% 

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
        
                
                %[x_est, resnorm] = locate_2D_NLS_visual(tdoa12, tdoa13, tdoa14, mic_pos, v);
                %[x_est, resnorm, f] = locate_2D_NLS(t12, t13, t14, mic_pos, c);
                %fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', x_est(1), x_est(2));
                %update_point_2D(x_est(1), x_est(2), mic_pos);
                
                solutions = solve_hyperbola_pairs(t12, t13, t14, mic_pos, c);
               
                [numRows,numCols] = size(solutions);


                if (numRows > 1)
                    for k= 1:length(solutions)
                        fprintf("solucao %d: x= %f ,y= %f \n", k,solutions(k,1),solutions(k,2));
                    end 
                    sol_mean= mean(solutions);
                    fprintf("\nsolucao media: x= %f ,y= %f \n", sol_mean(1), sol_mean(2));
                else 
                    fprintf("solucao unica: x= %f ,y= %f \n",solutions(1),solutions(2));
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
function solutions = solve_hyperbola_pairs(t12, t13, t14, mic_pos, c)
    % Calcula os deslocamentos reais entre os microfones (em metros)
    d12 = c * t12;
    d13 = c * t13;
    d14 = c * t14;

    % Soluções por par de hiperbolas
    sol12_13 = solve_pair(mic_pos(1,:), mic_pos(2,:), d12, ...
                          mic_pos(1,:), mic_pos(3,:), d13);

    sol12_14 = solve_pair(mic_pos(1,:), mic_pos(2,:), d12, ...
                          mic_pos(1,:), mic_pos(4,:), d14);

    sol13_14 = solve_pair(mic_pos(1,:), mic_pos(3,:), d13, ...
                          mic_pos(1,:), mic_pos(4,:), d14);

    % Juntar todas as soluções
    solutions = [sol12_13; sol12_14; sol13_14];
end

%%

function points = solve_pair(m1, m2, d1, m3, m4, d2)
    % Define as incógnitas
    syms x y real
    p = [x, y];

    % Distâncias para o primeiro par
    eq1 = norm(p - m1) - norm(p - m2) == d1;
    eq2 = norm(p - m3) - norm(p - m4) == d2;

    % Resolver o sistema
    sol = vpasolve([eq1, eq2], [x, y]);

    % Converter para matriz de pontos reais
    points = [];
    for i = 1:length(sol.x)
        xi = double(sol.x(i));
        yi = double(sol.y(i));
        if isreal(xi) && isreal(yi)
            points(end+1,:) = [xi, yi];
        end
    end
end

