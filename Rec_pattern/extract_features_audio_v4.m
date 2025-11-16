function features = extract_features_audio_v4(audio, Fs)

    % ------------------- Time-domain features -------------------
    
    % RMS
    rms_val = sqrt(mean(audio.^2));

    % Waveform Length
    waveform_length = sum(abs(diff(audio)));

    % Peak ratio (máximo / segundo máximo)
    sorted_peaks = sort(abs(audio), 'descend');
    if numel(sorted_peaks) >= 2 && sorted_peaks(2) > 0
        ratio_peaks = sorted_peaks(1) / sorted_peaks(2);
    else
        ratio_peaks = NaN;
    end

    % Skewness
    mu = mean(audio);
    centered = audio - mu;
    m2 = mean(centered.^2);
    m3 = mean(centered.^3);
    skewness_val = m3 / (m2^(3/2) + eps);

    % ------------------- Frequency-domain features -------------------

    % FFT
    N = length(audio);
    Y = fft(audio);
    mag = abs(Y(1:floor(N/2)));
    f = (0:floor(N/2)-1) * (Fs/N);

    ps = mag.^2;
    ps_sum = sum(ps) + eps;

    % Frequências dominantes (top 10 picos, espaçados em 400 Hz)
    [pks, locs] = findpeaks(mag, 'MinPeakDistance', round(400 / (Fs/N)));
    [~, idx] = maxk(pks, 10);
    freqs_top = sort(f(locs(idx)));
    freqs_selected = nan(1,5);
    if numel(freqs_top) >= 10
        freqs_selected = freqs_top(6:10); % pega as últimas 5
    elseif numel(freqs_top) >= 5
        freqs_selected(1:numel(freqs_top)) = freqs_top;
    end

    % Spectral rolloff (90%)
    cum_energy = cumsum(ps);
    rolloff_thresh = 0.9 * ps_sum;
    idx_roll = find(cum_energy >= rolloff_thresh, 1);
    if ~isempty(idx_roll)
        rolloff_freq = f(idx_roll);
    else
        rolloff_freq = Fs/2;
    end

    % Spectral flatness
    spec_flatness = exp(mean(log(ps+eps))) / mean(ps);

    % Spectral centroid
    spec_centroid = sum(f .* ps) / ps_sum;

    % Spectral kurtosis
    f_diff = f - spec_centroid;
    spec_kurtosis = (sum(ps .* f_diff.^4) / ps_sum) / ( (sum(ps .* f_diff.^2) / ps_sum)^2 + eps );

    % Spectral bandwidth
    spec_bandwidth = sqrt(sum(((f - spec_centroid).^2) .* ps) / ps_sum);

    % ------------------- Energy-based features -------------------

    win = round(0.001 * Fs); % janela 1 ms
    smooth_energy = movmean(audio.^2, win);
    energy_norm = smooth_energy / max(smooth_energy + eps);

    % Rise time (10% -> 90%)
    idx_10 = find(energy_norm >= 0.1, 1);
    idx_90 = find(energy_norm >= 0.9, 1);
    if ~isempty(idx_10) && ~isempty(idx_90) && idx_90 > idx_10
        tempo_ataque_ms = (idx_90 - idx_10) / Fs * 1000;
    else
        tempo_ataque_ms = NaN;
    end

    % Decay time (90% -> 10% depois do pico)
    [~, idx_peak] = max(energy_norm);
    idx_90d = find(energy_norm(idx_peak:end) <= 0.9, 1);
    idx_10d = find(energy_norm(idx_peak:end) <= 0.1, 1);
    if ~isempty(idx_90d) && ~isempty(idx_10d) && idx_10d > idx_90d
        tempo_decay_ms = (idx_10d - idx_90d) / Fs * 1000;
    else
        tempo_decay_ms = NaN;
    end

    % ------------------- Output vector -------------------
    features = [rms_val, waveform_length, ratio_peaks, ...
                skewness_val, rolloff_freq, spec_flatness, ...
                spec_kurtosis, spec_bandwidth, ...
                tempo_ataque_ms, tempo_decay_ms, ...
                freqs_selected];

end
