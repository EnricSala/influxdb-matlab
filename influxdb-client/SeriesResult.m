classdef SeriesResult < handle
    
    properties(Access = private)
        Name, Time, Tags, Fields, Values
    end
    
    methods
        % Constructor
        function obj = SeriesResult(name, time, tags, data)
            obj.Name = name;
            obj.Time = time;
            obj.Tags = tags;
            obj.Fields = {data.field};
            obj.Values = {data.value};
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
        function value = field(obj, field)
            idx = obj.indexOf(field);
            assert(~isempty(idx), ['field "' field '" is not present']);
            value = obj.Values{idx};
        end
        
        % Convert to a table
        function result = table(obj)
            names = genvarname(obj.Fields);
            result = table(obj.Values{:}, 'VariableNames', names);
        end
        
        % Convert to a timetable, with an optional timezone
        function result = timetable(obj, timezone)
            assert(~isempty(obj.Time), 'timetable:emptyTime', ...
                'cannot convert to a timetable because the time is empty');
            if nargin > 1
                time = obj.time(timezone);
            else
                time = obj.time();
            end
            names = genvarname(obj.Fields);
            result = timetable(time, obj.Values{:}, 'VariableNames', names);
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
        function obj = from(serie, epoch)
            fields = serie.columns;
            values = serie.values;
            
            % Obtain the name if present
            if isfield(serie, 'name')
                name = serie.name;
            else
                name = '';
            end
            
            % Obtain the tags if present
            if isfield(serie, 'tags')
                tags = serie.tags;
            else
                tags = struct();
            end
            
            % Check if the series is empty
            if isempty(fields) || isempty(values)
                warning(['serie "' name '" is empty']);
                obj = [];
                return
            end
            
            % Prepare the values in a cell format
            N = size(values, 1);
            if iscell(values)
                % There are non-numeric values
                celled = cell(N, length(values{1}));
                for i = 1:N
                    row = values{i};
                    if iscell(row)
                        celled(i, :) = row;
                    else
                        celled(i, :) = num2cell(row);
                    end
                end
            else
                % All values are numeric
                celled = num2cell(values);
            end
            
            % Check if the first field is the time
            if strcmp('time', fields{1})
                time_column = celled(:, 1);
                if isnumeric(time_column{1})
                    timestamps = cell2mat(time_column);
                    time = TimeUtils.toDatetime(timestamps, epoch);
                elseif ischar(time_column{1})
                    parse = @TimeUtils.parseTimestamp;
                    time = cellfun(parse, time_column);
                else
                    error('unsupported time type');
                end
                fields = fields(2:end);
                celled = celled(:, 2:end);
            else
                time = [];
            end
            
            % Format the fields as structs
            C = size(celled, 2);
            for i = C:-1:1
                field = fields{i};
                column = celled(:, i);
                if all(cellfun(@isnumeric, column))
                    % Convert to a numeric array
                    for j = 1:N
                        if isempty(column{j})
                            column{j} = NaN;
                        end
                    end
                    value = cell2mat(column);
                elseif any(cellfun(@islogical, column))
                    % Convert to a logical array
                    value = zeros(N, 1);
                    for j = 1:N
                        item = column{j};
                        value(j) = iif(islogical(item), item, NaN);
                    end
                else
                    % Convert to a nested char cell
                    for j = 1:N
                        if ~ischar(column{j})
                            column{j} = [];
                        end
                    end
                    value = {column};
                end
                props(i) = struct('field', field, 'value', value);
            end
            
            % Create the series result
            obj = SeriesResult(name, time, tags, props);
        end
    end
    
end
