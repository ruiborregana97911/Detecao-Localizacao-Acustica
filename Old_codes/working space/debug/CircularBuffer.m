classdef CircularBuffer < handle
    properties
        buffer              %data [numChanenels x buffersize]
        bufferSize          %numero total de amostras no buf
        numChannels         %canais de audio registados
        writeIndex          %marca onde escrever a proxima amostra
        readIndex           %marca onde comeca a proxima leitura
        availableSamples    %Quantas amostras disponiveis para leitura
        endwrite    %fim de escrita
    end

    methods
        function obj = CircularBuffer(numChannels, bufferSize)
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
            for i= 1:numSamples
                obj.buffer(:, obj.writeIndex) = newData(:, i);
                obj.writeIndex = mod(obj.writeIndex, obj.bufferSize) + 1;

                if(obj.availableSamples < obj.bufferSize)
                    obj.availableSamples = obj.availableSamples + 1;
                else
                    %buffer cheio, sobrescrevendo: mover readIndex
                    obj.readIndex = mod(obj.readIndex, obj.bufferSize) + 1;
                end
            end
        end

        function data = read(obj, numSamples)
            if(obj.availableSamples < numSamples)
                error('Buffer: nao a dados suficientes para leitura');
            end

            data = zeros(obj.numChannels, numSamples);
            for i= 1:numSamples
                data(:, i)= obj.buffer(:, obj.readIndex);
                obj.readIndex= mod(obj.readIndex, obj.bufferSize) + 1;
            end
            obj.availableSamples= obj.availableSamples - numSamples;
        end

        function n = getAvailableSamples(obj)
            n= obj.availableSamples;
        end
        
        function enableEndWrite(obj)
            obj.endwrite = true;
        end

        function n = getEndWrite(obj)
            n= obj.endwrite;
        end

     function data = peekAroundReadIndex(obj, before, after, channel)
        if nargin < 4
            channel = [];  % se não for passado, devolve todos os canais
        end
    
        totalSamples = before + after + 1;
        data = zeros(obj.numChannels, totalSamples);
        
        for i = 1:totalSamples
            idx = mod(obj.readIndex - before - 1 + i - 1, obj.bufferSize) + 1;
            data(:, i) = obj.buffer(:, idx);
        end
    
        if ~isempty(channel)
            data = data(channel, :);  % devolve só o canal escolhido
        end
    end



           
    end
end