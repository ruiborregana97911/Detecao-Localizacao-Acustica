    %calculo do tempo 
%prog para o calculo dos tdoa entre cada par de microfones


    clear all;clc;
    c = 343;  % velocidade do som (m/s)
    
    syms x y real
    
    d_x=0.8;
    d_y=0.5;

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
    
    
    p = [9.76, -2.42];
    fprintf('\nPonto (%.2f, %.2f):\n', p(1), p(2));
    fprintf('Δt_{12} = %.2f ms\n', delta12_func(p)*1e3);
    fprintf('Δt_{13} = %.2f ms\n', delta13_func(p)*1e3);
    fprintf('Δt_{14} = %.2f ms\n', delta14_func(p)*1e3);
    
    
    tdoa = [delta12_func(p);delta13_func(p);delta14_func(p)];

    loc = LocalizadorTDOA2D(mic_pos,c);
    
%% teste da funcao de loc com base na do prof daniel 

count = 0;
err_lin_ls = 0;
err_nls = 0;
th_err = 5; %margem maxima para o erro

for px = 0:0.05:d_x
    for py = 0:0.05:d_y
        p=[px, py];

        tdoa = [delta12_func(p);delta13_func(p);delta14_func(p)];

        pos_est = localizar_2D_TDOA_ls(mic_pos, tdoa, c);

        pos_est=pos_est';
        
        [x, resnorm, f] = locate_2D_NLS(tdoa(1), tdoa(2), tdoa(3), mic_pos', c);

        %tdoa2 = [delta12_func(p) delta13_func(p) delta14_func(p)];
        pp= loc.localizar(tdoa);

        disp('------------------------------------------------');
        fprintf('Ponto (%.2f, %.2f) cm\n', p(1)*100, p(2)*100);
        fprintf('Calc lin_ls (%.2f, %.2f) cm\n', pos_est(1)*100, pos_est(2)*100);
        fprintf('Calc NLS (%.2f, %.2f) cm\n', x(1)*100, x(2)*100);
        fprintf('Calc loc (%.2f, %.2f) cm\n', pp(1)*100, pp(2)*100);
        fprintf('t12: %.2f | t13: %.2f | t14: %.2f (ms)\n', tdoa(1)*1e3, tdoa(2)*1e3, tdoa(3)*1e3)
        fprintf('d12: %.2f | d13: %.2f | d14: %.2f (m)\n', tdoa(1)*c, tdoa(2)*c, tdoa(3)*c)
        disp('------------------------------------------------');

        if(abs(p(1)*100 - pos_est(1)*100) > th_err || abs(p(2)*100 - pos_est(2)*100) > th_err)
            err_lin_ls = err_lin_ls +1;
        end

        if(abs(p(1)*100 - x(1)*100) > th_err || abs(p(2)*100 - x(2)*100) > th_err)
            err_nls = err_nls +1;
        end

        count = count +1;

    end
end


fprintf('erro lin_ls: %2.f  \n', (err_lin_ls/count) * 100);

fprintf('erro nls: %2.f  \n', (err_nls/count) * 100);



%%

function pos_est = localizar_2D_TDOA_ls(mic_pos, tdoa, c)
    %nesta funcao o mic_pos tem de estar em transposto

    % Número de microfones
    N = size(mic_pos, 2);
    
    % Construção da matriz Ct (diferenças de posição em relação ao mic1)
    Ct = mic_pos(:, 2:end);
    
    % Diferenças de distância estimadas (baseadas nas TDOA)
    delta_d = tdoa * c;
    
    
    % Vetor r conforme a fórmula
    r = zeros(N-1, 1);
    for i = 1:N-1
        Ct(:,i) = Ct(:,i) - mic_pos(:, 1);
        r(i) = 0.5 * (norm(Ct(:,i))^2 - delta_d(i)^2);
    end
    
    % Resolução por mínimos quadrados
    A = (Ct * Ct') \ Ct;
    Ar = A * r;
    Ad = -A * delta_d;
    
    % Resolução da equação quadrática: 
    % a*d1^2 + b*d1 + c = 0
    
    a = Ad(1).^2 + Ad(2).^2 + 1;
    b = 2*(Ar(1)*Ad(1) + Ar(2)*Ad(2));
    c = Ar(1).^2 + Ar(2).^2;
    
    sq = sqrt(b.^2-4*a*c);
    s = real(([sq -sq]-b)/(2*a));
    
    
    % Estimar posição relativa e converter para absoluta
    pos_est = Ad * s + Ar + mic_pos(:,1);



end
%fprintf('\nPonto (%.2f, %.2f):\n', p(1), p(2));

%%

function [x, resnorm, f] = locate_2D_NLS(t12, t13, t14, mic_pos, c)
    x0 = mean(mic_pos);  % ponto inicial

    %norma eucladiana = sqrt(.^2) 
    f = @(p) [
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(2,:)) - c*t12;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(3,:)) - c*t13;
        norm(p - mic_pos(1,:)) - norm(p - mic_pos(4,:)) - c*t14
    ];

    opts = optimoptions('lsqnonlin', ...
    'Display', 'off', ...
    'MaxIterations', 6, ...
    'OptimalityTolerance', 1e-3, ...
    'FunctionTolerance', 1e-3, ...
    'StepTolerance', 1e-4);

    %[x, resnorm] = lsqnonlin(f, x0, mic_pos(1,:), mic_pos(4,:), opts);
    [x, resnorm] = lsqnonlin(f, x0, [], [], opts);

    %debug
    %fprintf("Estimativa inicial: [%.2f, %.2f]\n", x0(1), x0(2));
    %fprintf("Posição estimada: [%.2f, %.2f]\n", x(1), x(2));
    %fprintf("Erro final: %.4e\n", resnorm);

end




    
    

