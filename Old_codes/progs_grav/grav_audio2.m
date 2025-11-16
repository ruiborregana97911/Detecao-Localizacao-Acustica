function [audioData1, audioData2] = grav_audio2()
    % Cria a janela principal
    fig = figure('Name', 'Gravador de Áudio', 'NumberTitle', 'off', 'Position', [100, 100, 600, 400]);
    
    % Inicializa os parâmetros de gravação
    Fs = 44100;                 % Frequência de amostragem
    nBits = 16;                 % Bits por amostra
    nCanais = 1;                % Número de canais (mono)
    
    % Lista de dispositivos de entrada (corrigido)
    devs = audiodevinfo; % Obter informações sobre todos os dispositivos
    if isfield(devs, 'input') && ~isempty(devs.input)
        numDevs = length(devs.input); % Número de dispositivos de entrada
        disp('Dispositivos de Entrada de Áudio:');
        
        for i = 1:numDevs
            fprintf('%d: %s\n', i, devs.input(i).Name); % Exibe os dispositivos
        end
    else
        error('Nenhum dispositivo de entrada encontrado.');
    end
    
    % Solicita ao usuário escolher o microfone
    micIndex = input('Escolha o número do microfone: ');
    if micIndex < 1 || micIndex > numDevs
        error('Número de microfone inválido.');
    end
    
    % Cria o objeto de gravação selecionando o microfone
    recObj = audiorecorder(Fs, nBits, nCanais, devs.input(micIndex).ID);  % Ajusta o dispositivo selecionado
    time = 5;                % Duração de gravação
    
    % Criação de controles de interface
    uicontrol(fig, 'Style', 'text', 'Position', [20, 350, 100, 20], 'String', 'Duração (s):');
    in_time = uicontrol(fig, 'Style', 'edit', 'Position', [120, 350, 100, 25], 'String', num2str(time));
    
    botaoGravar = uicontrol(fig, 'Style', 'togglebutton', 'Position', [250, 350, 100, 25], ...
                            'String', 'Iniciar/Parar Gravação', 'Callback', @iniciarPararGravacao);
    botaoZoomMais = uicontrol(fig, 'Style', 'pushbutton', 'Position', [370, 350, 100, 25], ...
                              'String', 'Aumentar Zoom', 'Callback', @zoomMais);
    botaoZoomMenos = uicontrol(fig, 'Style', 'pushbutton', 'Position', [480, 350, 100, 25], ...
                               'String', 'Diminuir Zoom', 'Callback', @zoomMenos);

    % Inicializa o gráfico
    ax = axes('Parent', fig, 'Position', [0.1, 0.1, 0.8, 0.5]);
    hPlot = plot(ax, NaN, NaN);
    xlabel(ax, 'Tempo [s]');
    ylabel(ax, 'Amplitude');
    title(ax, 'Sinal de Entrada do Microfone');
    grid(ax, 'on');

    % Variáveis de controle de zoom
    fatorZoom = 0.5;         % Fator de zoom padrão
    escalaGrafico = 1;       % Multiplicador de escala para o zoom
    
    % Dados de áudio gravados
    audioData1 = [];
    audioData2 = [];

    % Função de callback para iniciar/parar gravação
    function iniciarPararGravacao(~, ~)
        % Obtém a duração do campo de entrada
        time = str2double(get(in_time, 'String'));
        
        if get(botaoGravar, 'Value') == 1
            % Inicia a gravação
            disp('Gravando áudio...');
            set(botaoGravar, 'String', 'Parar Gravação');
            recordblocking(recObj, time);
            disp('Gravação concluída.');
            
            % Obtém dados de áudio e faz o plot
            dadosAudio = getaudiodata(recObj);
            t = linspace(0, time, length(dadosAudio));  % Vetor de tempo
            set(hPlot, 'XData', t, 'YData', dadosAudio);
            xlim(ax, [0 time * escalaGrafico]);
            ylim(ax, [-1 1]);
            
            % Armazena os dados de áudio para a correlação cruzada
            if isempty(audioData1)
                audioData1 = dadosAudio;  % Primeira gravação
            else
                audioData2 = dadosAudio;  % Segunda gravação
            end
            
        else
            % Para a gravação
            set(botaoGravar, 'String', 'Iniciar/Parar Gravação');
        end
    end

    % Função de callback para aumentar zoom
    function zoomMais(~, ~)
        % Cálculo dos valores da nova janela
        limites = xlim(ax);
        centro = mean(limites);
        intervalo = diff(limites)*fatorZoom;

        % Ajuste da nova janela
        xlim(ax, [centro - intervalo/2, centro + intervalo/2]);
    end

    % Função de callback para diminuir zoom
    function zoomMenos(~, ~)
        % Cálculo dos valores da nova janela
        limites = xlim(ax);
        centro = mean(limites);
        intervalo = diff(limites)/fatorZoom;

        % Ajuste da nova janela
        xlim(ax, [centro - intervalo/2, centro + intervalo/2]);
    end
    
    % Espera até que a figura seja fechada
    waitfor(fig);
end
