clc;clear all;

Fs = 44100;                
nBits = 16;               
nChannels = 1;             
time = 5;             

recObj = audiorecorder(Fs, nBits, nChannels);
disp('Recording audio...');
recordblocking(recObj, time);
disp('Recording complete.');

audioData = getaudiodata(recObj);

t = linspace(0, time, length(audioData));
figure;
plot(t, audioData);
xlabel('Time [s]');
ylabel('Amplitude');
title('Microphone Input Signal');
grid on;
