%% Figura 1: TOA (Time of Arrival)
figure;
hold on; axis equal; grid on;
title('TOA - Tempo de Chegada Absoluto');

% Fonte sonora (impacto)
source = [0, 0];
plot(source(1), source(2), 'rp', 'MarkerSize', 15, 'MarkerFaceColor','r');
text(source(1)+0.1, source(2), 'Fonte', 'Color','r');

% Microfones
mic_pos = [3,1; -2,2; 1,-3]; % posições arbitrárias
for i = 1:size(mic_pos,1)
    plot(mic_pos(i,1), mic_pos(i,2), 'bo', 'MarkerSize', 10, 'MarkerFaceColor','b');
    text(mic_pos(i,1)+0.2, mic_pos(i,2), sprintf('M%d (t_%d)', i,i));
end

% Ondas esféricas (propagação do som)
radii = [1.5, 3, 4.5];
theta = linspace(0,2*pi,200);
for r = radii
    plot(r*cos(theta), r*sin(theta), 'k--');
end

xlabel('x (m)'); ylabel('y (m)');
legend({'Fonte','Microfones'}, 'Location','best');
hold off;



%% Figura ToA (versão 2)
%close all
figure;
hold on; axis equal; 

%fonte= [-2 -3]; 
%mic_pos = [-4,4; 2,3; 4,-1]; 
fonte= [0 0];
mic_pos = [3,1; -2,2; 1,-3];

% Define the radius and center of the circle
%r = [7.2801 7.2111 6.3246];        % Radius
r = [3.1623 2.8284 3.1623];
x_center = [mic_pos(1,1) mic_pos(2,1) mic_pos(3,1)]; % X-coordinate of the center
y_center = [mic_pos(1,2) mic_pos(2,2) mic_pos(3,2)]; % Y-coordinate of the center

% Create a vector of angles from 0 to 2*pi (360 degrees)
theta = linspace(0, 2*pi, 100); % 100 points for a smooth circle
for i=1:length(r)
    % Calculate the x and y coordinates for the circle
    x = r(i) * cos(theta) + x_center(i);
    y = r(i) * sin(theta) + y_center(i);
    
    % Plot the circle
    plot(x, y, 'k--');
end

% d1
plot([mic_pos(1,1) fonte(1)], [mic_pos(1,2) fonte(2)], 'k-', 'LineWidth',2);
mid = (mic_pos(1,:)+fonte)/2;
text(mid(1), mid(2)+0.3, 'd_{1}', 'Color','k','FontWeight','bold');

% d2
plot([mic_pos(2,1) fonte(1)], [mic_pos(2,2) fonte(2)], 'k-', 'LineWidth',2);
mid = (mic_pos(2,:)+fonte)/2;
text(mid(1), mid(2)+0.3, 'd_{2}', 'Color','k','FontWeight','bold');

% d3
plot([mic_pos(3,1) fonte(1)], [mic_pos(3,2) fonte(2)], 'k-', 'LineWidth',2);
mid = (mic_pos(3,:)+fonte)/2;
text(mid(1), mid(2)+0.3, 'd_{3}', 'Color','k','FontWeight','bold');

%fonte
plot(fonte(1), fonte(2), 'ro', 'MarkerSize', 7, 'MarkerFaceColor', 'r');
text(fonte(1)+0.15, fonte(2), 'F', 'Color','r');

%micros
for i = 1:size(mic_pos,1)
    plot(mic_pos(i,1), mic_pos(i,2), 'b^', 'MarkerSize', 7, 'MarkerFaceColor','b');
    text(mic_pos(i,1)+0.22, mic_pos(i,2)+0.05, sprintf('M%d', i));
end

xlabel('x (m)'); ylabel('y (m)');
hold off;