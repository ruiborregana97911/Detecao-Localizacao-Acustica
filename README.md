# Detecao-Localizacao-Acustica
Implementação completa em MATLAB para deteção, classificação e localização acústica 2D de impactos de bola de ténis de mesa.  
Inclui deteção baseada em energia, estimação de TDOA com GCC-PHAT, extração de *features* e classificação com AdaBoost.  

Este repositório reúne todo o código, dados e ferramentas desenvolvidas no âmbito da minha dissertação de mestrado.

A organização do repositório está dividida em módulos temáticos, conforme descrito abaixo.

---

## Estrutura do Repositório

### **1. Demo/**
Contém uma demonstração completa e funcional do sistema final, incluindo:
- Script principal capaz de correr o sistema de deteção + localização.
- Funções auxiliares (correlação, energia, buffer, análise 2D).
- Modelo final de classificação (`modelo_Boosted_Trees.mat`).


Esta pasta permite executar o sistema com o mínimo de dependências.

---

### **2. Experiments/**
Inclui dados e materiais utilizados nas sessões experimentais:
- Gravações áudio das experiências (sem os vídeos, que foram movidos para armazenamento externo).
- Medições, anotações e resultados intermédios obtidos durante a recolha de dados.
- Ficheiros relacionados com experiências no Aristides Hall e outros locais.

---

### **3. Imag_codes/**
Código utilizado para gerar imagens, gráficos e figuras incluídas na dissertação:
- Scripts MATLAB para processamento gráfico.
- Rotinas para gerar heatmaps, diagramas, representações 2D, etc.
- Ficheiros auxiliares que suportam a criação de figuras de resultados.

---

### **4. Old_codes/**
Versões antigas e código descontinuado:
- Implementações preliminares.
- Protótipos de deteção e localização.
- Funções substituídas por versões mais otimizadas.
  
Esta pasta é mantida para referência histórica e rastreamento da evolução do projeto.

---

### **5. Rec_pattern/**
Módulo de reconhecimento de padrões (classificação):
- Conjuntos de treino: `Bola/`, `Nao_Bola/` e `data_validation/`
- Funções de extração de *features* (v2, v3, v4).
- Sessões do Classification Learner (`*.mat`).
- Código para seleção de classificadores (`classif_choice*.m`).
- Modelo final de Boosted Trees.
- Tabela de resultados comparativos (`resultsTable.csv`).

Todo o processo de classificação e análise de performance está documentado nesta pasta.

---

## Requisitos

- **MATLAB R2024a** ou superior
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Audio Toolbox
- ASIO4ALL (para captura de áudio com baixa latência)

---

## Nota sobre vídeos das experiências
Devido às limitações do GitHub (tamanho máximo de ficheiro), os vídeos das experiências foram movidos para armazenamento externo. O link será disponibilizado no documento da dissertação.

---

## Autor
Rui Borregana  
Universidade de Aveiro · 2025

