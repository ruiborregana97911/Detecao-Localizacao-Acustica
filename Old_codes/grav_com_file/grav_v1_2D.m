clearvars; clc; close all;

%% Parâmetros
Fs = 48000;             % Frequência de amostragem
v = 343;                % Velocidade do som (m/s)
threshold = 2e-3;       % Limiar de energia
sample_range = ceil(20e-3 * Fs); % Janela de análise (20ms)
vrf_tm = ceil(1e-3 * Fs);        % Verificação de energia a cada 1ms
tol_ev = 0.01;          % Tolerância mínima entre eventos (segundos)
last_event = -inf;

%% Posições dos microfones (em metros)
mic_pos = [0, 0;
           0, 1;
           1, 0;
           1, 1];

%% Carregar áudios
[audio1,Fs]=audioread("grav_audio1.wav");    %mudar para o ficheiro final
audio1=audio1';

audio1=audio1(1:48000);

%criacao do segundo audio
tmp= -1;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio2 = circshift(audio1,tmp);

%criacao do segundo audio
tmp= 0;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio3 = circshift(audio1,tmp);

%criacao do segundo audio
tmp= -1;    %tempo de deslocacao (ms)
tmp= ceil((tmp*1e-3)*Fs);
audio4 = circshift(audio1,tmp);


[audio_ref, ~] = audioread("ref_ball_sound.wav");
audio_ref = audio_ref(1:sample_range,1);

%% Inicializações

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
                segs = {audio1(init:fin), audio2(init:fin), audio3(init:fin), audio4(init:fin)};
        
                % Estimar TDOAs relativos ao canal 1
                tdoa12 = estimate_tdoa(segs{1}, segs{2}, Fs);
                tdoa13 = estimate_tdoa(segs{1}, segs{3}, Fs);
                tdoa14 = estimate_tdoa(segs{1}, segs{4}, Fs);
        
                % Localização
                %[x_est, resnorm] = locate_2D_NLS_visual(tdoa12, tdoa13, tdoa14, mic_pos, v);
                [x_est, resnorm, f] = locate_2D_NLS(tdoa12, tdoa13, tdoa14, mic_pos, v);
                fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', x_est(1), x_est(2));
                update_point_2D(x_est(1), x_est(2), mic_pos);
                
                % Plot do mapa de erro
                plot_resnorm_map(f, mic_pos);
                
                % Plot das hipérboles
                plot_hyperbolas(mic_pos, v, tdoa12, tdoa13, tdoa14);

        
                last_event = present_event;
                break   % evita múltiplas detecções no mesmo instante
            end
        end
    end
end

disp("Análise concluída.");

%% Função: Estimar TDOA entre dois sinais
function tdoa = estimate_tdoa(sig1, sig2, Fs)
    [c, lags] = xcorr(sig2, sig1);  % ordem invertida!
    [~, idx] = max(abs(c));
    tdoa = lags(idx) / Fs;
end

%% Função: Resolver TDOA 2D com 4 sensores via mínimos quadrados
function [x, resnorm, f] = locate_2D_NLS(t12, t13, t14, mic_pos, c)
    x0 = mean(mic_pos);  % chute inicial
	    
    %norma eucladiana = sqrt(.^2) 
    f = @(p) [
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(2,:)) - c*t12;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(3,:)) - c*t13;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(4,:)) - c*t14
    ];

    opts = optimoptions('lsqnonlin', 'Display','off');  % ou 'iter' se quiser acompanhar
    [x, resnorm] = lsqnonlin(f, x0, [], [], opts);
end



%%
function plot_resnorm_map(f, mic_pos)
    x_range = linspace(min(mic_pos(:,1)) - 0.1, max(mic_pos(:,1)) + 0.1, 200);
    y_range = linspace(min(mic_pos(:,2)) - 0.1, max(mic_pos(:,2)) + 0.1, 200);
    [X, Y] = meshgrid(x_range, y_range);
    E = zeros(size(X));

    for i = 1:numel(X)
        p = [X(i), Y(i)];
        e = f(p);
        E(i) = sum(e.^2);
    end

    figure;
    contourf(X, Y, E, 30, 'LineColor', 'none');
    colormap('hot');
    colorbar;
    hold on;
    scatter(mic_pos(:,1), mic_pos(:,2), 100, 'k', 'filled');
    text(mic_pos(:,1)+0.01, mic_pos(:,2)+0.01, ...
        arrayfun(@(i) sprintf('M%d', i), 1:4, 'UniformOutput', false));
    title('Mapa de erro quadrático');
    xlabel('x (m)');
    ylabel('y (m)');
    axis equal;
    grid on;
end

%%
function plot_hyperbolas(mic_pos, c, t12, t13, t14)
    % Parâmetros de grade
    x_range = linspace(min(mic_pos(:,1)) - 0.5, max(mic_pos(:,1)) + 0.5, 500);
    y_range = linspace(min(mic_pos(:,2)) - 0.5, max(mic_pos(:,2)) + 0.5, 500);
    [X, Y] = meshgrid(x_range, y_range);

    % Geração de hipérboles (Z == 0)
    D1 = sqrt((X - mic_pos(1,1)).^2 + (Y - mic_pos(1,2)).^2);
    D2 = sqrt((X - mic_pos(2,1)).^2 + (Y - mic_pos(2,2)).^2);
    D3 = sqrt((X - mic_pos(3,1)).^2 + (Y - mic_pos(3,2)).^2);
    D4 = sqrt((X - mic_pos(4,1)).^2 + (Y - mic_pos(4,2)).^2);

    figure;
    hold on;

    % Hipérboles
    contour(X, Y, (D1 - D2) - c*t12, [0 0], 'r', 'LineWidth', 1.5);
    contour(X, Y, (D1 - D3) - c*t13, [0 0], 'g', 'LineWidth', 1.5);
    contour(X, Y, (D1 - D4) - c*t14, [0 0], 'b', 'LineWidth', 1.5);

    scatter(mic_pos(:,1), mic_pos(:,2), 100, 'k', 'filled');
    text(mic_pos(:,1)+0.01, mic_pos(:,2)+0.01, ...
        arrayfun(@(i) sprintf('M%d', i), 1:4, 'UniformOutput', false));
    
    legend({'M1-M2', 'M1-M3', 'M1-M4'});
    title('Hipérboles TDOA dos pares com M1');
    xlabel('x (m)'); ylabel('y (m)');
    axis equal;
    grid minor;
end



