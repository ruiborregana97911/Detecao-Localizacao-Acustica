% --- Carregar arquivo WAV multicanal ---
[signal, fs] = audioread('gravacao_aris_hall_3.wav'); % 4 canais
num_channels = size(signal,2);
signal = signal(fs*48.84:fs*48.9,:);

limiar_energia = 6.486e-5; 

% --- Parâmetros ---
window_ms = 1;                        % janela de 1 ms
window_samples = round(fs * window_ms/1000);

% --- Inicializar armazenamento de energia ---
energy = zeros(floor(length(signal)/window_samples), num_channels);
time_vec = (0:size(energy,1)-1) * window_ms / 1000; % tempo em segundos

% --- Calcular energia média por janela ---
for ch = 1:num_channels
    idx = 1;
    for n = 1:window_samples:length(signal)-window_samples
        frame = signal(n:n+window_samples-1, ch);
        energy(idx,ch) = sum(frame.^2)/window_samples;
        idx = idx + 1;
    end
end


% --- Plotar energia e picos em 4 subplots ---
figure;
colors = lines(num_channels);
for ch = 1:num_channels
    subplot(num_channels,1,ch);
    plot(time_vec*1000, energy(:,ch), 'Color', colors(ch,:), 'DisplayName', ['Canal ' num2str(ch)]);
    hold on;
    yline(limiar_energia, 'k--', 'LineWidth', 1); % limiar
    ylabel('Energia');
    
        xlabel('Tempo [ms]');
   
    legend(['Canal ' num2str(ch)], 'Limiar');
    grid minor;
end


