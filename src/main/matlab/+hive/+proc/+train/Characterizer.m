classdef Characterizer < hive.proc.ProcessorBase
    %CHARACTERIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
    end
    
    %
    % API
    %
    methods
        
        function this = Characterizer(cfg)
            this.treatment = cfg;
            this.cfg = cfg.training;
            this.actionLabel = 'Characterizing';
        end
        
    end
    
    %
    % IMPLEMENTATION
    %
    methods (Access = protected)
        
        function argv = getArgsForProcessSource(this, setIx)
            argv = {length(this.cfg.datasetCatalog{setIx})};
        end
        
        function processSource(this, setIx, sourceIx, nSources)
            [id, name, ~] = this.cfg.getSourceInfo(setIx, sourceIx);
            
            fprintf('    dataset %03d (%d files): %s... ', id, nSources, name);
            t = tic;
            
            directory = fullfile(this.cfg.resultPathList{setIx}, this.cfg.datasetCatalog{setIx}{sourceIx, 2});
            
            infile = fullfile(directory, this.cfg.vgramFile);
            outfile = fullfile(directory, this.cfg.characterizationFile);
            
            if this.overwrite || ~exist(outfile, 'file')
                load(infile);
                
                nSteps = length(voltammograms); %#ok<USENS>
                
                vgramChar = cell(nSteps, 1);
                
                fprintf('%s %d steps...', this.actionLabel, nSteps);
                
                for stepIx = 1:nSteps
                    vgramChar{stepIx} = this.processStep(voltammograms{stepIx});
                end
                
                save(outfile, 'vgramChar');
                
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

