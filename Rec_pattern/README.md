Reconhecimento de Padrões – Extração de Features e Classificação

Esta pasta contém os ficheiros e scripts utilizados para o reconhecimento de padrões de impactos de bola de ténis de mesa, incluindo:

dados de treino e validação,

funções de extração de features acústicas,

scripts para seleção e comparação de classificadores,

sessões do Classification Learner utilizadas no MATLAB,

o modelo final utilizado no trabalho,

e tabelas de resultados de vários classificadores.

Conteúdo da pasta:

Bola/ -	Pasta com gravações de impactos de bola utilizadas no treino.

Nao_Bola/ -	Pasta com gravações de sons de fundo / não bola para treino.

data_validation/ -	Pasta com dados de validação para testar os modelos.

extract_features_audio_v2.m / v3 / v4.m -	Funções para extrair features acústicas de gravações.

feature_training_v4.m / v5.m -	Scripts para processar dados de treino e preparar matrizes de features 
para classificação.

classif_choice.m / classif_choice2.m -	Scripts para comparar diferentes classificadores e escolher os melhores com base nos dados de treino.

ClassificationLearnerSession.mat -	Sessão do MATLAB Classification Learner contendo a análise dos classificadores testados.

CLSession_15features.mat -	Sessão com 15 features utilizadas para treino e comparação de modelos.

modelo_Boosted_Trees.mat -	Modelo final AdaBoost treinado para classificação bola vs. não bola.

resultsTable.csv -	Tabela de resultados comparando desempenho de vários classificadores durante o treino.

