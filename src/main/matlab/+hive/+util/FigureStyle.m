classdef FigureStyle
    %FIGURESTYLE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = protected)
        figure
        
        lineWidthMin
        lineWidthScale
        lineWidthFixed
        
        fontSizeMin
        fontSizeScale
        fontSizeFixed
        fontName
        fontWeight
    end
    
    methods (Access = protected)
        function tf = isLineConfigured(this)
            tf = any(cellfun(@(x) ~isempty(x), {
                this.lineWidthFixed
                this.lineWidthMin
                this.lineWidthScale
                }));
        end
        
        function tf = isFontConfigured(this)
            tf = any(cellfun(@(x) ~isempty(x), {
                this.fontSizeMin
                this.fontSizeScale
                this.fontSizeFixed
                this.fontName
                this.fontWeight
                }));
        end 
    end
    
    methods
        function this = FigureStyle(fig)
            this.figure = fig;
        end
        
        function this = withMinimumLineWidth(this, lw)
            this.lineWidthMin = lw;
            this.lineWidthFixed = [];
        end
        
        function this = withScaledLineWidth(this, s)
            this.lineWidthScale = s;
            this.lineWidthFixed = [];
        end
        
        function this = withFixedLineWidth(this, lw)
            this.lineWidthFixed = lw;
            this.lineWidthMin = [];
            this.lineWidthScale = [];
        end
        
        function this = withMinimumFontSize(this, fs)
            this.fontSizeMin = fs;
            this.fontSizeFixed = [];
        end
        
        function this = withScaledFontSize(this, s)
            this.fontSizeScale = s;
            this.fontSizeFixed = [];
        end
        
        function this = withFixedFontSize(this, fs)
            this.fontSizeFixed = fs;
            this.fontSizeMin = [];
            this.fontSizeScale = [];
        end
        
        function this = withFontName(this, fn)
            this.fontName = fn;
        end
        
        function this = withFontWeight(this, fw)
            this.fontWeight = fw;
        end
                
        function fig = apply(this)
            fig = this.figure;
            
            if this.isLineConfigured()
                lines = findobj(fig, '-property', 'LineWidth');
                
                if ~isempty(this.lineWidthScale)
                    arrayfun(@(l) set(l, 'LineWidth', this.lineWidthScale * get(l, 'LineWidth')), lines);
                end
                
                if ~isempty(this.lineWidthMin)
                    arrayfun(@(l) set(l, 'LineWidth', max(this.lineWidthMin, get(l, 'LineWidth'))), lines);
                end
                
                if ~isempty(this.lineWidthFixed)
                    arrayfun(@(l) set(l, 'LineWidth', this.lineWidthFixed), lines);
                end
            end
            
            if this.isFontConfigured()
                fonts = findobj(fig, '-property', 'FontName');
                
                if ~isempty(this.fontName)
                    arrayfun(@(f) set(f, 'FontName', this.fontName), fonts);
                end
                
                if ~isempty(this.fontWeight)
                    arrayfun(@(f) set(f, 'FontWeight', this.fontWeight), fonts);
                end
                
                if ~isempty(this.fontSizeScale)
                    arrayfun(@(f) set(f, 'FontSize', this.fontSizeScale * get(f, 'FontSize')), fonts);
                end
                
                if ~isempty(this.fontSizeMin)
                    arrayfun(@(f) set(f, 'FontSize', max(this.fontSizeMin, get(f, 'FontSize'))), fonts);
                end
                
                if ~isempty(this.fontSizeFixed)
                    arrayfun(@(f) set(f, 'FontSize', this.fontSizeFixed), fonts);
                end
            end
        end
    end
end

