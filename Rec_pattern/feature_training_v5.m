%treino de classificador com 2 classes para 15 features
%

clc, clearvars;
close all;

% Pastas para cada classe
folders = { ...
    'Bola/', ...
    'Nao_Bola/'};

labels = {'bola_mesa','nao_bola'};

X = [];   % matriz de features
Y = {};   % labels

for c = 1:numel(folders)
    audioFolder = folders{c};
    files = dir(fullfile(audioFolder, '*.wav'));
    
    for i = 1:length(files)
        filePath = fullfile(audioFolder, files(i).name);

        [audio, Fs] = audioread(filePath);
        audio = audio';   % garante formato

        % extrair features
        features = extarct_features_audio_v3(audio, Fs);

        % acumular
        X = [X; features];
        Y = [Y; labels{c}];
    end
end

% Features usadas no treino
name_features = {'RMS','Waveform Length','Peak Ratio','Skewness', ...
    'Spectral Rolloff Frequency','Spectral Flatness', ...
    'Spectral Kurtosis','Spectral Bandwidth', ...
    'Rise Time','Fall Time'};
for k=6:10
    name_features{end+1} = sprintf('Peak_freq%02d', k);
end

% Criação da tabela
T = array2table(X, 'VariableNames', name_features);
T.Label = categorical(Y);

% Mostra resumo
disp(tabulate(T.Label));

%% test data
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
    features = extarct_features_audio_v3(audio, Fs);
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

X_test_table = array2table(X_test, 'VariableNames', name_features);
X_test_table.Label = categorical(y_test);