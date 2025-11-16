clc; clear; close all;

%% Parâmetros do cenário
c = 343;                         % velocidade do som [m/s]
micro = [0 0; 4 0; 0 2; 4 2];    % posições dos 4 microfones (x,y)
source = [3.2 1.8];              % posição real da fonte
pairs = [1 2; 1 3; 1 4];         % pares de microfones
numPairs = size(pairs,1);

% Domínio do plano
x = linspace(-0.5,4.5,500);
y = linspace(-0.5,2.5,500);
[X,Y] = meshgrid(x,y);

figure('Color','w'); hold on; axis equal;
axis([-0.5 4.5 -0.5 4.5]);
set(gca,'XColor','none','YColor','none'); % remove eixos

%% Cores suaves para as hipérboles
colors = [0.2 0.4 0.8;   % azul petróleo
          1 0.8 0.1;   % cinza azulado
          0.2 0.6 0.5];  % verde azulado

%% Gerar e plotar hipérboles
for k = 1:numPairs
    i = pairs(k,1); j = pairs(k,2);
    d_i = sqrt((X-micro(i,1)).^2 + (Y-micro(i,2)).^2);
    d_j = sqrt((X-micro(j,1)).^2 + (Y-micro(j,2)).^2);
    tdoa = norm(source-micro(i,:)) - norm(source-micro(j,:));
    
    contour(X,Y,d_i-d_j-tdoa,[0 0], 'LineWidth',1.5, 'LineColor',colors(k,:));
end

%% Adicionar microfones e fonte
plot(micro(:,1), micro(:,2), '^', ...
    'MarkerSize',8, 'MarkerFaceColor','k', 'MarkerEdgeColor','k'); % microfones (triângulos pretos)

%% Adicionar etiquetas dos microfones
labels = {'M_1','M_2','M_3','M_4'};
for k = 1:size(micro,1)
    text(micro(k,1)-0.18, micro(k,2)+0.12, labels{k}, ...
        'FontSize',10, 'Color','k');
end

%% Legenda das hipérboles
legLabels = {'Par (M_1, M_2)', 'Par (M_1, M_3)', 'Par (M_1, M_4)'};
for k = 1:numPairs
    h(k) = plot(nan, nan, '-', 'Color', colors(k,:), 'LineWidth', 1.4);
end
legend(h, legLabels, 'Location', 'northoutside', 'Orientation', 'horizontal', ...
       'Box', 'off', 'FontSize', 9);

