classdef WriteBuilder < handle
    
    properties(Access = private)
        InfluxDB = []
        Items = {}
        Database = []
        Precision = 'ms'
        Consistency = []
        RetentionPolicy = []
    end
    
    methods
        % Set the client instance used for execution
        function obj = influxdb(obj, influxdb)
            obj.InfluxDB = influxdb;
        end
        
        % Configure the database
        function obj = database(obj, database)
            obj.Database = database;
        end
        
        % Configure the precision
        function obj = precision(obj, precision)
            obj.Precision = precision;
        end
        
        % Configure the retention policy
        function obj = retention(obj, retention)
            obj.RetentionPolicy = retention;
        end
        
        % Configure the consistency
        function obj = consistency(obj, consistency)
            obj.Consistency = consistency;
        end
        
        % Append series to the builder
        function obj = append(obj, varargin)
            for i = 1:length(varargin)
                item = varargin{i};
                for j = 1:length(item)
                    obj.Items{end + 1} = item(j);
                end
            end
        end
        
        % Build line protocol
        function lines = build(obj)
            if isempty(obj.Items)
                warning('this writer is empty');
                lines = '';
            else
                f = @(x) x.toLine(obj.Precision);
                items = cellfun(f, obj.Items, 'UniformOutput', false);
                nonempty = ~cellfun(@isempty, items);
                lines = strjoin(items(nonempty), newline);
            end
        end
        
        % Execute the write
        function [] = execute(obj)
            assert(~isempty(obj.InfluxDB), 'execute:clientNotSet', ...
                'the influxdb client is not set for this builder');
            lines = obj.build();
            obj.InfluxDB.runWrite(lines, obj.Database, ...
                obj.Precision, obj.RetentionPolicy, obj.Consistency);
        end
    end
    
end
