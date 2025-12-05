%% ============================================================
%  Leilani Elkaslasy and Thomas Lilygren 
%  E-155 Final Project: Barcode Beats 
%  This Matlab Script was used to generate a 256 entry SIN LUT for the MCU
%  DDS
%  12/5/25 
%% --------------------------
%  Plot: FIR-only output (48 kHz) with lollipop markers
%% --------------------------
clear; clc;

Ns     = 256;  % Number of LUT entries
RES    = 12;   % DAC resolution (12-bit)
OFFSET = 0;    % Output offset (if needed)

%------------[ Generate Sine Wave LUT ]------------------
T = linspace(0, 2*pi, Ns+1); 
T(end) = [];               % Remove last point so LUT wraps cleanly

Y = sin(T);                % -1 to +1
Y = (Y + 1) / 2;           % Now 0 to 1

maxDAC = (2^RES - 1);
Y = Y * (maxDAC - 2*OFFSET) + OFFSET;

Y = round(Y);              % Integer values for LUT

%------------[ Plot LUT ]--------------------------------
plot(T, Y);
title('256-Entry Sine LUT');
xlabel('Radians');
ylabel('DAC Value');
grid on;

%------------[ Print LUT Values ]-------------------------
fprintf('Sine LUT (%d entries):\n', Ns);
for k = 1:Ns
    fprintf('%d, ', Y(k));
    if mod(k, 16) == 0
        fprintf('\n');

    end
end
