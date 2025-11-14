%funcao de extracao de features para as 15 melhores no ranking de MRMR
%


function features = extarct_features_audio_v3(audio, Fs)

    
    %Feature 2: Root Mean Square
    rms_val = sqrt(mean(audio.^2));
    
    
    %Feature 6: Waveform Length
    waveform_length = sum(abs(diff(audio)));
    
   
    %Feature 7: razao pico max / pico sec    
       
        % Ordena os valores em ordem decrescente
        sorted_peaks = sort(abs(audio), 'descend');
        
        % Garante que existam pelo menos dois valores distintos
        if length(sorted_peaks) >= 2 && sorted_peaks(2) > 0
            ratio_peaks = sorted_peaks(1) / sorted_peaks(2);
        else
            ratio_peaks = NaN;  % ou 1
        end
    
    
     %Feature 9: Skewness
    mu = mean(audio);
    m2 = mean((audio - mu).^2);
    m3 = mean((audio - mu).^3);
    skewness = m3 / (m2^(3/2));
    
    
    
    %---------------------spectral extraction ---------------------------------
    
    %FFT
    Y = fft(audio);
    N = length(Y);
    f = (0:N-1)*(Fs/N);           % eixo de frequências
    halfRange = 1:floor(N/2);   %frequencias ate Nyquist
    f_half = f(halfRange);
    
    Y_half = Y(halfRange);
    magnitude = abs(Y_half);
    magnitude_norm = magnitude /  max(magnitude);   %linear normalizado
    
    
    %Feature 11: frequencias dominates
    num_peaks = 10;
    min_distance_hz=400;
    
    % Encontra picos da FFT
    min_peak_distance_bins = round(min_distance_hz / (Fs/N));
    [peaks, locs] = findpeaks(magnitude_norm, 'MinPeakDistance', min_peak_distance_bins);
    
    % Ordena os picos por magnitude decrescente
    [~, idx_sorted] = sort(peaks, 'descend');
    locs_top = locs(idx_sorted(1:min(num_peaks, length(locs))));
    freqs_top = f_half(locs_top);
    
    % Ordena por frequência crescente 
    freqs_top_sorted = sort(freqs_top);
    idx_escolhidos = [6 7 8 9 10]; % qualquer subset
    freqs_selected = freqs_top_sorted(idx_escolhidos);

    
    
    
    %power spectral density      
    ps = magnitude.^2;   % 1/N .* 
    ps_sum = sum(ps);

    %Feature 13: Spectral rolloff
    rolloff = 0.90; %valores tipicos: 0.95, 0.90, 0.75, 0.50
    ps_sum_rolloff = ps_sum * rolloff;
    ps_sum_aux = 0;
    rolloff_freq = 0.5 * Fs;  %valor padrao caso nao atinja(frequencia de Nyquist)
    for i=1:length(ps)
        ps_sum_aux = ps_sum_aux + ps(i);
        if(ps_sum_aux >= ps_sum_rolloff)
            rolloff_freq = 0.5 * Fs / (length(ps) - 1) * (i - 1);
            break;
        end
    end
    
    
    
    %Feature 14: spectral flatness 
    geometric_mean = exp(mean(log(ps + eps)));
    arithmetic_mean = mean(ps);
    spec_flatness = geometric_mean / arithmetic_mean;
    
    
    
    %Spectral Centroid
    indices = 0:length(ps)-1;
    ps_sum_weighted = sum(ps .* indices);
    
    spec_centroid = 0.5 * Fs / (length(ps) - 1) * (ps_sum_weighted / ps_sum);    %freq da centroide
     
    %Feature 17: Spectral kurtosis
    f_diff= f_half - spec_centroid;
    ps_sum_weighted2 = sum(ps .* f_diff.^2);
    ps_sum_weighted4 = sum(ps .* f_diff.^4);
    spec_kurtosis = (ps_sum_weighted4 / ps_sum) / (sqrt(ps_sum_weighted2 / ps_sum))^4;
    
    
    %Feature 19: Spectral Bandwith
    spec_bandwidth = sqrt(sum(((f_half - spec_centroid).^2) .* ps) / ps_sum);
    
    
    
    %------------------------------ Energy ------------------------------------
    
    
    %tentar apoveitar e retirar medidas apartir da energia!!!
    
    vrf_tm = 1;  % em milissegundos
    vrf_tm = vrf_tm * 1e-3;
    
    
    energy = audio.^2;
    smooth_energy = movmean(energy, round(vrf_tm*Fs)); % janela de 1 ms
    energy_norm = smooth_energy / max(smooth_energy);
    
    %Feature 20: Time rise
    
    idx_10 = find(energy_norm >= 0.1, 1, 'first');
    idx_90 = find(energy_norm >= 0.9, 1, 'first');
    if ~isempty(idx_10) && ~isempty(idx_90)
        tempo_ataque_ms = (idx_90 - idx_10) / Fs * 1000;
    end
    
    
    
    %Feature 21: Time Fall
    
    [~, idx_peak] = max(energy_norm); %localizar pico de energia
    
    idx_90d = find(energy_norm(idx_peak:end) <= 0.9, 1, 'first');
    idx_10d = find(energy_norm(idx_peak + idx_90d - 1:end) <= 0.1, 1, 'first');
    
    if ~isempty(idx_90d) && ~isempty(idx_10d)
        idx_90d = idx_peak + idx_90d - 1;
        idx_10d = idx_90d + idx_10d - 1;
    
        tempo_decay_ms = (idx_10d - idx_90d) / Fs * 1000;
        
    else
        tempo_decay_ms = NaN;
    end
    
 
    
    features = [rms_val, waveform_length, ratio_peaks, ...
         skewness, rolloff_freq, spec_flatness, ...
         spec_kurtosis, spec_bandwidth, tempo_ataque_ms, tempo_decay_ms, ...
        freqs_selected];

end