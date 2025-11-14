classdef ImpactPlot2D < handle
    properties (Access = private)
        fig
        ax
        mic_pos
        max_points = 7
        pos_list = []
        scatter_handles
        base_color = [0.9290, 0.6940, 0.1250]
    end

    methods
        function obj = ImpactPlot2D(mic_pos, max_points)
            obj.mic_pos = mic_pos;
            if nargin > 1
                obj.max_points = max_points;
            end
            obj.setupFigure();
        end

        function reset(obj)
            obj.pos_list = [];
            obj.scatter_handles = gobjects(obj.max_points, 1);

            cla(obj.ax);

            % Dimensões da mesa
            mesa_x = obj.mic_pos(1,1);
            mesa_y = obj.mic_pos(1,2);
            mesa_w = obj.mic_pos(3,1);
            mesa_h = obj.mic_pos(2,2);

            % Mesa
            rectangle(obj.ax, 'Position', [mesa_x, mesa_y, mesa_w, mesa_h], ...
                'FaceColor', [0, 0.5, 0.5], 'EdgeColor', 'w', 'LineWidth', 2);

            % Linhas centrais
            line(obj.ax, [0, mesa_w], [mesa_h/2, mesa_h/2], 'Color', 'w', 'LineWidth', 2);
            line(obj.ax, [mesa_w/2, mesa_w/2], [0, mesa_h], 'Color', 'w', 'LineWidth', 2);

            % Microfones
            scatter(obj.ax, obj.mic_pos(:,1), obj.mic_pos(:,2), 80, 'k', 'filled');
            text(obj.ax, obj.mic_pos(:,1) + 0.01, obj.mic_pos(:,2) + 0.01, ...
                arrayfun(@(i) sprintf('M%d',i), 1:4, 'UniformOutput', false));

            % Eixos
            margem = 0.05;
            xlim(obj.ax, [mesa_x - margem, mesa_x + mesa_w + margem]);
            ylim(obj.ax, [mesa_y - margem, mesa_y + mesa_h + margem]);

            title(obj.ax, 'Localização estimada dos impactos (2D)');
            xlabel(obj.ax, 'x (m)');
            ylabel(obj.ax, 'y (m)');
            axis(obj.ax, 'equal');
            grid(obj.ax, 'minor');
        end

        function addImpact(obj, x, y)
            if isempty(obj.pos_list)
                obj.pos_list = [x y];
            elseif size(obj.pos_list,1) < obj.max_points
                obj.pos_list = [obj.pos_list; x y];
            else
                obj.pos_list = [obj.pos_list(2:end,:); x y];
            end

            n = size(obj.pos_list, 1);
            for i = 1:n
                alpha = (i / n)^1.5;

                if ~isgraphics(obj.scatter_handles(i))
                    obj.scatter_handles(i) = scatter(obj.ax, obj.pos_list(i,1), obj.pos_list(i,2), 100, ...
                        'MarkerFaceColor', obj.base_color, ...
                        'MarkerEdgeColor', 'k', ...
                        'MarkerFaceAlpha', alpha, ...
                        'MarkerEdgeAlpha', alpha);
                else
                    set(obj.scatter_handles(i), ...
                        'XData', obj.pos_list(i,1), ...
                        'YData', obj.pos_list(i,2), ...
                        'MarkerFaceAlpha', alpha, ...
                        'MarkerEdgeAlpha', alpha);
                end
            end

            for i = (n+1):obj.max_points
                if isgraphics(obj.scatter_handles(i))
                    set(obj.scatter_handles(i), 'XData', NaN, 'YData', NaN);
                end
            end

            drawnow limitrate;  % atualização eficiente do gráfico
        end
    end

    methods (Access = private)
        function setupFigure(obj)
            obj.fig = figure('Name', 'Visualizador de Impactos');
            obj.ax = axes(obj.fig);
            set(obj.ax, 'Color', [0.3010, 0.7450, 0.9330]);
            hold(obj.ax, 'on');
        end
    end
end
