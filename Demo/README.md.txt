Demo – Sistema de Deteção e Localização de Impactos de Bola

Esta pasta contém uma demonstração funcional do sistema de deteção e localização acústica de impactos de bola de ténis de mesa desenvolvido em MATLAB. Inclui todos os ficheiros necessários para executar o exemplo completo: deteção, extração de features, classificação, estimação de TDOA e localização 2D.

Conteúdo da pasta:
		
ball_0001.wav -	Gravação de exemplo. Utilizada como Sinal de Referencia para identificar o Sinal de uma bola dentro do Buffer Circular.

CircularBuffer_v2.m -	Implementação de um buffer circular para armazenamento e processamento contínuo do áudio.

EnergyTracker.m -	Classe utilizada para calcular energia sobe a forma de uma Soma Aculmulada.

extract_features_audio_v3.m -	Função de extração de features.

ImpactPlot2D.m -	Função de visualização que representa graficamente a posição estimada do impacto em 2D.

modelo_Boosted_Trees.mat -	Modelo de classificação AdaBoost treinado para distinguir impactos de bola de outros sons.

RT_lin_v3.m -	Script principal da demonstração. Executa todo o pipeline de deteção → TDOA → localização 2D → features → classificação → visualização.

Como correr a demonstração:

Abrir MATLAB.

Definir esta pasta Demo como pasta atual.

Executar o script principal:
RT_lin_v3


Requisitos:

MATLAB R2024a ou superior

Signal Processing Toolbox

Statistics and Machine Learning Toolbox

ASIO4ALL (para suporte a drivers de áudio de baixa latência)

Ficheiros incluídos nesta pasta
