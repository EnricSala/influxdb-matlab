classdef SeriesResult < handle
    
    properties(Access = private)
        Name, Time, Tags, Fields, Values
    end
    
    methods
        % Constructor
        function obj = SeriesResult(name, time, tags, values)
            obj.Name = name;
            obj.Time = time;
            obj.Tags = tags;
            obj.Fields = {values.field};
            obj.Values = values;
        end
        
        % Get the name of the series
        function name = name(obj)
            name = obj.Name;
        end
        
        % Get the tags of the series
        function name = tags(obj)
            name = obj.Tags;
        end
        
        % Get the time, with an optional timezone
        function time = time(obj, timezone)
            time = obj.Time;
            if nargin > 1
                time.TimeZone = timezone;
            end
        end
        
        % List fields
        function fields = fields(obj)
            fields = obj.Fields;
        end
        
        % Check if the result contains these fields
        function present = contains(obj, varargin)
            check = @(x) ~isempty(obj.indexOf(x));
            present = arrayfun(check, varargin);
        end
        
        % Get the value of a field
        function values = field(obj, field)
            idx = obj.indexOf(field);
            assert(~isempty(idx), ['field "' field '" is not present']);
            values = obj.Values(idx).value;
        end
        
        % Convert to a table
        function result = table(obj)
            vars = {obj.Values.value};
            result = table(vars{:}, 'VariableNames', obj.fields());
        end
        
        % Convert to a timetable, with an optional timezone
        function ttable = timetable(obj, timezone)
            if nargin > 1
                time = obj.time(timezone);
            else
                time = obj.time();
            end
            vars = {obj.Values.value};
            ttable = timetable(time, vars{:}, 'VariableNames', obj.fields());
        end
    end
    
    methods(Access = private)
        % Find the position of a field
        function idx = indexOf(obj, field)
            match = strcmp(obj.fields(), field);
            idx = find(match, 1, 'first');
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
            
            % Extract the tags if present
            if isfield(serie, 'tags')
                tags = serie.tags;
            else
                tags = struct();
            end
            
            % Prepare the values in a cell format
            N = size(values, 1);
            fields = columns(2:end);
            if iscell(values)
                % Implies there are non-numeric values
                C = length(values{1});
                celled = cell(N, C);
                for i = 1:N
                    row = values{i};
                    if iscell(row)
                        % The row contains non-numeric values
                        celled(i, :) = row;
                    else
                        % The row is all numeric, or NaN
                        celled(i, :) = num2cell(row);
                    end
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
                column = celled(:, i);
                if all(cellfun(@(x) isnumeric(x), column))
                    % Convert to a numeric array
                    for j = 1:N
                        if isempty(column{j})
                            column{j} = NaN;
                        end
                    end
                    value = cell2mat(column);
                elseif any(cellfun(@(x) islogical(x), column))
                    % Convert to a logical array
                    value = zeros(N, 1);
                    for j = 1:N
                        item = column{j};
                        value(j) = iif(islogical(item), item, NaN);
                    end
                else
                    % Convert to a nested char cell
                    value = {column};
                end
                props(i - 1) = struct('field', field, 'value', value);
            end
            
            % Create the series result
            obj = SeriesResult(name, time, tags, props);
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
