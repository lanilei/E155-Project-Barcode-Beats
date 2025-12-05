%% ============================================================
%  Leilani Elkaslasy and Thomas Lilygren 
%  E-155 Final Project: Barcode Beats 
%  This Matlab Script was used to visualiz the LUT for the DDS at 200 and
%  2000 HZ as well as how far the LUT sin was from an ideal sin
%  12/5/25 
%% --------------------------
% MATLAB Script to Visualize DDS Sine LUT
% Analyzes the 256-entry lookup table used in STM32L432KC DDS

clear all; close all; clc;

%% Define the LUT (from your DDS code)
sine_lut = [...
    2048, 2098, 2148, 2198, 2248, 2298, 2348, 2398, ...
    2447, 2496, 2545, 2594, 2642, 2690, 2737, 2784, ...
    2831, 2877, 2923, 2968, 3013, 3057, 3100, 3143, ...
    3185, 3226, 3267, 3307, 3346, 3385, 3423, 3459, ...
    3495, 3530, 3565, 3598, 3630, 3662, 3692, 3722, ...
    3750, 3777, 3804, 3829, 3853, 3876, 3898, 3919, ...
    3939, 3958, 3975, 3992, 4007, 4021, 4034, 4045, ...
    4056, 4065, 4073, 4080, 4085, 4089, 4093, 4094, ...
    4095, 4094, 4093, 4089, 4085, 4080, 4073, 4065, ...
    4056, 4045, 4034, 4021, 4007, 3992, 3975, 3958, ...
    3939, 3919, 3898, 3876, 3853, 3829, 3804, 3777, ...
    3750, 3722, 3692, 3662, 3630, 3598, 3565, 3530, ...
    3495, 3459, 3423, 3385, 3346, 3307, 3267, 3226, ...
    3185, 3143, 3100, 3057, 3013, 2968, 2923, 2877, ...
    2831, 2784, 2737, 2690, 2642, 2594, 2545, 2496, ...
    2447, 2398, 2348, 2298, 2248, 2198, 2148, 2098, ...
    2048, 1997, 1947, 1897, 1847, 1797, 1747, 1697, ...
    1648, 1599, 1550, 1501, 1453, 1405, 1358, 1311, ...
    1264, 1218, 1172, 1127, 1082, 1038, 995, 952, ...
    910, 869, 828, 788, 749, 710, 672, 636, ...
    600, 565, 530, 497, 465, 433, 403, 373, ...
    345, 318, 291, 266, 242, 219, 197, 176, ...
    156, 137, 120, 103, 88, 74, 61, 50, ...
    39, 30, 22, 15, 10, 6, 2, 1, ...
    0, 1, 2, 6, 10, 15, 22, 30, ...
    39, 50, 61, 74, 88, 103, 120, 137, ...
    156, 176, 197, 219, 242, 266, 291, 318, ...
    345, 373, 403, 433, 465, 497, 530, 565, ...
    600, 636, 672, 710, 749, 788, 828, 869, ...
    910, 952, 995, 1038, 1082, 1127, 1172, 1218, ...
    1264, 1311, 1358, 1405, 1453, 1501, 1550, 1599, ...
    1648, 1697, 1747, 1797, 1847, 1897, 1947, 1997];

%% Parameters
LUT_SIZE   = 256;
DAC_BITS   = 12;
DAC_MAX    = 2^DAC_BITS - 1;  % 4095
SAMPLE_RATE = 51200;          % Hz (for 200 Hz base frequency)
BASE_FREQ   = 200;            % Hz

%% Create index array
index = 0:LUT_SIZE-1;
angle = (index / LUT_SIZE) * 2 * pi;  % Angle in radians

%% Convert LUT to normalized values (-1 to +1)
lut_normalized = (sine_lut - 2048) / 2048;

%% Generate ideal sine wave for comparison
ideal_sine = sin(angle);

%% Calculate error
error     = lut_normalized - ideal_sine;
rms_error = sqrt(mean(error.^2));
max_error = max(abs(error));

%% Precompute 200 Hz and 2000 Hz signals
% 200 Hz at 51.2 kHz sample rate (256 samples per cycle)
sample_rate_200hz = 51200;                        % 200 Hz * 256
time_200hz        = (0:3*LUT_SIZE-1) / sample_rate_200hz;
signal_200hz      = repmat(lut_normalized, 1, 3); % 3 cycles

% 2000 Hz at fixed 51.2 kHz sample rate (step 10 through LUT)
fixed_sample_rate = 51200;
step_size_2000    = 10;                                % skip 10 entries per sample
num_samples_2000  = floor(3 * LUT_SIZE / step_size_2000);
signal_2000hz_fixed = zeros(1, num_samples_2000);
for i = 1:num_samples_2000
    lut_idx = mod((i-1) * step_size_2000, LUT_SIZE) + 1;
    signal_2000hz_fixed(i) = lut_normalized(lut_idx);
end
time_2000hz_fixed = (0:num_samples_2000-1) / fixed_sample_rate;

% Create stair-step version to show DAC hold behavior for 2000 Hz
time_2000hz_stairs   = [];
signal_2000hz_stairs = [];
for i = 1:length(time_2000hz_fixed)-1
    time_2000hz_stairs   = [time_2000hz_stairs,   time_2000hz_fixed(i), time_2000hz_fixed(i+1)];
    signal_2000hz_stairs = [signal_2000hz_stairs, signal_2000hz_fixed(i), signal_2000hz_fixed(i)];
end

%% Create figure with multiple subplots
figure('Position', [100 100 1200 900], 'Name', 'DDS LUT Analysis');

%% Subplot 1: LUT Values (DAC codes)
subplot(3, 2, 1);
plot(index, sine_lut, 'b.-', 'LineWidth', 1.5, 'MarkerSize', 4);
grid on;
xlabel('LUT Index');
ylabel('DAC Code (0-4095)');
title('Sine LUT - DAC Values');
ylim([0 DAC_MAX]);
xlim([0 LUT_SIZE-1]);

%% Subplot 2: Normalized comparison
subplot(3, 2, 2);
plot(angle, ideal_sine, 'r-', 'LineWidth', 2, 'DisplayName', 'Ideal Sine');
hold on;
plot(angle, lut_normalized, 'b.-', 'LineWidth', 1, 'MarkerSize', 4, 'DisplayName', 'LUT');
grid on;
xlabel('Angle (radians)');
ylabel('Amplitude (normalized)');
title('LUT vs Ideal Sine Wave');
legend('Location', 'best');
xlim([0 2*pi]);

%% Subplot 3: Error analysis
subplot(3, 2, 3);
plot(index, error, 'r.-', 'LineWidth', 1, 'MarkerSize', 4);
grid on;
xlabel('LUT Index');
ylabel('Error (normalized)');
title(sprintf('Quantization Error (RMS: %.6f, Max: %.6f)', rms_error, max_error));
xlim([0 LUT_SIZE-1]);

%% Subplot 4: 200 Hz waveform (variable step = 1, 256 pts/cycle)
subplot(3, 2, 4);
plot(time_200hz * 1000, signal_200hz, 'b-', 'LineWidth', 2);
grid on;
xlabel('Time (ms)');
ylabel('Amplitude (normalized)');
title('200 Hz Output (step = 1, 256 samples/cycle)');
xlim([0 max(time_200hz)*1000]);

%% Subplot 5: Step size between samples
subplot(3, 2, 5);
step_size_codes = diff(sine_lut);
plot(index(1:end-1), step_size_codes, 'g.-', 'LineWidth', 1, 'MarkerSize', 4);
grid on;
xlabel('LUT Index');
ylabel('Step Size (DAC codes)');
title('Step Size Between Consecutive Samples');
xlim([0 LUT_SIZE-2]);

%% Subplot 6: 2000 Hz waveform (fixed sample rate, LUT skipping)
subplot(3, 2, 6);
plot(time_2000hz_stairs * 1000, signal_2000hz_stairs, 'r-', 'LineWidth', 1.5, ...
     'DisplayName', '2000 Hz (step=10, 25.6 pts/cycle)');
hold on;
plot(time_2000hz_fixed * 1000, signal_2000hz_fixed, 'ko', 'MarkerSize', 6, ...
     'MarkerFaceColor', 'r', 'HandleVisibility', 'off');
grid on;
xlabel('Time (ms)');
ylabel('Amplitude (normalized)');
title('2000 Hz Output (fixed Fs, LUT stepping with DAC hold)');
legend('Location', 'best');
xlim([0 max(time_200hz)*1000]);

% Add annotation (single-line text to avoid string issues)
annotation_str = sprintf('Same sample rate = %.1f kHz,  200 Hz: 256 samples/cycle,  2000 Hz: 25.6 samples/cycle', ...
    fixed_sample_rate/1000);

text(0.02, 0.98, annotation_str, ...
    'Units', 'normalized', ...
    'VerticalAlignment', 'top', ...
    'BackgroundColor', 'white', ...
    'EdgeColor', 'black', ...
    'FontSize', 9);


%% Print statistics
fprintf('\n========== DDS LUT Statistics ==========');
