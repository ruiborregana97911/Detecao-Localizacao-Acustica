close all;clearvars;clc
% Figura 1: TOA (Time of Arrival)
figure;
hold on; axis equal;
axis([-0.1 1.5 -0.1 1.5]);

% Fonte sonora (impacto)
source = [0, 0];
plot(source(1), source(2), 'ro', 'MarkerSize', 6, 'MarkerFaceColor','r');
text(source(1)-0.05, source(2)+0.05, 'F', 'Color','r');


% Ondas esféricas (propagação do som)
radii = [1,  1.4142];
theta = linspace(0,2*pi,200);
for r = radii
    plot(r*cos(theta), r*sin(theta), 'k--');
end

% Microfones
mic_pos = [1,0; 1,1]; % posições arbitrárias
for i = 1:size(mic_pos,1)
    plot(mic_pos(i,1), mic_pos(i,2), 'b^', 'MarkerSize', 6, 'MarkerFaceColor','b');
    text(mic_pos(i,1)-0.15, mic_pos(i,2)+0.05, sprintf('M_%d', i));
end



hold off;

