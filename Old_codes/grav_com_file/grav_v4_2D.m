clearvars; clc; close all;
%
%janela de hamming

%% Parâmetros
Fs = 48000;             % Frequência de amostragem
c = 343;                % Velocidade do som (m/s)
threshold = 2e-3;       % Limiar de energia
sample_range = ceil(60e-3 * Fs); % Janela de análise (20ms)
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

update_point_2D(0, 0, mic_pos, true);  % reset inicial
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
                %segs = {audio1(init:fin), audio2(init:fin), audio3(init:fin), audio4(init:fin)};

                N=length(audio1(init:fin));
                win=hamming(N);

                audio_win1=audio1(init:fin) .* win';
                audio_win2=audio2(init:fin) .* win';
                audio_win3= audio3(init:fin) .* win';
                audio_win4=audio4(init:fin) .* win';

                segs = {audio_win1, audio_win2, audio_win3, audio_win4};

                % Estimar TDOAs relativos ao canal 1
                t12 = estimate_tdoa(segs{1}, segs{2}, Fs);
                t13 = estimate_tdoa(segs{1}, segs{3}, Fs);
                t14 = estimate_tdoa(segs{1}, segs{4}, Fs);

                fprintf("t12 = %.2f ms | t13 = %.2f ms | t14 = %.2f ms\n", t12*1e3, t13*1e3, t14*1e3);

                
                
                
                %[x_est, resnorm] = locate_2D_NLS_visual(tdoa12, tdoa13, tdoa14, mic_pos, v);
                [x_est, resnorm, f] = locate_2D_NLS(t12, t13, t14, mic_pos, c);
                fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', x_est(1), x_est(2));
                update_point_2D(x_est(1), x_est(2), mic_pos);
                
                f_vect = build_tdoa_error_functions(mic_pos, c, t12, t13, t14);    

                last_event = present_event;
                break   % evita múltiplas detecções no mesmo instante
            end
        end
    end
end

disp("Análise concluída.");


%plot_resnorm_map(f_vect, mic_pos, t12, t13, t14);
%plot_hyperbolas(f_vect, mic_pos);


%% 
function tdoa = estimate_tdoa(sig1, sig2, Fs)
    [c, lags] = xcorr(sig2, sig1);  
    [~, idx] = max(abs(c));
    tdoa = lags(idx) / Fs;
end

%%
function data_norm = DataNorm(data)

    %normalizar
    media_data = mean(data);
    dev_data = std(data);
    data_norm= (data - media_data) ./ dev_data; 
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

%%
function [x, resnorm, f] = locate_2D_NLS2(t12, t13, t14, mic_pos, c, mic)
  
   % Começa na posição do microfone que detectou primeiro
    pos_est = mic_pos(mic, :);

    % Calcula o vetor médio para os outros microfones
    dir_vec = mean(mic_pos - pos_est, 1);

    % Fator de deslocamento para afastar a estimativa inicial um pouco
    desloc_factor = 0.3;

    % Estimativa inicial ajustada
    x0 = pos_est + desloc_factor * dir_vec;
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




%%

function f_vect = build_tdoa_error_functions(mic_pos, c, t12, t13, t14)
    
    m1 = mic_pos(1,:);
    m2 = mic_pos(2,:);
    m3 = mic_pos(3,:);
    m4 = mic_pos(4,:);

    f_vect = @(X,Y) struct( ...
        'D1', sqrt((X - m1(1)).^2 + (Y - m1(2)).^2) - sqrt((X - m2(1)).^2 + (Y - m2(2)).^2) - c*t12, ...
        'D2', sqrt((X - m1(1)).^2 + (Y - m1(2)).^2) - sqrt((X - m3(1)).^2 + (Y - m3(2)).^2) - c*t13, ...
        'D3', sqrt((X - m1(1)).^2 + (Y - m1(2)).^2) -  sqrt((X - m4(1)).^2 + (Y - m4(2)).^2) - c*t14);
end

%%

function plot_resnorm_map(f_vect, mic_pos, t12, t13, t14)

    % Geração da malha (grid)
    x_range = linspace(min(mic_pos(:,1)) - 0.1, max(mic_pos(:,1)) + 0.1, 200);
    y_range = linspace(min(mic_pos(:,2)) - 0.1, max(mic_pos(:,2)) + 0.1, 200);
    [X, Y] = meshgrid(x_range, y_range);

   
    F = f_vect(X, Y);  % Deve retornar struct com D1, D2, D3

    % Calcula o erro quadrático para cada ponto do grid:
    % erro = (D1 - tdoa(1))^2 + (D2 - tdoa(2))^2 + (D3 - tdoa(3))^2
    E = (F.D1 - t12).^2 + (F.D2 - t13).^2 + (F.D3 - t14).^2;

    
    figure;
    contourf(X, Y, log(E + 1e-12), 30, 'LineColor', 'none');  % log escala para melhor contraste
    colormap('hot');
    colorbar;
    hold on;
    scatter(mic_pos(:,1), mic_pos(:,2), 100, 'k', 'filled');
    text(mic_pos(:,1)+0.01, mic_pos(:,2)+0.01, ...
        arrayfun(@(i) sprintf('M%d', i), 1:size(mic_pos,1), 'UniformOutput', false));
    title('Mapa de erro quadrático (log escala)');
    xlabel('x (m)');
    ylabel('y (m)');
    axis equal;
    grid on;
end


%%

function plot_hyperbolas(f_vect, mic_pos)
    x_range = linspace(min(mic_pos(:,1)) - 200, max(mic_pos(:,1)) + 200, 4000);
    y_range = linspace(min(mic_pos(:,2)) - 200, max(mic_pos(:,2)) + 200, 4000);
    [X, Y] = meshgrid(x_range, y_range);
    
    F = f_vect(X,Y);

    figure;
    hold on;
    contour(X, Y, F.D1, [0 0], 'r', 'LineWidth', 1.5);
    contour(X, Y, F.D2, [0 0], 'g', 'LineWidth', 1.5);
    contour(X, Y, F.D3, [0 0], 'b', 'LineWidth', 1.5);
    scatter(mic_pos(:,1), mic_pos(:,2), 100, 'k', 'filled');
    title('Hipérboles TDOA entre M1-Mj');
    legend('M1-M2', 'M1-M3', 'M1-M4');
    axis equal; grid minor;
end
