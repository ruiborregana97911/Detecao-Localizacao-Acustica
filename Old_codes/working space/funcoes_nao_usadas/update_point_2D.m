% UPDATE_POINT_2D --> Registra e exibe a posição de impactos sonoros em 2D
%
% Sintaxe:
%   update_point_2D(x, y, mic_pos)              - Adiciona um impacto na posição (x, y)
%   update_point_2D(x, y, mic_pos, reset)       - Limpa dados antigos e reinicializa o gráfico
%
% Entradas:
%   x, y     - Coordenadas estimadas do impacto (em metros)
%   mic_pos  - Matriz 4x2 com posições dos microfones [x y] (em metros)
%   reset    - (Opcional) Booleano que reinicializa o gráfico (default = false)
%
% 
% Data: [25/05/2025]

function update_point_2D(x, y, mic_pos, reset)
    persistent pos_list color_list color_palette

    if nargin < 4
        reset = false;
    end

    if reset
        pos_list = [];
        color_list = [];
        color_palette = [];

        % Inicializar nova figura
        figure;
        hold on;
        scatter(mic_pos(:,1), mic_pos(:,2), 80, 'k', 'filled');
        text(mic_pos(:,1) + 0.01, mic_pos(:,2) + 0.01, ...
             arrayfun(@(i) sprintf('M%d',i), 1:4, 'UniformOutput', false));
        title('Localização estimada dos impactos (2D)');
        xlabel('x (m)'); ylabel('y (m)');
        axis equal;
        grid minor;
        return;
    end

    % Paleta de cores (até 7 impactos distintos)
    if isempty(color_palette)
        color_palette = [
            1, 0, 0;   % vermelho
            0, 1, 0;   % verde
            0, 0, 1;   % azul
            1, 1, 0;   % amarelo
            0, 1, 1;   % ciano
            1, 0, 1;   % magenta
            0.5, 0.5, 0.5; % cinza
        ];
    end

    % Adicionar nova posição
    if isempty(pos_list)
        pos_list = [x y];
        color_list = color_palette(1,:);
    elseif size(pos_list,1) < 7
        pos_list = [pos_list; x y];
        color_list = [color_list; color_palette(size(pos_list,1),:)];
    else
        % Substituir o mais antigo
        pos_list = [pos_list(2:end,:); x y];
        color_list = [color_list(2:end,:); color_list(1,:)];
    end

    % Atualizar gráfico
    cla;
    hold on;
    scatter(mic_pos(:,1), mic_pos(:,2), 80, 'k', 'filled');
    text(mic_pos(:,1) + 0.01, mic_pos(:,2) + 0.01, ...
         arrayfun(@(i) sprintf('M%d',i), 1:4, 'UniformOutput', false));
    for i = 1:size(pos_list,1)
        plot(pos_list(i,1), pos_list(i,2), 'o', 'MarkerSize', 10, ...
             'MarkerFaceColor', color_list(i,:), 'MarkerEdgeColor', 'k');
    end
    title('Localização estimada dos impactos (2D)');
    xlabel('x (m)');
    ylabel('y (m)');
    %axis equal;
    %grid minor;
    drawnow;
end
