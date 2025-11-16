clearvars;close all;clc;
% ---- Configuração ----
c = 343; % velocidade do som [m/s]
fs = 1;  % escala (não interessa muito, já que é só ilustrativo)

% Posições dos microfones
M = [0 0;   % M1
     2 0;   % M2
     0 2;   % M3
     2 2];  % M4

% Fonte
S = [1.2 1.5];

% Grelha para avaliar hipérboles
[x,y] = meshgrid(linspace(-0.5,2.5,400), linspace(-0.5,2.5,400));

% Inicializar figura
figure; hold on; axis equal;
xlabel('x [m]'); ylabel('y [m]');
title('Interseção de hipérboles (localização 2D)');

% Desenhar cada hipérbole para pares de microfones
pairs = [1 2; 1 3; 1 4];  % exemplo com 3 TDOAs independentes
for k=1:size(pairs,1)
    i = pairs(k,1); j = pairs(k,2);
    % Diferença de distâncias verdadeira
    delta_d = norm(S - M(i,:)) - norm(S - M(j,:));
    % Função hipérbole
    F = sqrt((x-M(i,1)).^2 + (y-M(i,2)).^2) - ...
        sqrt((x-M(j,1)).^2 + (y-M(j,2)).^2);
    % Plot da curva F = delta_d
    contour(x,y,F,[delta_d delta_d],'LineWidth',1.5);
end

% Plot microfones
plot(M(:,1),M(:,2),'ko','MarkerFaceColor','k','DisplayName','Microfones');
text(M(:,1)+0.05,M(:,2)+0.05,{'M1','M2','M3','M4'});

% Plot fonte
plot(S(1),S(2),'ro','MarkerFaceColor','r','DisplayName','Fonte');

legend;


%%

% ---- Configuração ----
M1 = [0 0];  % Microfone 1
M2 = [5 0];  % Microfone 2
S  = [4 2]; % Fonte

[x,y] = meshgrid(linspace(M1(1)-0.5,M2(1)+0.5,400), linspace(M1(1)-0.5,M2(1)+0.5,400));

% Diferença de distâncias
delta_d = norm(S - M1) - norm(S - M2);

% Função hipérbole
F = sqrt((x-M1(1)).^2 + (y-M1(2)).^2) - ...
    sqrt((x-M2(1)).^2 + (y-M2(2)).^2);

% Plot
figure; hold on; axis equal;
xlabel('x [m]'); ylabel('y [m]');
title('Hipérbole definida por dois microfones');

% Hipérbole
contour(x,y,F,[delta_d delta_d],'k','LineWidth',1.5);

% Microfones
plot(M1(1),M1(2),'bo','MarkerFaceColor','b');
text(M1(1)+0.05,M1(2)+0.05,'M_i');
plot(M2(1),M2(2),'bo','MarkerFaceColor','b');
text(M2(1)+0.05,M2(2)+0.05,'M_j');

% Distâncias (linhas destacadas)
plot([S(1) M1(1)], [S(2) M1(2)], '-k', 'LineWidth',1); % |p-mi|
plot([S(1) M2(1)], [S(2) M2(2)], '-k', 'LineWidth',1); % |p-mj|

% Fonte
plot(S(1),S(2),'ro','MarkerFaceColor','r');
text(S(1)+0.05,S(2)+0.05,'S');

% Legendas das distâncias
mid1 = (S + M1)/2;
mid2 = (S + M2)/2;
text(mid1(1), mid1(2)+0.1, '||p - m_i||', 'Color','k');
text(mid2(1), mid2(2)+0.1, '||p - m_j||', 'Color','k');


