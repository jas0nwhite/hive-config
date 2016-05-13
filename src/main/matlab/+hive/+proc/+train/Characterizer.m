classdef Characterizer < hive.proc.ProcessorBase
    %CHARACTERIZER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        characterFile = 'characterization.mat';
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
               
        function c = characterizeVoltammogram(~, vgram)
            % define region of interest
            roi = vgram(1:60);
            nx = length(roi);
            
            % "resample" with spline to create smoother output
            xp = linspace(1, nx, 3000);
            yp = interp1(1:nx, roi, xp, 'spline');
            
            % subtract linear trend defined by endpoints of ROI
            yy = yp - linspace(yp(1), yp(end), length(yp));
            
            % find location and value of maximum
            maxIx = ceil(median(find(yy == max(yy))));
            
            % return coordinates of maximum
            c = [xp(maxIx), yp(maxIx)];
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
            t = tic;
            
            fprintf('%d/%d: ', sourceIx, nSources);
            
            directory = fullfile(this.cfg.resultPathList{setIx}, this.cfg.datasetCatalog{setIx}{sourceIx, 2});
            
            infile = fullfile(directory, this.cfg.vgramFile);
            outfile = fullfile(directory, this.characterFile);
            
            if this.overwrite || ~exist(outfile, 'file')
                load(infile);

                nSteps = length(voltammograms); %#ok<USENS>

                vgramChar = cell(nSteps, 1);

                fprintf('%s %d steps...', this.actionLabel, nSteps);

                for stepIx = 1:nSteps
                    vgramChar{stepIx} = this.processStep(voltammograms{stepIx});
                end

                save(outfile, 'vgramChar');
                
                fprintf(' %0.1fms\n', 1e3 * toc(t));
            else
                fprintf('SKIP.\n');
            end
        end
        
        function c = processStep(this, vgrams)
            nVgrams = size(vgrams, 2);
            
            c = nan(nVgrams, 2);
            
            for vgramIx = 1:nVgrams
                c(vgramIx, :) = this.characterizeVoltammogram(vgrams(:, vgramIx));
            end
        end
        
    end
        
end

