
% save('modelo_Ensemble_2_22.mat','trainedModel_Ensemble_2_22');
% save('modelo_Ensemble_2_23.mat','trainedModel_Ensemble_2_23');
% save('modelo_SVM_2_12.mat','trainedModel_SVM_2_12');
% save('modelo_NN_2_28.mat','trainedModel_NN_2_28');
% save('modelo_SVM_2_11.mat','trainedModel_SVM_2_11');
% save('modelo_En_20.mat','trainedModel_En_20');    %mesmo do 2.23
% save('modelo_En_15.mat','trainedModel_En_15');
%save('modelo_En_10.mat','trainedModel_En_10');
% save('modelo_Tree_2_1.mat','trainedModel_Tree_2_1');
% save('modelo_Tree_2_2.mat','trainedModel_Tree_2_2');
% save('modelo_SVM_2_14.mat','trainedModel_SVM_2_14');
% save('modelo_KNN_2_16.mat','trainedModel_KNN_2_16');
% save('modelo_KNN_2_19.mat','trainedModel_KNN_2_19');
% save('modelo_NN_2_27.mat','trainedModel_NN_2_27');
% save('modelo_NN_2_29.mat','trainedModel_NN_2_29');
% save('modelo_NN_2_27.mat','trainedModel_NN_2_27');
% save('modelo_NN_2_29.mat','trainedModel_NN_2_29');
% save('modelo_NN_2_30.mat','trainedModel_NN_2_30');
% save('modelo_NN_2_31.mat','trainedModel_NN_2_31');
% save('modelo_Kernel_2_32.mat','trainedModel_Kernel_2_32');

%% Avaliação de modelos exportados do Classification Learner
clear; clc;

audioFolder = 'data_validation/';
files = dir(fullfile(audioFolder, '*.wav'));
numFiles= length(files);

% Features usadas no treino
name_features = {'ZCR','RMS','Clearence Factor','Crest Factor', ...
    'Impulse Factor','Waveform Length','Peak Ratio','Kurtosis','Skewness', ...
    'Shape Factor','Spectral Entropy','Spectral Rolloff Frequency', ...
    'Spectral Flatness','Spectral Centroid','Spectral Skewness', ...
    'Spectral Kurtosis','Spectral Variance','Spectral Bandwidth', ...
    'Rise Time','Fall Time','Energy Entropy'};
for k=1:10
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
    features = extarct_features_audio_v2(audio, Fs);
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
load('modelo_Ensemble_2_22.mat','trainedModel_Ensemble_2_22');
load('modelo_Ensemble_2_23.mat','trainedModel_Ensemble_2_23');
load('modelo_SVM_2_12.mat','trainedModel_SVM_2_12');
load('modelo_NN_2_28.mat','trainedModel_NN_2_28');
load('modelo_SVM_2_11.mat','trainedModel_SVM_2_11');
load('modelo_Tree_2_1.mat','trainedModel_Tree_2_1');
load('modelo_Tree_2_2.mat','trainedModel_Tree_2_2');
load('modelo_SVM_2_14.mat','trainedModel_SVM_2_14');
load('modelo_KNN_2_16.mat','trainedModel_KNN_2_16');
load('modelo_KNN_2_19.mat','trainedModel_KNN_2_19');
load('modelo_NN_2_27.mat','trainedModel_NN_2_27');
load('modelo_NN_2_29.mat','trainedModel_NN_2_29');
load('modelo_NN_2_30.mat','trainedModel_NN_2_30');
load('modelo_NN_2_31.mat','trainedModel_NN_2_31');
load('modelo_Kernel_2_32.mat','trainedModel_Kernel_2_32');

modelos = {
    trainedModel_Tree_2_1 'Tree 2.1';
    trainedModel_Tree_2_2 'Tree 2.2';
    trainedModel_SVM_2_11, 'SVM 2.11';
    trainedModel_SVM_2_12, 'SVM 2.12';
    trainedModel_SVM_2_14 'SVM 2.14';
    trainedModel_KNN_2_16 'KNN 2.16';
    trainedModel_KNN_2_19 'KNN 2.19';
    trainedModel_KNN_2_16 'KNN 2.16';
    trainedModel_Ensemble_2_22, 'Ensemble 2.22';
    trainedModel_Ensemble_2_23, 'Ensemble 2.23';
    trainedModel_NN_2_27, 'Neural Net 2.27';
    trainedModel_NN_2_28, 'Neural Net 2.28';
    trainedModel_NN_2_29, 'Neural Net 2.29';
    trainedModel_NN_2_30, 'Neural Net 2.30';
    trainedModel_NN_2_31, 'Neural Net 2.31';
    trainedModel_Kernel_2_32, 'Kernel 2.32'
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












