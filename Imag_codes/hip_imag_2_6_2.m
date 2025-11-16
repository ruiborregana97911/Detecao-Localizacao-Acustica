% hip_single_pair.m
clc; clear; close all;

% --- definir microfones e ponto p (ajusta como quiseres) ---
m1 = [-1, 0];    % micófone i
m2 = [ 1, 0];    % micófone j
p  = [ 0.6, 0.35]; % ponto da fonte (escolhido para ficar sobre a hipérbole)

% --- distâncias e delta (Delta d_ij) ---
di = norm(p - m1);
dj = norm(p - m2);
delta = di - dj;             % delta = ||p-m1|| - ||p-m2||

% --- definir grelha suficiente (expande automaticamente em torno dos pontos) ---
margin = 1.2;
xmin = min([m1(1), m2(1), p(1)]) - margin;
xmax = max([m1(1), m2(1), p(1)]) + margin;
ymin = min([m1(2), m2(2), p(2)]) - margin;
ymax = max([m1(2), m2(2), p(2)]) + margin;

nx = 500; ny = 500; % resolução (aumenta se quiseres linhas mais suaves)
[xg, yg] = meshgrid(linspace(xmin, xmax, nx), linspace(ymin, ymax, ny));

% --- calcular D(x,y) = ||(x,y)-m1|| - ||(x,y)-m2|| ---
D = sqrt((xg - m1(1)).^2 + (yg - m1(2)).^2) - sqrt((xg - m2(1)).^2 + (yg - m2(2)).^2);

% --- plot ---
fig = figure('Color','w','Units','normalized','Position',[0.2 0.2 0.45 0.45]);
hold on; axis equal;

% desenhar a hipérbole correspondente a D = delta
[C,hC] = contour(xg, yg, D, [delta delta], '-', 'LineWidth', 1.6);
if isempty(C)
    warning('Nenhuma hipérbole encontrada no intervalo atual. Aumenta margem/resolução ou escolhe p diferente.');
end

plot([-2 2], [0 0], ':', 'Color', [0.5 0.5 0.5], 'LineWidth', 0.8);


% desenhar microfones e ponto p
plot(m1(1), m1(2), 'k^', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(m2(1), m2(2), 'k^', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
plot(p(1),  p(2),  'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

% linhas que ligam p aos microfones (para depois transformares em setas no Inkscape)
%plot([p(1) m1(1)], [p(2) m1(2)], ':', 'Color',[0.4 0.4 0.4], 'LineWidth', 1.0);
%plot([p(1) m2(1)], [p(2) m2(2)], ':', 'Color',[0.4 0.4 0.4], 'LineWidth', 1.0);

% rótulos
text(m1(1), m1(2) - 0.12, '$m_i$', 'Interpreter','latex', 'HorizontalAlignment','center', 'FontSize',12);
text(m2(1), m2(2) - 0.12, '$m_j$', 'Interpreter','latex', 'HorizontalAlignment','center', 'FontSize',12);
text(p(1)+0.05, p(2)+0.05, '$\mathbf{p}$', 'Interpreter','latex', 'Color','k', 'FontSize',12);

% rótulos das distâncias (posicionados no ponto médio das linhas)
mid1 = (p + m1)/2;
mid2 = (p + m2)/2;
text(mid1(1), mid1(2) + 0.06, sprintf('$d_i$'), 'Interpreter','latex', 'HorizontalAlignment','center', 'FontSize',10);
text(mid2(1), mid2(2) + 0.06, sprintf('$d_j$'), 'Interpreter','latex', 'HorizontalAlignment','center', 'FontSize',10);

% estética final
axis([xmin xmax ymin ymax]);
set(gca, 'visible', 'off');   % remove eixos; se preferires os eixos, comenta esta linha
title('Hipérbole associada a um par de microfones (TDOA)', 'FontSize', 11);

