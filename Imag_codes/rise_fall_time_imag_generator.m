clc;clearvars;close all;

[audio,Fs] = audioread("Bola\ball_0220.wav");   
    


%tentar apoveitar e retirar medidas apartir da energia!!!
    
    vrf_tm = 1;  % em milissegundos
    vrf_tm = vrf_tm * 1e-3;
    
    
    energy = audio.^2;
    smooth_energy = movmean(energy, round(vrf_tm*Fs)); % janela de 1 ms
    energy_norm = smooth_energy / max(smooth_energy);
    
    %Feature 20: Time rise
    
    idx_10 = find(energy_norm >= 0.1, 1, 'first');
    idx_90 = find(energy_norm >= 0.9, 1, 'first');
    if ~isempty(idx_10) && ~isempty(idx_90)
        tempo_ataque_ms = (idx_90 - idx_10) / Fs * 1000;
    end
    
    
    
    %Feature 21: Time Fall
    
    [~, idx_peak] = max(energy_norm); %localizar pico de energia
    
    idx_90d = find(energy_norm(idx_peak:end) <= 0.9, 1, 'first');
    idx_10d = find(energy_norm(idx_peak + idx_90d - 1:end) <= 0.1, 1, 'first');
    
    if ~isempty(idx_90d) && ~isempty(idx_10d)
        idx_90d = idx_peak + idx_90d - 1;
        idx_10d = idx_90d + idx_10d - 1;
    
        tempo_decay_ms = (idx_10d - idx_90d) / Fs * 1000;
        
    else
        tempo_decay_ms = NaN;
    end


% Thresholds de 10% e 90%
th10 = 0.1; 
th90 = 0.9; 

idx_10 = (idx_10 -1) / Fs * 1000;
idx_10d = (idx_10d -1) / Fs * 1000;
idx_90 = (idx_90 -1) / Fs * 1000;
idx_90d = (idx_90d -1) / Fs * 1000;


t = (0:length(audio)-1)/Fs*1000;

figure;
% --- Cores principais ---
cor_env = [0.2 0.2 0.2];       % cinzento escuro
cor_ataque = [0.85 0.33 0.1];  % laranja/vermelho suave
cor_queda = [0 0.45 0.74];     % azul suave
cor_10 = [0.47 0.67 0.19];     % verde (10%)
cor_90 = [0.49 0.18 0.56];     % magenta (90%)

% Plot da envolvente
plot(t, energy_norm, 'Color', cor_env, 'LineWidth', 1.5); hold on;

% Linhas horizontais 10% e 90%
yline(th10, '--', '10%', 'Color', cor_10, 'LineWidth', 1);
yline(th90, '--', '90%', 'Color', cor_90, 'LineWidth', 1);

% Linhas verticais para ataque e queda
xline(idx_10, '--', 'Color', cor_10, 'LineWidth', 1);
xline(idx_90, '--', 'Color', cor_90, 'LineWidth', 1);
xline(idx_90d, '--', 'Color', cor_90, 'LineWidth', 1);
xline(idx_10d, '--', 'Color', cor_10, 'LineWidth', 1);

% Regiões sombreadas (ataque e queda)
patch([idx_10 idx_90 idx_90 idx_10], [0 0 1 1], cor_ataque, ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none');
patch([idx_90d idx_10d idx_10d idx_90d], [0 0 1 1], cor_queda, ...
    'FaceAlpha', 0.15, 'EdgeColor', 'none');


% Melhorar aparência geral
xlabel("Tempo [ms]");
ylabel("Envolvente normalizada");
% grid on;
% ax = gca;
% ax.GridLineStyle = ':';
% ax.GridColor = [0.5 0.5 0.5];
% ax.GridAlpha = 0.3;
axis([0 5 0 1]);
xticks(0:1:5);
yticks(0:0.2:1);


% --- Texto para T_ataque e T_queda ---
x_ataque = (idx_10 + idx_90) / 2;   % ponto médio entre 10% e 90%
x_queda = (idx_90d + idx_10d) / 2;  % ponto médio entre 90% e 10%

% Posições verticais (ligeiramente abaixo de 1 para não sobrepor)
y_text = 0.05;  

% Adicionar textos ao gráfico
text(x_ataque, y_text, 'T_{ataque}', 'HorizontalAlignment', 'center', ...
    'FontSize', 11,'FontName', 'Times New Roman');  

text(x_queda, y_text, 'T_{queda}', 'HorizontalAlignment', 'center', ...
    'FontSize', 11,'FontName', 'Times New Roman');

