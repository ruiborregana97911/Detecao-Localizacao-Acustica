% UPDATE_POINT_1D --> Registra e exibe a posição de impactos sonoros em 1
% dimensão
%
% Sintaxe:
%   update_point_1D(pos_s, d)        - Adiciona um impacto na posição 'pos_s'.
%   update_point_1D(pos_s, d, reset)  - Limpa dados antigos guardados e faz um novo grafico limpo.
%
% Entradas:
%   pos_s  - Posição do impacto em cm.
%   d      - Distância entre os microfones em cm.
%   reset  - (Opcional) Booleano para limpar dados antigos (default = false).
%
% Esta função mantém um histórico de impactos e mostra-os , em um gráfico,
% com um limite máximo de 7 pontos visíveis. Se 'reset' for TRUE, 
% o histórico é apagado e o gráfico reinicializado. Aconselha-se que se
% faça um reset = true numa nova inicialização da função, para garantir que a funcao não
% têm dados antigos que perturbem os novos. Ao chamar o reset = true, ter
% em atenção que os valores dados a 'pos_s' são ignorados! Depois da
% primeira chamada da função, necessario fazer um pause() de pelo menos 1 segundo para a
% funcao nao interferir com o resto do codigo
%
% Autor: [Rui Borregana]
% Data: [22/02/2025]


function update_point_1D(pos_s, d, reset)
    persistent positions colors color_palette
    
    if nargin > 2 && reset
        % Redefinir variáveis persistentes
        positions = [];
        colors = [];
        color_palette = [];
        
        % Inicializar novo gráfico para visualização
        figure;
        hold on;
        plot([-d/2 d/2], [0 0], 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10); % Microfones
        line([-d/2 d/2], [0 0], 'Color', 'b');  % linha entre microfones
        title('Posicao da fonte de som');
        xlabel('Posicao (cm)');
        ylabel('Impacto');
        grid on;
        
        return; % Termina a execução da função
    end

    % Definir número máximo de pontos e cores
    max_points = 7;  
    if isempty(color_palette)
        color_palette = [
            1, 0, 0;   % vermelho
            0, 1, 0;   % verde
            0, 0, 1;   % azul
            1, 1, 0;   % amarelo
            0, 1, 1;   % ciano
            1, 0, 1;   % magenta
            0.5, 0.5, 0.5; % cinza
        ];
    end
    
    % Inicializar cores e posições
    if isempty(positions)
        positions = [];
        colors = [];
    end
    
    % Adicionar nova posição e cor
    if length(positions) < max_points
        positions = [positions, pos_s];
        colors = [colors; color_palette(length(positions), :)];
    else
        % Substituir o ponto mais antigo
        positions = [positions(2:end), pos_s];
        colors = [colors(2:end, :); colors(1, :)];
    end
    
    % Limpar e redesenhar todos os pontos
    cla; % Limpar gráfico atual
    hold on;
    plot([-d/2 d/2], [0 0], 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 10); % Microfones
    line([-d/2 d/2], [0 0], 'Color', 'b'); % Linha dos microfones
    for i = 1:length(positions)
        plot(positions(i), 0, 'o', 'MarkerFaceColor', colors(i, :), 'MarkerSize', 8);
    end
    drawnow; % Atualizar o gráfico
end
