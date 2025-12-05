%% ============================================================
%  Leilani Elkaslasy and Thomas Lilygren 
%  E-155 Final Project: Barcode Beats 
%  This Matlab Script was used to find our coefficients for our 8 TAP FIR
%  Visualize the sampled version of the FIR filtered signal and how it will
%  look after applied 4x decimation
%  12/5/25 
%% --------------------------
%  Plot: FIR-only output (48 kHz) with lollipop markers
%% --------------------------

%% --------------------------
%  Plot: FIR-only output (48 kHz) with lollipop markers
%% --------------------------

y_fir = filter(best_bq, 1, x);    % full-rate FIR output
fs_ds = fs/4;                     % decimated sample rate
y_ds  = y_fir(1:4:end);           % 4× decimated FIR signal
t_ds  = (0:length(y_ds)-1)/fs_ds; % decimated timebase

figure;

% Input (full-rate)
subplot(4,1,1);
plot(t*1e3, x, 'LineWidth', 1.3); grid on;
title('Input: 1.2 kHz Square Wave @ 48 kHz');
xlabel('Time (ms)');
ylabel('Amplitude (V)');

% FIR output (full-rate) — lollipop / stem style
subplot(4,1,2);
stem(t*1e3, y_fir, 'filled'); grid on;
title(sprintf('FIR Output Only (8-tap LPF, fc ≈ %.1f Hz)', best_fc));
xlabel('Time (ms)');
ylabel('Amplitude');

% *** NEW PLOT INSERTED HERE ***
% FIR output after 4× decimation (12 kHz)
subplot(4,1,3);
stem(t_ds*1e3, y_ds, 'filled'); grid on;
title('FIR Output After 4× Decimation (12 kHz)');
xlabel('Time (ms)');
ylabel('Amplitude');

% Spectrum (full-rate)
Nfft = 4096;
Yfir  = abs(fft(y_fir, Nfft));
fvec  = linspace(0, fs/2, Nfft/2);

subplot(4,1,4);
plot(fvec/1e3, Yfir(1:Nfft/2), 'LineWidth', 1.3); grid on;
title('FIR Output Spectrum (48 kHz)');
xlabel('Frequency (kHz)');
ylabel('|Y(f)|');
