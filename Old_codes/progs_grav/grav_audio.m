%usar audiodevinfo e ver o ID do microfone!!!!!!!


function grav_audio()
    %cria a janela principal
    fig = figure('Name', 'Gravador de Áudio', 'NumberTitle', 'off', 'Position', [100, 100, 600, 400]);
    
    %inicializa os parametros de gravacao
    Fs = 44100;                 %frequencia de amostragem
    nBits = 16;                 %bits por amostra
    nCanais = 1;                %significa que so tenho um canal se som
    recObj = audiorecorder(Fs, nBits, nCanais,6);  %objeto de gravacao de audio
    time = 5;                %duracao de gravacao
    
    %criacao de controles de interface
    uicontrol(fig, 'Style', 'text', 'Position', [20, 350, 100, 20], 'String', 'Duração (s):');
    in_time = uicontrol(fig, 'Style', 'edit', 'Position', [120, 350, 100, 25], 'String', num2str(time));
    
    botaoGravar = uicontrol(fig, 'Style', 'togglebutton', 'Position', [250, 350, 100, 25], ...
                            'String', 'Iniciar/Parar Gravação', 'Callback', @iniciarPararGravacao);
    botaoZoomMais = uicontrol(fig, 'Style', 'pushbutton', 'Position', [370, 350, 100, 25], ...
                              'String', 'Aumentar Zoom', 'Callback', @zoomMais);
    botaoZoomMenos = uicontrol(fig, 'Style', 'pushbutton', 'Position', [480, 350, 100, 25], ...
                               'String', 'Diminuir Zoom', 'Callback', @zoomMenos);

    %inicializa o grafico
    ax = axes('Parent', fig, 'Position', [0.1, 0.1, 0.8, 0.5]);
    hPlot = plot(ax, NaN, NaN);
    xlabel(ax, 'Tempo [s]');
    ylabel(ax, 'Amplitude');
    title(ax, 'Sinal de Entrada do Microfone');
    grid(ax, 'on');

    %variaveis de controle de zoom
    fatorZoom = 0.5;         %fator de zoom padrao
    escalaGrafico = 1;       %multiplicador de escala para o zoom
    
    %função de callback para iniciar/parar gravacao
    function iniciarPararGravacao(~, ~)
        %obtem a duracao do campo de entrada
        time = str2double(get(in_time, 'String'));
        
        if get(botaoGravar, 'Value') == 1
            %inicia a gravacao
            disp('Gravando áudio...');
            set(botaoGravar, 'String', 'Parar Gravação');
            recordblocking(recObj, time);
            disp('Gravação concluída.');
            
            %obtem dados de audio e faz o plot
            dadosAudio = getaudiodata(recObj);
            t = linspace(0, time, length(dadosAudio));  %vetor de tempo
            set(hPlot, 'XData', t, 'YData', dadosAudio);
            xlim(ax, [0 time * escalaGrafico]);
            ylim(ax, [-1 1]);
            %set(botaoGravar, 'String', 'Iniciar/Parar Gravação');
            
        else
            %para a gravacao
            set(botaoGravar, 'String', 'Iniciar/Parar Gravação');
        end
    end

    %funcao de callback para aumentar zoom
    function zoomMais(~, ~)
        %calculo dos valores da nova janela
        limites = xlim(ax);
        centro = mean(limites);
        intervalo = diff(limites)*fatorZoom;

        %ajuste da nova janela
        xlim(ax, [centro - intervalo/2, centro + intervalo/2]);
    end

    %funcao de callback para diminuir zoom
    function zoomMenos(~, ~)
        %calculo dos valores da nova janela
        limites = xlim(ax);
        centro = mean(limites);
        intervalo = diff(limites)/fatorZoom;

        %ajuste da nova janela
        xlim(ax, [centro - intervalo/2, centro + intervalo/2]);
    end
end
