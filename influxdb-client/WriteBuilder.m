classdef WriteBuilder < handle
    
    properties(Access = private)
        Influx, Points;
    end
    
    methods
        % Constructor
        function obj = WriteBuilder(influx)
            obj.Influx = influx;
            obj.Points = {};
        end
        
        % Append points
        function obj = append(obj, varargin)
            for i = 1:length(varargin)
                item = varargin{i};
                for j = 1:length(item)
                    obj.Points{end + 1} = item(j);
                end
            end
        end
        
        % Build line protocol
        function str = build(obj)
            builder = java.lang.StringBuilder();
            for i = 1:length(obj.Points)
                point = obj.Points{i};
                builder.append(point.toLine());
                builder.append(newline);
            end
            builder.deleteCharAt(int32(builder.length() - 1));
            str = builder.toString().toCharArray()';
        end
        
        % Execute the write
        function [] = execute(obj)
            lines = obj.build();
            obj.Influx.rawWrite(lines);
        end
    end
    
end
