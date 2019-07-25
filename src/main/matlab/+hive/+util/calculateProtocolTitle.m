function [voltageProtocol] = calculateProtocolTitle(protocol, sampleRange, fSample)

    if (~isempty(regexp(lower(protocol), '_(uncorrelated|rbv[^_]*)_', 'once')))
        voltageProtocol = 'random burst';
    else
        % TODO: these calculations assume ±2V
        voltage = 2;
        seconds = sampleRange / fSample;
        vps = round(voltage * 2 / seconds);
        voltageProtocol = sprintf('%dV/s', vps);
    end
    
end

