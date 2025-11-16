% Figura ilustrativa do problema 2D de localização por TDOA
clc; clear; close all;

% --- Coordenadas dos microfones ---
M1 = [3, 1];
M2 = [-2, 2];
M3 = [1, -3];

% --- Fonte sonora ---
S = [1.5, 0.5];

% --- Diferenças de distâncias (definem as hipérboles) ---
d12 = norm(S - M1) - norm(S - M2);
d13 = norm(S - M1) - norm(S - M3);
d23 = norm(S - M2) - norm(S - M3);

% --- Geração de grelha ---
[x, y] = meshgrid(linspace(-4, 4, 400), linspace(-4, 4, 400));

% --- Cálculo das diferenças de distância em cada ponto ---
D12 = sqrt((x - M1(1)).^2 + (y - M1(2)).^2) - sqrt((x - M2(1)).^2 + (y - M2(2)).^2);
D13 = sqrt((x - M1(1)).^2 + (y - M1(2)).^2) - sqrt((x - M3(1)).^2 + (y - M3(2)).^2);
D23 = sqrt((x - M2(1)).^2 + (y - M2(2)).^2) - sqrt((x - M3(1)).^2 + (y - M3(2)).^2);

% --- Figura ---
figure('Color','w'); hold on; axis equal;
set(gca, 'XColor', 'none', 'YColor', 'none')  % oculta apenas os eixos
contour(x, y, D12, [d12 d12], 'b-', 'LineWidth', 1);
contour(x, y, D13, [d13 d13], 'g-', 'LineWidth', 1);
contour(x, y, D23, [d23 d23], 'r-', 'LineWidth', 1);

% --- Microfones e fonte ---
plot(M1(1), M1(2), 'k^', 'MarkerFaceColor', 'k', 'DisplayName','M_1');
plot(M2(1), M2(2), 'k^', 'MarkerFaceColor', 'k', 'DisplayName','M_2');
plot(M3(1), M3(2), 'k^', 'MarkerFaceColor', 'k', 'DisplayName','M_3');
plot(S(1), S(2), 'ko', 'MarkerFaceColor', 'k', 'DisplayName','S');

% --- Etiquetas ---
text(M1(1)-0.05, M1(2)-0.05, 'M_1', 'FontSize', 11);
text(M2(1)+0.03, M2(2)-0.05, 'M_2', 'FontSize', 11);
text(M3(1)+0.03, M3(2)+0.03, 'M_3', 'FontSize', 11);
text(S(1)+0.03, S(2), 'S', 'FontSize', 11);

xlabel('x (m)'); ylabel('y (m)');
axis([-4 4 -4 4]);

legend('Hipérbole M_1-M_2','Hipérbole M_1-M_3','Hipérbole M_2-M_3');
