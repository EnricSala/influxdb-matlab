classdef WriteBuilder < handle
    
    properties(Access = private)
        InfluxDB, Points;
    end
    
    methods
        % Constructor
        function obj = WriteBuilder()
            obj.InfluxDB = [];
            obj.Points = {};
        end
        
        % Set the client instance used for execution
        function obj = influxdb(obj, influxdb)
            obj.InfluxDB = influxdb;
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
            assert(~isempty(obj.InfluxDB), 'execute:clientNotSet', ...
                'the influxdb client is not set for this builder');
            lines = obj.build();
            obj.InfluxDB.runWrite(lines);
        end
    end
    
end
