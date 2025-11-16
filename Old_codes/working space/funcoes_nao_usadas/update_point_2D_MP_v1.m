function update_point_2D_MP_v1(x, y, mic_pos, reset)
    persistent pos_list max_points base_color

    if nargin < 4
        reset = false;
    end

    if reset
        pos_list = [];
        base_color = [0.9290, 0.6940, 0.1250];  % verde
        max_points = 7;

        figure;
        set(gcf, 'Position', [80, 80, 800, 600]); % [left, bottom, width, height]
        set(gca,'Color', [0.3010, 0.7450, 0.9330]); % Muda a cor de fundo
        hold on;
        
        rectangle('Position',[mic_pos(1,1), mic_pos(1,2), mic_pos(3,1), mic_pos(2,2)], ...
            'FaceColor',[0, 0.5, 0.5],'EdgeColor','w','LineWidth',2);
        
        px=[0, mic_pos(3,1)];
        py= [mic_pos(2,2)./2, mic_pos(2,2)./2];
        line(px, py, 'Color', 'w', 'LineWidth',2);

        px=[mic_pos(3,1)./2, mic_pos(3,1)./2];
        py= [0, mic_pos(2,2)];
        line(px, py, 'Color', 'w', 'LineWidth',2);

        scatter(mic_pos(:,1), mic_pos(:,2), 80, 'k', 'filled');
        text(mic_pos(:,1) + 0.01, mic_pos(:,2) + 0.01, ...
            arrayfun(@(i) sprintf('M%d',i), 1:4, 'UniformOutput', false));
        title('Localização estimada dos impactos (2D)');
        xlabel('x (m)'); ylabel('y (m)');
        axis equal;
        grid minor;
        return;
    end

    % Adiciona nova posição
    if isempty(pos_list)
        pos_list = [x y];
    elseif size(pos_list,1) < max_points
        pos_list = [pos_list; x y];
    else
        pos_list = [pos_list(2:end,:); x y];  % remove o mais antigo
    end

    % Atualizar gráfico
    cla;
    hold on;
    rectangle('Position',[mic_pos(1,1), mic_pos(1,2), mic_pos(3,1), mic_pos(2,2)], ...
        'FaceColor',[0, 0.5, 0.5],'EdgeColor','w','LineWidth',2);

    px=[0, mic_pos(3,1)];
    py= [mic_pos(2,2)./2, mic_pos(2,2)./2];
    line(px, py, 'Color', 'w', 'LineWidth',2);

    px=[mic_pos(3,1)./2, mic_pos(3,1)./2];
    py= [0, mic_pos(2,2)];
    line(px, py, 'Color', 'w', 'LineWidth',2);

    scatter(mic_pos(:,1), mic_pos(:,2), 80, 'k', 'filled');
    text(mic_pos(:,1) + 0.01, mic_pos(:,2) + 0.01, ...
        arrayfun(@(i) sprintf('M%d',i), 1:4, 'UniformOutput', false));

    % Desenhar os impactos com transparência crescente
    n = size(pos_list,1);
    for i = 1:n
        alpha = (i / n)^1.5;  % mais antigo = mais transparente
        scatter(pos_list(i,1), pos_list(i,2), 100, ...
            'MarkerFaceColor', base_color, ...
            'MarkerEdgeColor', 'k', ...
            'MarkerFaceAlpha', alpha, ...
            'MarkerEdgeAlpha', alpha);
    end

    title('Localização estimada dos impactos (2D)');
    xlabel('x (m)');
    ylabel('y (m)');
    drawnow;
end
