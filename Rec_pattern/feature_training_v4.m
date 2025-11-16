%treino de classificador com 2 classes
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
        features = extarct_features_audio_v2(audio, Fs);

        % acumular
        X = [X; features];
        Y = [Y; labels{c}];
    end
end

% Nomes das features
name_features = {'ZCR','RMS','Clearence Factor','Crest Factor', ...
    'Impulse Factor','Waveform Length','Peak Ratio','Kurtosis','Skewness', ...
    'Shape Factor','Spectral Entropy','Spectral Rolloff Frequency', ...
    'Spectral Flatness','Spectral Centroid','Spectral Skewness', ...
    'Spectral Kurtosis','Spectral Variance','Spectral Bandwidth', ...
    'Rise Time','Fall Time','Energy Entropy'};
for k = 1:10
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

X_test_table = array2table(X_test, 'VariableNames', name_features);
X_test_table.Label = categorical(y_test);