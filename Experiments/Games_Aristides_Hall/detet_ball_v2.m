clear; clc;
%versao que usa a analise com todos os canais para marcar os picos dos sons
%de bola!


%% === PARÂMETROS ===
nome_ficheiro = 'gravacao_aris_hall_xx.wav';  
n_canais = 4;
frame_ms = 2;
frame_length = round((frame_ms / 1000) * 48000); % Ajuste o fs depois
threshold = 0.01; % Só para mostrar, não usada para ativar clique

%% === LER ÁUDIO ===
[audio, fs] = audioread(nome_ficheiro);
if size(audio,2) < n_canais
    error('O ficheiro não tem %d canais.', n_canais);
end

% Energia para cada canal
energia = zeros(size(audio,1), n_canais);
for c = 1:n_canais
    energia(:,c) = movmean(audio(:,c).^2, frame_length);
end
t = (0:size(audio,1)-1)/fs;

%% === FIGURA ===
fig = figure('Name', 'Anotar Eventos Multicanais', ...
             'NumberTitle', 'off', ...
             'KeyPressFcn', @tecla, ...
             'WindowButtonDownFcn', @clicou);

ax = axes('Parent', fig);
cores = ['c', 'r', 'g', 'm'];
hold on;
for c = 1:n_canais
    plot(t, energia(:,c), cores(c));
end
xlabel('Tempo (s)');
ylabel('Energia');
title({'Clique com botão esquerdo para anotar evento', ...
       'ENTER = terminar | BACKSPACE = desfazer'});
grid minor;
legend('Canal 1','Canal 2','Canal 3','Canal 4');
hold off;

% === BOTÕES DE ZOOM E PAN ===
tb = uitoolbar(fig);

uipushtool(tb, 'TooltipString', 'Zoom', ...
    'ClickedCallback', @(~,~) activateMode(fig, 'zoom'), ...
    'CData', rand(16,16,3));  % ícone aleatório placeholder

uipushtool(tb, 'TooltipString', 'Pan', ...
    'ClickedCallback', @(~,~) activateMode(fig, 'pan'), ...
    'CData', 0.5*ones(16,16,3));  % ícone cinza claro

uipushtool(tb, 'TooltipString', 'Selecionar (desativar zoom/pan)', ...
    'ClickedCallback', @(~,~) activateMode(fig, 'none'), ...
    'CData', zeros(16,16,3));  % ícone preto

%% === Variáveis de Estado ===
x_eventos = [];
h_cliques = [];

assignin('base', 'x_eventos', x_eventos);
assignin('base', 'h_cliques', h_cliques);
assignin('base', 't', t);
assignin('base', 'energia', energia);
assignin('base', 'ax', ax);

%% === Esperar até ENTER ===
uiwait(fig);

%% === GUARDAR ===
% Aqui você pode guardar a lista de eventos anotados
eventos = x_eventos(:);
[~, nome_base, ~] = fileparts(nome_ficheiro);
nome_saida = ['eventos_label_ball_' nome_base '.mat'];
save(nome_saida, 'eventos');
fprintf('Eventos guardados em "%s"\n', nome_saida);

%% === Funções Auxiliares ===

function activateMode(fig, mode)
    zoom(fig, 'off');
    pan(fig, 'off');
    if strcmp(mode, 'zoom')
        zoom(fig, 'on');
    elseif strcmp(mode, 'pan')
        pan(fig, 'on');
    end
end

function clicou(src, ~)
    if ~strcmp(get(src, 'SelectionType'), 'normal')
        return;
    end

    x_eventos = evalin('base', 'x_eventos');
    h_cliques = evalin('base', 'h_cliques');
    t = evalin('base', 't');
    energia = evalin('base', 'energia');
    ax = evalin('base', 'ax');

    pt = get(ax, 'CurrentPoint');
    x = pt(1,1);

    if x < min(t) || x > max(t)
        return;
    end

    % Para mostrar o valor da energia mais alta naquele instante entre os canais
    idx = find(t >= x, 1);
    y_canais = energia(idx, :);
    y = max(y_canais);

    hold(ax, 'on');
    h = plot(ax, x, y, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);
    hold(ax, 'off');

    x_eventos(end+1) = x;
    h_cliques(end+1) = h;

    assignin('base', 'x_eventos', x_eventos);
    assignin('base', 'h_cliques', h_cliques);
end

function tecla(src, event)
    x_eventos = evalin('base', 'x_eventos');
    h_cliques = evalin('base', 'h_cliques');

    switch event.Key
        case 'backspace'
            if ~isempty(x_eventos)
                x_eventos(end) = [];
                delete(h_cliques(end));
                h_cliques(end) = [];
                assignin('base', 'x_eventos', x_eventos);
                assignin('base', 'h_cliques', h_cliques);
            end
        case 'return'
            uiresume(src);
    end
end
