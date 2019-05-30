function P1 = log_P1_fft(x, dim)
%LOG_1P_FFT Summary of this function goes here
%   Detailed explanation goes here
    narginchk(1, 2);
    
    if (nargin < 2)
        dim = 1;
    end
    
    assert(isreal(x), 'input array/matrix must be real-valued');
    assert(numel(size(x)) <= 2, 'input array/matrix can be of maximum 2 dimensions');
    assert(dim == 1 || dim == 2, 'dim can only be 1 or 2');
    
    % find the size of the vectors in the given  dimension
    nx = size(x, dim);
    
    % we want to return the 1-sided FFT, so we'll ask for at least
    % nx*2 points, however we might use more for performance:
    % find the next power of 2 for the FFT
    NFFT = 2^nextpow2(nx*2);
    
    % take FFT in given dimension, twice the size
    X = fft(x, NFFT, dim);
    
    % two-sided spectrum
    P2 = abs(X / nx);
    
    % return the one-sided spectrum
    % note: we can only do this because the signal is real, not complex
    if (dim == 1)
        P1 = P2(1:nx, :);
        P1(2:end-1, :) = 2*P1(2:end-1, :);
    else
        P1 = P2(:, 1:nx);
        P1(:, 2:end-1) = 2*P1(:, 2:end-1);
    end
    
    % convert to dB-like logorithmic
    P1 = 10 * log(P1);
end

