% Set up audio device reader object
Fs = 44100;              % Sampling frequency
frameLength = 1024;      % Frame length for real-time processing
deviceReader = audioDeviceReader('SampleRate', Fs, 'SamplesPerFrame', frameLength);

% Create a scope for real-time plotting
scope = dsp.TimeScope('SampleRate', Fs, 'TimeSpan', 0.1, 'BufferLength', 2*Fs, ...
                      'YLimits', [-1, 1], 'Title', 'Real-Time Microphone Input');

% Real-time audio processing loop
disp('Recording in real-time...');
while true
    audioFrame = deviceReader();  % Capture audio frame
    scope(audioFrame);            % Plot the frame
end