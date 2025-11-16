% --- Configuração ---
d = 3; % distância entre microfones (arbitrário, em metros)
Mi = -d; % posição do microfone i (à esquerda)
Mj =  d; % posição do microfone j (à direita)
S  =  1; % posição da fonte (exemplo, deslocada para a direita)

% --- Figura ---
figure;
hold on; axis equal;
xlim([-1.5*d, 1.5*d]);
ylim([-1.5, 1.5]);
axis off;

% Linha de referência (reta 1D)
plot([-d, d], [0 0], 'k-', 'LineWidth', 0.75);


% Origem no meio
plot(0,0,'k|','MarkerFaceColor','k','MarkerSize',5);
text(0, -0.15, '0', 'Interpreter','latex', 'HorizontalAlignment','center');

xline(Mj,'k--');
xline(Mi,'k--');
y_lim = [-1.5 0];       % limites no eixo y
line([S S], y_lim, 'Color', 'k', 'LineStyle', '--');

% Microfones
plot(Mi, 0, 'ko', 'MarkerFaceColor', 'b', 'MarkerSize', 8);
plot(Mj, 0, 'ko', 'MarkerFaceColor', 'b', 'MarkerSize', 8);

% Fonte
plot(S, 0, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);

% Labels
text(Mi, -0.1, '$M_i$', 'Interpreter','latex', 'HorizontalAlignment','center');
text(Mj, -0.1, '$M_j$', 'Interpreter','latex', 'HorizontalAlignment','center');
text(S,  0.15, '$S$',   'Interpreter','latex', 'HorizontalAlignment','center');

%%

figure

text(0.1, 0.5, '$d_i$', 'Interpreter','latex', 'HorizontalAlignment','center');
text(0.4, 0.5, '$d_j$', 'Interpreter','latex', 'HorizontalAlignment','center');
text(0.8,  0.5, '$d$',   'Interpreter','latex', 'HorizontalAlignment','center');
axis off