%% ============================================================
%  Leilani Elkaslasy and Thomas Lilygren 
%  E-155 Final Project: Barcode Beats 
%  This Matlab Script was used to find our coefficients for our 8 TAP FIR
%  filter for the FPGA signal processing of the barcode square wave input
%  This script finds the "roundest" signal this 8-tap LPF can make
%  12/5/2025

%  - Sweep fc
%  - Measure THD on 1.2 kHz square
%  - Pick fc that minimizes THD
%% ============================================================

clear; clc; close all;

%% --------------------------
%  FIR / system parameters
%% --------------------------
NUM_TAPS    = 8;        % must match NUM_TAPS in SV
COEFF_WIDTH = 8;        % signed 8-bit coeffs in HW
fs          = 48e3;     % sample rate (Hz)
f0          = 1.2e3;    % input square wave frequency (Hz)

%% --------------------------
%  Input: 1.2 kHz square wave, 1 Vpp centered
%% --------------------------
A    = 0.5;             % amplitude, gives 0..1 in your current code
Tsim = 5e-3;            % simulate 5 ms

t = 0:1/fs:Tsim;
x = A * square(2*pi*f0*t) + 0.5;   % matches your code

%% --------------------------
%  Sweep fc to find "roundest" filter
%% --------------------------
fc_list = linspace(1.3e3, 3e3, 40);    % candidate cutoffs
best_thd = inf;
best_fc  = NaN;
best_bq  = [];
best_y   = [];

for fc = fc_list

    % --- Design 8-tap LPF with this fc ---
    Wn = fc / (fs/2);
    b  = fir1(NUM_TAPS-1, Wn, 'low');   % floating-point prototype

    % --- Quantize to signed 8-bit (like your HW) ---
    max_int   = 2^(COEFF_WIDTH-1) - 1;  % 127
    scale_fac = max_int / max(abs(b));
    coeffs_int = round(b * scale_fac);
    coeffs_int = max(min(coeffs_int, max_int), -max_int);
    b_q = double(coeffs_int) / scale_fac;

    % --- Filter the signal ---
    y = filter(b_q, 1, x);

    % --- Compute THD (how non-sine it is) ---
    Nfft = 8192;
    Y    = fft(y, Nfft);
    fvec = (0:Nfft-1) * fs / Nfft;

    % Find fundamental and a few harmonics
    [~, k1] = min(abs(fvec - f0));        % fundamental
    [~, k3] = min(abs(fvec - 3*f0));      % 3rd
    [~, k5] = min(abs(fvec - 5*f0));      % 5th
    [~, k7] = min(abs(fvec - 7*f0));      % 7th

    A1 = abs(Y(k1));
    A3 = abs(Y(k3));
    A5 = abs(Y(k5));
    A7 = abs(Y(k7));

    thd = sqrt(A3^2 + A5^2 + A7^2) / A1;

    if thd < best_thd
        best_thd = thd;
        best_fc  = fc;
        best_bq  = b_q;
        best_y   = y;
        best_coeffs_int = coeffs_int;
        best_scale_fac  = scale_fac;
    end
end

fprintf('Best fc ≈ %.1f Hz\n', best_fc);
fprintf('Minimum THD ≈ %.4f\n\n', best_thd);

disp('Best quantized FIR coeffs (signed 8-bit):');
disp(best_coeffs_int.');

fprintf('\nSystemVerilog coefficient assigns:\n');
for k = 1:NUM_TAPS
    fprintf('assign coeffs[%0d] = 8''sd%d;\n', k-1, best_coeffs_int(k));
end
fprintf('\n%% Implicit scaling factor in hardware ≈ 1/%g\n', best_scale_fac);

%% --------------------------
%  Plot input and "roundest" output
%% --------------------------
y = best_y;   % use best signal

figure;

% Input
subplot(3,1,1);
plot(t*1e3, x, 'LineWidth', 1.3); grid on;
title('Input: 1.2 kHz Square Wave (0..1 V)');
xlabel('Time (ms)');
ylabel('Amplitude (V)');

% Output
subplot(3,1,2);
plot(t*1e3, y, 'LineWidth', 1.3); grid on;
title(sprintf('Roundest Output (8-tap LPF, fc ≈ %.1f Hz)', best_fc));
xlabel('Time (ms)');
ylabel('Amplitude');

% Spectrum
Nfft = 4096;
Y    = abs(fft(y, Nfft));
fvec = linspace(0, fs/2, Nfft/2);

subplot(3,1,3);
plot(fvec/1e3, Y(1:Nfft/2), 'LineWidth', 1.3); grid on;
title('Output Spectrum of Roundest Signal');
xlabel('Frequency (kHz)');
ylabel('|Y(f)|');
