clearvars; 
clc;


cb = CircularBuffer(2,1024);

cb.write(randn(2, 512));

disp(cb.getAvailableSamples());

dados = cb.read(256);



