% UPDATE_POINT_2D_MP_v2 --> Registra e exibe a posição de impactos sonoros em 2D
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
% Data: [27/06/2025]

function update_point_2D_MP_v2(x, y, mic_pos, reset)
    persistent pos_list max_points base_color scatter_handles

    if nargin < 4
        reset = false;
    end

    if reset
        pos_list = [];
        base_color = [0.9290, 0.6940, 0.1250];  % cor dos impactos
        max_points = 7;
        scatter_handles = gobjects(max_points, 1);  % prealocar com handles inválidos

        figure;
        set(gcf, 'Position', [80, 80, 800, 600]);
        set(gca, 'Color', [0.3010, 0.7450, 0.9330]);
        hold on;


        % Dimensões da mesa
        mesa_x = mic_pos(1,1);  % origem x
        mesa_y = mic_pos(1,2);  % origem y
        mesa_w = mic_pos(3,1);  % comprimento
        mesa_h = mic_pos(2,2);  % altura

        % Desenhar mesa
        rectangle('Position', [mesa_x, mesa_y, mesa_w, mesa_h], ...
            'FaceColor', [0, 0.5, 0.5], 'EdgeColor', 'w', 'LineWidth', 2);

        % Linhas centrais
        line([0, mesa_w], [mesa_h/2, mesa_h/2], 'Color', 'w', 'LineWidth', 2);
        line([mesa_w/2, mesa_w/2], [0, mesa_h], 'Color', 'w', 'LineWidth', 2);

        % Microfones
        scatter(mic_pos(:,1), mic_pos(:,2), 80, 'k', 'filled');
        text(mic_pos(:,1) + 0.01, mic_pos(:,2) + 0.01, ...
            arrayfun(@(i) sprintf('M%d',i), 1:4, 'UniformOutput', false));
        
        % Margem à volta da mesa (em metros)
        margem = 0.05;
        
        % Ajustar os limites dos eixos
        xlim([mesa_x - margem, mesa_x + mesa_w + margem]);
        ylim([mesa_y - margem, mesa_y + mesa_h + margem]);


        title('Localização estimada dos impactos (2D)');
        xlabel('x (m)'); ylabel('y (m)');
        axis equal;
        grid minor;
        return;
    end

    % Atualizar histórico
    if isempty(pos_list)
        pos_list = [x y];
    elseif size(pos_list,1) < max_points
        pos_list = [pos_list; x y];
    else
        pos_list = [pos_list(2:end,:); x y];
    end

    % Atualizar scatter
    n = size(pos_list, 1);
    for i = 1:n
        alpha = (i / n)^1.5;

        if ~isgraphics(scatter_handles(i)) || ~isvalid(scatter_handles(i))
            scatter_handles(i) = scatter(pos_list(i,1), pos_list(i,2), 100, ...
                'MarkerFaceColor', base_color, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceAlpha', alpha, ...
                'MarkerEdgeAlpha', alpha);
        else
            % Atualiza posição e transparência
            set(scatter_handles(i), ...
                'XData', pos_list(i,1), ...
                'YData', pos_list(i,2), ...
                'MarkerFaceAlpha', alpha, ...
                'MarkerEdgeAlpha', alpha);
        end
    end

    % Esconde pontos extra
    for i = (n+1):max_points
        if isgraphics(scatter_handles(i)) && isvalid(scatter_handles(i))
            set(scatter_handles(i), 'XData', NaN, 'YData', NaN);
        end
    end

    drawnow;
end
