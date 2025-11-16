% === anotar_eventos_audio_interativo.m ===
clear; clc;

%% === PARÂMETROS ===
nome_ficheiro = 'gravacao_aris_hall_1.wav';  % <--- altera aqui
canal = 1;

%% === LER ÁUDIO ===
[audio, fs] = audioread(nome_ficheiro);
if size(audio,2) < canal
    error('O ficheiro não tem o canal %d.', canal);
end
sinal = audio(:, canal);
duracao_s = length(sinal) / fs;
fprintf('Duração: %.2f segundos\n', duracao_s);

%% === ENERGIA ===
frame_ms = 2;
frame_length = round((frame_ms / 1000) * fs);
energia = movmean(sinal.^2, frame_length);
t = (0:length(sinal)-1) / fs;

%% === FIGURA ===
fig = figure('Name', 'Anotar Eventos de Impacto', ...
             'NumberTitle', 'off', ...
             'KeyPressFcn', @tecla, ...
             'WindowButtonDownFcn', @clicou);

ax = axes('Parent', fig);
plot(ax, t, energia, 'b'); hold on;
xlabel('Tempo (s)'); ylabel('Energia');
title({'Clique com botão esquerdo para anotar', ...
       'ENTER = terminar | BACKSPACE = desfazer'});

% Grid personalizado
grid minor;

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

% Guardar no base
assignin('base', 'x_eventos', x_eventos);
assignin('base', 'h_cliques', h_cliques);
assignin('base', 't', t);
assignin('base', 'energia', energia);
assignin('base', 'ax', ax);

%% === Esperar até ENTER ===
uiwait(fig);

%% === GUARDAR ===
eventos = [x_eventos(:), ones(numel(x_eventos),1)];
[~, nome_base, ~] = fileparts(nome_ficheiro);
nome_saida = ['eventos_' nome_base '.mat'];
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

    y = interp1(t, energia, x);
    h = plot(ax, x, y, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5);

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
