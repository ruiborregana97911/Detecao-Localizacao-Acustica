function update_point_3D_MP(x, y, mic_pos, reset)
    persistent pos_list max_points base_color scatter_handles

    if nargin < 4
        reset = false;
    end

    if reset
        pos_list = [];
        max_points = 7;
        base_color = [0.9290, 0.6940, 0.1250]; % amarelo
        scatter_handles = gobjects(max_points, 1);

        figure;
        clf;
        set(gcf, 'Position', [100, 100, 900, 700]);
        ax = gca;
        hold on;
        grid on;

        % Ativar rotação livre
        view(3);
        rotate3d on;

        % Tamanho da mesa
        mesa_x = mic_pos(1,1);
        mesa_y = mic_pos(1,2);
        mesa_w = mic_pos(3,1);
        mesa_h = mic_pos(2,2);
        mesa_z = 0;

        % Desenhar a mesa como um retângulo 3D
        fill3(...
            [mesa_x, mesa_x+mesa_w, mesa_x+mesa_w, mesa_x], ...
            [mesa_y, mesa_y, mesa_y+mesa_h, mesa_y+mesa_h], ...
            [mesa_z, mesa_z, mesa_z, mesa_z], ...
            [0, 0.5, 0.5], 'FaceAlpha', 1, 'EdgeColor', 'w', 'LineWidth', 2);

        % Linhas brancas centrais
        line([mesa_x, mesa_x+mesa_w], [mesa_y+mesa_h/2, mesa_y+mesa_h/2], [0 0], 'Color', 'w', 'LineWidth', 2);
        line([mesa_x+mesa_w/2, mesa_x+mesa_w/2], [mesa_y, mesa_y+mesa_h], [0 0], 'Color', 'w', 'LineWidth', 2);

        % Microfones como pontos pretos
        scatter3(mic_pos(:,1), mic_pos(:,2), zeros(4,1), 80, 'k', 'filled');
        text(mic_pos(:,1)+0.01, mic_pos(:,2)+0.01, zeros(4,1), ...
            arrayfun(@(i) sprintf('M%d',i), 1:4, 'UniformOutput', false));

        title('Localização estimada dos impactos (3D)');
        xlabel('x (m)');
        ylabel('y (m)');
        zlabel('z (m)');
        axis equal;
        xlim([mesa_x-0.1, mesa_x+mesa_w+0.1]);
        ylim([mesa_y-0.1, mesa_y+mesa_h+0.1]);
        zlim([-0.1, 0.3]);

        return;
    end

    % Atualiza lista de pontos
    if isempty(pos_list)
        pos_list = [x y];
    elseif size(pos_list,1) < max_points
        pos_list = [pos_list; x y];
    else
        pos_list = [pos_list(2:end,:); x y];
    end

    % Atualizar os pontos
    n = size(pos_list, 1);
    for i = 1:n
        alpha = (i / n)^1.5;

        if ~isgraphics(scatter_handles(i)) || ~isvalid(scatter_handles(i))
            scatter_handles(i) = scatter3(pos_list(i,1), pos_list(i,2), 0, ...
                100, 'MarkerFaceColor', base_color, ...
                'MarkerEdgeColor', 'k', ...
                'MarkerFaceAlpha', alpha, ...
                'MarkerEdgeAlpha', alpha);
        else
            set(scatter_handles(i), ...
                'XData', pos_list(i,1), ...
                'YData', pos_list(i,2), ...
                'ZData', 0, ...
                'MarkerFaceAlpha', alpha, ...
                'MarkerEdgeAlpha', alpha);
        end
    end

    % Esconder pontos a mais
    for i = (n+1):max_points
        if isgraphics(scatter_handles(i)) && isvalid(scatter_handles(i))
            set(scatter_handles(i), 'XData', NaN, 'YData', NaN, 'ZData', NaN);
        end
    end

    drawnow;
end
