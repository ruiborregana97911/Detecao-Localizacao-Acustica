clear all,clc;

%% teste de update_point_1D


posicao= [10,-15]; 
d=70;

update_point_1D(0,d,true);

for i=1:length(posicao)
    update_point_1D(posicao(i),d);
    pause(1);
end

update_point_1D(0,d,true);





