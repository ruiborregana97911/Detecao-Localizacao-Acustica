   %calculo do tempo 
%prog para o calculo dos tdoa entre cada par de microfones
%teste de quanto demora o calculo da classe TDOA

    clear all;clc;
    c = 343;  % velocidade do som (m/s)
    
    syms x y real
    
    d_x=2.738;
    d_y=1.528;

    m1 = [0, 0];
    m2 = [0, d_y];
    m3 = [d_x, 0];
    m4 = [d_x, d_y];

    mic_pos=[m1' m2' m3' m4'];
    
    % dist fonte para cada microfone
    d1 = sqrt((x - m1(1)).^2 + (y - m1(2)).^2);
    d2 = sqrt((x - m2(1)).^2 + (y - m2(2)).^2);
    d3 = sqrt((x - m3(1)).^2 + (y - m3(2)).^2);
    d4 = sqrt((x - m4(1)).^2 + (y - m4(2)).^2);
    
    % Δt_{1j} = (d1 - dj)/c
    delta_12 = simplify((d1 - d2)/c);
    delta_13 = simplify((d1 - d3)/c);
    delta_14 = simplify((d1 - d4)/c);
    
    delta12_func = matlabFunction(delta_12, 'Vars', {[x y]});
    delta13_func = matlabFunction(delta_13, 'Vars', {[x y]});
    delta14_func = matlabFunction(delta_14, 'Vars', {[x y]});
    
    % 
    % p = [9.76, -2.42];
    % fprintf('\nPonto (%.2f, %.2f):\n', p(1), p(2));
    % fprintf('Δt_{12} = %.2f ms\n', delta12_func(p)*1e3);
    % fprintf('Δt_{13} = %.2f ms\n', delta13_func(p)*1e3);
    % fprintf('Δt_{14} = %.2f ms\n', delta14_func(p)*1e3);
    
    
    %tdoa = [delta12_func(p);delta13_func(p);delta14_func(p)];

    loc = LocalizadorTDOA2D(mic_pos,c);
    
%% teste da funcao de loc 

N_iter = 100;
tempos = zeros(N_iter*41922,1);
idx=1;
for i=1:N_iter
    for px = 0:0.01:d_x
        for py = 0:0.01:d_y
            p=[px, py];
            
            
            tdoa = [delta12_func(p);delta13_func(p);delta14_func(p)];
            
            tic
            pp= loc.localizar(tdoa);
            tempos(idx) = toc;
            idx = idx+1;
            
        end
    end
end


fprintf('Tempo medio: %.6f s\n',mean(tempos));
fprintf('Tempo maximo: %.6f s\n',max(tempos));
histogram(tempos*1e6, 10);
xlabel('Tempo [µs]');
ylabel('Contagem');
title('Distribuição dos tempos de execução');