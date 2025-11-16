clearvars; 
clc;
close all;

load("debub_vars1");

c=343;
Fs = 48000;
max_t = length(data4_norm)/Fs;

t=linspace(0,max_t,length(data4_norm)) * 1e3;

d12=t12*c;
d13=t13*c;
d14=t14*c;

fprintf("d12 = %.2f m | d13 = %.2f m | d14 = %.2f m\n", t12*c, t13*c, t14*c);
fprintf("t12 = %.2f ms | t13 = %.2f ms | t14 = %.2f ms\n", t12*1e3, t13*1e3, t14*1e3);
fprintf('-> Posição estimada: (x = %.2f m, y = %.2f m)\n', pos_est(1), pos_est(2));

[t12_new, cc12_new, lags12_new]= gcc_phat(data1_norm,data2_norm,Fs);
[t13_new, cc13_new, lags13_new]= gcc_phat(data1_norm,data3_norm,Fs);
[t14_new, cc14_new, lags14_new]= gcc_phat(data1_norm,data4_norm,Fs);

fprintf("t12 = %.2f ms | t13 = %.2f ms | t14 = %.2f ms\n", t12_new*1e3, t13_new*1e3, t14_new*1e3);

figure;
plot(t, data1_norm);
hold on 
plot(t, data2_norm);
hold off;
title("Par 12");
grid minor;
legend("mic1", "mic2");
xlabel("tempo (ms)");


figure;
plot(lags12, abs(cc12));
title("cc12");
grid minor;

figure;
plot(lags12_new, abs(cc12_new));
title("cc12 gcc phat");
grid minor;

figure;
plot(t, data1_norm);
hold on 
plot(t, data3_norm);
hold off;
title("Par 13");
grid minor;
legend("mic1", "mic3");
xlabel("tempo (ms)");

figure;
plot(lags13, abs(cc13));
title("cc13");
grid minor;

figure;
plot(lags13_new, abs(cc13_new));
title("cc13 gcc phat");
grid minor;

figure;
plot(t, data1_norm);
hold on 
plot(t, data4_norm);
hold off;
title("Par 14");
grid minor;
legend("mic1", "mic4");
xlabel("tempo (ms)");

figure;
plot(lags14, abs(cc14));
title("cc14");
grid minor;

figure;
plot(lags14_new, abs(cc14_new));
title("cc14 gcc phat");
grid minor;
%%

function [tdoa, cc ,lags] = gcc_phat(x1, x2, fs)
    
    N = length(x1) + length(x2);
    X1 = fft(x1, N);
    X2 = fft(x2, N);

    R = X1 .* conj(X2);
    R = R ./ abs(R + eps);  % PHAT: só mantém a fase
    
    cc = real(ifft(R));
    [~, max_idx] = max(cc);
    lag_samples = max_idx - 1;
    if lag_samples > N/2
        lag_samples = lag_samples - N;
    end
    tdoa = lag_samples / fs;

    cc = fftshift(cc);  % centraliza o zero
    lags = (-floor(N/2):ceil(N/2)-1) / fs;

end

















