classdef SeriesResult < handle
    
    properties
        Name, Time, Values;
    end
    
    methods
        % Constructor
        function obj = SeriesResult(name, time, values)
            obj.Name = name;
            obj.Time = time;
            obj.Values = values;
        end
        
        % Get the time, with an optional timezone
        function time = time(obj, varargin)
            time = obj.Time;
            if nargin < 2
                time.TimeZone = 'local';
            else
                time.TimeZone = varargin{1};
            end
        end
        
        % List fields
        function fields = fields(obj)
            fields = {obj.Values.field};
        end
        
        % Find field position
        function idx = indexOf(obj, field)
            match = strcmp(obj.fields(), field);
            idx = find(match, 1, 'first');
        end
        
        % Test if field is present
        function present = isPresent(obj, field)
            present = ~isempty(obj.indexOf(field));
        end
        
        % Get the value of a field
        function values = field(obj, field)
            idx = obj.indexOf(field);
            assert(~isempty(idx), ['field "' field '" is not present']);
            values = obj.Values(idx).value;
        end
    end
    
    methods(Static)
        % Convert a series result to an object
        function obj = from(serie)
            name = serie.name;
            columns = serie.columns;
            values = serie.values;
            
            % Check if empty result
            if isempty(columns) || isempty(values)
                warning(['serie ''' name ''' is empty']);
                obj = [];
                return
            end
            
            % Prepare the values in a cell format
            fields = columns(2:end);
            if iscell(values)
                % Implies there are non-numeric values
                N = length(values);
                C = length(values{1});
                celled = cell(N, C);
                for i = 1:N
                    row = values{i};
                    celled(i, :) = row;
                end
                time = SeriesResult.toDatetime(cell2mat(celled(:, 1)));
            else
                % All values are numeric
                C = size(values, 2);
                time = SeriesResult.toDatetime(values(:, 1));
                celled = num2cell(values);
            end
            
            % Format the values as name/value structs
            for i = C:-1:2
                field = fields{i - 1};
                value = celled(:, i);
                if all(cellfun(@(x) isnumeric(x), value))
                    % If all values are numeric convert to an array
                    value = cell2mat(value);
                    if isempty(value), value = NaN(N, 1); end
                else
                    % Prevent an error creating the struct below
                    value = {value};
                end
                props(i - 1) = struct('field', field, 'value', value);
            end
            
            obj = SeriesResult(name, time, props);
        end
    end
    
    methods(Static, Access = private)
        % Convert a unix timestamp in millis to a datetime
        function [time] = toDatetime(timestamp)
            time = datetime(timestamp / 1000, ...
                'ConvertFrom', 'posixtime', 'TimeZone', 'local');
        end
    end
    
end
