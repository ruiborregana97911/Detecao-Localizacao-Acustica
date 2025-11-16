%classe feita para usar como funcao de calculo de localizaca linearizada



classdef LocalizadorTDOA2D
    properties (Access = private)
        mic_pos     % 2xN matriz de posições dos microfones
        c           % velocidade do som
        Ct          % matriz de diferenças de posição
        A           % matriz de pseudo-inversa
        ref_pos     % posição do microfone de referência
        N           % número de microfones
    end
    
    methods
        function obj = LocalizadorTDOA2D(mic_pos, c)
            % Construtor
            obj.mic_pos = mic_pos;
            obj.c = c;
            obj.N = size(mic_pos, 2);
            obj.ref_pos = mic_pos(:,1);
            obj.Ct = mic_pos(:,2:end) - obj.ref_pos;
            obj.A = (obj.Ct * obj.Ct') \ obj.Ct;
        end

        function pos_est = localizar(obj, tdoa)
            delta_d = tdoa * obj.c;
            r = 0.5 * (sum(obj.Ct.^2,1)' - delta_d.^2);

            Ar = obj.A * r;
            Ad = -obj.A * delta_d;

            a = sum(Ad.^2) - 1;
            b = 2 * sum(Ar .* Ad);
            c1 = sum(Ar.^2);

            sq = sqrt(b.^2 - 4*a*c1);
            s = real(([-b + sq, -b - sq]) / (2*a));
            pos_cands = Ad * s + Ar + obj.ref_pos;

            pos_est = obj.choose_best(pos_cands, delta_d);
        end
    end

    methods (Access = private)
        function pos_est = choose_best(obj, pos_cands, delta_d)
            err = zeros(1, 2);
            for i = 1:2
                dists = vecnorm(pos_cands(:,i) - obj.mic_pos, 2, 1);
                de_est = dists(1) - dists(2:end);
                err(i) = norm(de_est(:) - delta_d(:));
            end
            [~, idx_best] = min(err);
            pos_est = pos_cands(:, idx_best);
        end
    end
end
