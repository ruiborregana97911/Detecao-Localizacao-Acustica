classdef CircularBuffer_v2 < handle
    properties
        buffer              % [numChannels x bufferSize]
        bufferSize          % número total de amostras no buffer
        numChannels         % canais de áudio registados
        writeIndex          % posição de escrita
        readIndex           % posição de leitura
        availableSamples    % quantas amostras estão no buffer
        endwrite            % flag de fim de escrita
    end

    methods
        function obj = CircularBuffer_v2(numChannels, bufferSize)
            obj.bufferSize = bufferSize;
            obj.numChannels = numChannels;
            obj.buffer = zeros(numChannels, bufferSize);
            obj.writeIndex = 1;
            obj.readIndex = 1;
            obj.availableSamples = 0;
            obj.endwrite = false;
        end
        
        function write(obj, newData)
            numSamples = size(newData, 2);

            % Índices circulares de escrita
            idxs = mod((obj.writeIndex:obj.writeIndex+numSamples-1)-1, obj.bufferSize) + 1;

            % Escrever de uma vez
            obj.buffer(:, idxs) = newData;

            % Atualizar writeIndex
            obj.writeIndex = mod(obj.writeIndex + numSamples - 1, obj.bufferSize) + 1;

            % Atualizar availableSamples
            obj.availableSamples = min(obj.availableSamples + numSamples, obj.bufferSize);

            % Se sobrescreveu, move o readIndex
            if obj.availableSamples == obj.bufferSize
                obj.readIndex = obj.writeIndex;  
            end
        end

        function data = read(obj, numSamples)
            if obj.availableSamples < numSamples
                error('Buffer: nao ha dados suficientes para leitura');
            end

            % Índices circulares de leitura
            idxs = mod((obj.readIndex:obj.readIndex+numSamples-1)-1, obj.bufferSize) + 1;

            % Ler de uma vez
            data = obj.buffer(:, idxs);

            % Atualizar readIndex
            obj.readIndex = mod(obj.readIndex + numSamples - 1, obj.bufferSize) + 1;

            % Atualizar contador
            obj.availableSamples = obj.availableSamples - numSamples;
        end

        function n = getAvailableSamples(obj)
            n = obj.availableSamples;
        end
        
        function enableEndWrite(obj)
            obj.endwrite = true;
        end

        function n = getEndWrite(obj)
            n = obj.endwrite;
        end
    
        function data = peekAroundReadIndex(obj, before, after, channel)
            if nargin < 4
                channel = [];  % devolve todos os canais se não especificado
            end

            % Índices circulares de leitura (sem alterar o readIndex real!)
            idxs = mod((obj.readIndex-before : obj.readIndex+after)-1, obj.bufferSize) + 1;

            % Ler de uma vez
            data = obj.buffer(:, idxs);

            % Selecionar canal se pedido
            if ~isempty(channel)
                data = data(channel, :);
            end
        end
    end
end
