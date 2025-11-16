%analise do classificador de 15 features

 %save('modelo_Boosted_Trees.mat','trainedModel');

%% Avaliação de modelos exportados do Classification Learner
clear; clc;

audioFolder = 'data_validation/';
files = dir(fullfile(audioFolder, '*.wav'));
numFiles= length(files);

% Features usadas no treino
name_features = {'RMS','Waveform Length','Peak Ratio','Skewness', ...
    'Spectral Rolloff Frequency','Spectral Flatness', ...
    'Spectral Kurtosis','Spectral Bandwidth', ...
    'Rise Time','Fall Time'};
for k=6:10
    name_features{end+1} = sprintf('Peak_freq%02d', k);
end

% Pré-alocar matriz de features
X_test = zeros(numFiles, numel(name_features));
y_test = strings(numFiles, 1);
tempo_total=0;
tempo_max=-1;

for i = 1:numFiles
    filename = fullfile(audioFolder, files(i).name);

    [audio, Fs] = audioread(filename);
    audio= audio';

    tic;
    features = extract_features_audio_v3(audio, Fs);
    tempo_inst = toc;
    tempo_total = tempo_total + tempo_inst;
    if tempo_inst > tempo_max
        tempo_max= tempo_inst;
    end

    X_test(i,:) = features;

    if contains(lower(files(i).name), 'ball')
        y_test(i) = "bola_mesa";
    else
        y_test(i) = "nao_bola";
    end
end
tempo_medio = tempo_total / numFiles;
fprintf('Tempo médio extração features: %.6f s\n', tempo_medio);
fprintf('Tempo maximo extração features: %.6f s\n', tempo_max);

y_test = categorical(y_test);

%% 2. Carregar modelos

load('modelo_Boosted_Trees.mat','trainedModel');

modelos = {
    trainedModel 'Boosted Trees'
};

resultados = [];


%% 3. Avaliar cada modelo
for i = 1:size(modelos,1)
    modelo = modelos{i,1};
    nome   = modelos{i,2};

    X_test_table = array2table(X_test, 'VariableNames', name_features);

    tic;
    y_pred = modelo.predictFcn(X_test_table);
    tempo_total = toc;
    tempo_medio_pred = tempo_total / size(X_test,1);

    y_pred = categorical(y_pred);

    % Matriz de confusão
    C = confusionmat(y_test, y_pred);

    % Accuracy global
    acc = sum(diag(C)) / sum(C(:));

    % Métricas por classe
    recall = diag(C) ./ sum(C,2);   % sensibilidade por classe
    precision = diag(C) ./ sum(C,1)'; 
    f1 = 2*(precision.*recall) ./ (precision+recall);

    % Média macro
    recall_macro = mean(recall);
    precision_macro = mean(precision);
    f1_macro = mean(f1);

    % Matthews Correlation Coefficient (multi-class generalizado)
    n = sum(C(:));
    C_sum_rows = sum(C,2);
    C_sum_cols = sum(C,1);
    numerator = n*sum(diag(C)) - sum(C_sum_rows .* C_sum_cols');
    denominator = sqrt( (n^2 - sum(C_sum_cols.^2)) * (n^2 - sum(C_sum_rows.^2)) );
    if denominator == 0
        MCC = NaN;
    else
        MCC = numerator / denominator;
    end

    resultados = [resultados; {nome, acc, recall_macro, precision_macro, ...
                               f1_macro, MCC, tempo_medio_pred}];

    % --- Confusion chart ---
    figure('Name',['Confusion Matrix - ' nome]);
    cm = confusionchart(y_test, y_pred, ...
        'Normalization','row-normalized', ... % mostra percentagens por linha
        'RowSummary','row-normalized', ...
        'ColumnSummary','column-normalized');
    title(['Confusion Matrix - ' nome]);
end

%% 4. Resultados
T = cell2table(resultados, ...
    'VariableNames', {'Modelo','Accuracy','Recall','Precision','F1', ...
                      'MCC','TempoMedio_s'});

disp(T);
%%
% Criação da tabela

X_test_table.Label = categorical(y_test);












