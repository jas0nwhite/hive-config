classdef (Abstract) CharacterizerBase < hive.proc.ProcessorBase
    %CHARACTERIZERBASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
    end
    
    %
    % API
    %
    methods
               
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
        function argv = getArgsForProcessSource(this, setIx)
            argv = {
                this.cfg.getSetValue(this.cfg.importPathList, setIx);
                this.cfg.getSetValue(this.cfg.resultPathList, setIx);
                };
        end
        
        function processSource(this, setIx, sourceIx, inPath, outPath)
            [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx);
            
            fprintf('    dataset %03d: %s... ', id, name);
            t = tic;
            
            infile = fullfile(inPath, name, this.cfg.vgramFile);
            outfile = fullfile(outPath, name, this.cfg.characterizationFile);
            
            if this.overwrite || ~exist(outfile, 'file')
                load(infile);
                
                nSteps = length(voltammograms); %#ok<USENS>
                
                vgramChar = cell(nSteps, 1);
                
                fprintf('%d steps...', nSteps);
                
                for stepIx = 1:nSteps
                    vgramChar{stepIx} = this.processStep(voltammograms{stepIx});
                end
                
                save(outfile, 'vgramChar');
                hive.util.appendDatasetInfo(cvTestFile, name, id, setIx, sourceIx, this.treatment.name);
                
                fprintf(' %0.3fs\n', toc(t));
            else
                fprintf('SKIP.\n');
            end
        end
        
        function c = processStep(~, vgrams)
            nVgrams = size(vgrams, 2);
            
            c = nan(nVgrams, 2);
            
            for vgramIx = 1:nVgrams
                [x, y] = hive.proc.analyze.characterizeVoltammogram(vgrams(:, vgramIx));
                c(vgramIx, :) = [x, y];
            end
        end
        
    end
    
end

