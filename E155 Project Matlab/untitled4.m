clear; clc; close all;

%% Signal
fs = 48e3;
f0 = 1.2e3;
dur = 5e-3;               % 5 ms window
t  = 0:1/fs:dur;
x  = square(2*pi*f0*t);   % input square wave

%% FIR (8-tap LPF)
best_bq = [10 33 85 127 127 85 33 10];
best_bq = best_bq / sum(best_bq);   % normalize so gain ~ 1
best_fc = 2e3;                      % just for title, pick whatever

y_fir = filter(best_bq, 1, x);      % full-rate FIR output

%% 4× decimation
M     = 4;
fs_ds = fs / M;
t_ds  = t(1:M:end);
y_ds  = y_fir(1:M:end);

%% Plots
figure;

% 1) Input
subplot(3,1,1);
plot(t*1e3, x, 'LineWidth', 1.3); grid on;
title('Input: 1.2 kHz Square Wave @ 48 kHz');
xlabel('Time (ms)');
ylabel('Amplitude (V)');
xlim([0 dur*1e3]);

% 2) FIR output (smooth line)
subplot(3,1,2);
plot(t*1e3, y_fir, 'LineWidth', 1.3); grid on;
title(sprintf('FIR Output Only (8-tap LPF, fc \\approx %.1f Hz)', best_fc));
xlabel('Time (ms)');
ylabel('Amplitude');
xlim([0 dur*1e3]);

% 3) 4× decimated output (lollipop style, but sparse)
subplot(3,1,3);
stem(t_ds*1e3, y_ds, 'filled'); grid on;
title('FIR Output After 4× Decimation (12 kHz)');
xlabel('Time (ms)');
ylabel('Amplitude');
xlim([0 dur*1e3]);
