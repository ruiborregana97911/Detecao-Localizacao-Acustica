classdef EnergyTracker < handle
    properties
        buffer      % Matriz (num_channels x buffer_length)
        idx         % Índice circular atual
        count       % Número de valores inseridos (até buffer cheio)
        buffer_len  % Tamanho do buffer (ex: amostras em 1 ms)
        sum_energy  % Soma corrente por canal
        num_channels
    end

    methods
        function obj = EnergyTracker(num_channels, buffer_len)
            obj.num_channels = num_channels;
            obj.buffer_len = buffer_len;
            obj.buffer = zeros(num_channels, buffer_len);
            obj.idx = 1;
            obj.count = 0;
            obj.sum_energy = zeros(num_channels, 1);
        end

        function update(obj, new_energy)
            % new_energy é um vetor (num_channels x 1)
            old_energy = obj.buffer(:, obj.idx);
            obj.buffer(:, obj.idx) = new_energy;
            obj.sum_energy = obj.sum_energy - old_energy + new_energy;
            obj.idx = mod(obj.idx, obj.buffer_len) + 1;
            obj.count = min(obj.count + 1, obj.buffer_len);
        end

        function avg = getAverage(obj)
            if obj.count == 0
                avg = zeros(obj.num_channels, 1);
            else
                avg = obj.sum_energy / obj.count;
            end
        end
    end
end
