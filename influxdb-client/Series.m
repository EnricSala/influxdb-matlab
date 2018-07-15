classdef Series < handle
    
    properties(Access = private)
        Name = []
        Tags = {}
        Fields = {}
        Time = []
    end
    
    methods
        % Constructor
        function obj = Series(name)
            obj.Name = name;
        end
        
        % Add a tag
        function obj = tag(obj, key, value)
            obj.Tags{end + 1} = [key '=' value];
        end
        
        % Add multiple tags at once
        function obj = tags(obj, varargin)
            forEachPair(varargin, @(k, v) obj.tag(k, v));
        end
        
        % Add a field value
        function obj = field(obj, key, value)
            if isempty(value)
                error('field:emptyValue', 'value of field "%s" is empty', key);
            elseif isnumeric(value) || islogical(value)
                field = struct('key', key, 'value', value);
                obj.Fields{end + 1} = field;
            elseif iscell(value)
                field = struct('key', key, 'value', {value});
                obj.Fields{end + 1} = field;
            else
                error('unsupported value type');
            end
        end
        
        % Add multiple fields at once
        function obj = fields(obj, varargin)
            forEachPair(varargin, @(k, v) obj.field(k, v));
        end
        
        % Set the time
        function obj = time(obj, time)
            if isdatetime(time)
                obj.Time = time;
            elseif isfloat(time)
                obj.Time = datetime(time, 'ConvertFrom', 'datenum', 'TimeZone', 'local');
            else
                error('unsupported time type');
            end
        end
        
        % Import data from other structures
        function obj = import(obj, data)
            if istimetable(data) || istable(data)
                insert = @(x) obj.field(x, data.(x));
                cellfun(insert, data.Properties.VariableNames);
                if istimetable(data)
                    obj.time(data.Properties.RowTimes);
                end
            else
                error('unsupported data structure');
            end
        end
        
        % Format to Line Protocol
        function lines = toLine(obj, precision)
            time_length = length(obj.Time);
            field_lengths = unique(cellfun(@(x) length(x.value), obj.Fields));
            
            % Make sure the dimensions match
            assert(~isempty(obj.Time), ...
                'toLine:emptyTime', 'the time vector cannot be empty');
            assert(~isempty(field_lengths), ...
                'toLine:emptyFields', 'must define at least one field');
            assert(length(field_lengths) == 1, ...
                'toLine:sizeMismatch', 'all fields must have the same length');
            assert(time_length == field_lengths || time_length == 0, ...
                'toLine:sizeMismatch', 'time and fields must have the same length');
            
            % Obtain the time precision scale
            if nargin < 2, precision = 'ms'; end
            scale = obj.timeScale(precision);
            timestamp = int64(scale * posixtime(obj.Time));
            
            % Create a line for each sample
            prefix = [strjoin([{obj.Name}, obj.Tags], ','), ' '];
            builder = '';
            for i = 1:field_lengths
                values = '';
                for f = 1:length(obj.Fields)
                    field = obj.Fields{f};
                    name = field.key;
                    value = field.value;
                    if iscell(value)
                        str = obj.fieldFmt(name, value{i});
                    else
                        str = obj.fieldFmt(name, value(i));
                    end
                    if ~isempty(str)
                        values = [values, str, ','];
                    end
                end
                if ~isempty(values)
                    values = values(1:end-1);
                    time = sprintf(' %i', timestamp(i));
                    builder = [builder, prefix, values, time, newline];
                end
            end
            lines = builder(1:end-1);
        end
    end
    
    methods(Static, Access = private)
        % Format a field
        function str = fieldFmt(key, value)
            if isfloat(value)
                if ~isempty(value) && isfinite(value)
                    str = sprintf('%s=%.8g', key, value);
                else
                    str = '';
                end
            elseif isinteger(value)
                str = sprintf('%s=%ii', key, value);
            elseif ischar(value)
                str = [key '="' value '"'];
            elseif islogical(value)
                str = [key '=' iif(value, 'true', 'false')];
            else
                error('unsupported value type');
            end
        end
        
        % Otain the scale for a precision
        function scale = timeScale(precision)
            switch precision
                case 'ns'
                    scale = 1000000000;
                case 'u'
                    scale = 1000000;
                case 'ms'
                    scale = 1000;
                case 's'
                    scale = 1;
                case 'm'
                    scale = 1 / 60;
                case 'h'
                    scale = 1 / 3600;
                otherwise
                    error('precision:unknown', '"%s" is not a valid precision', precision);
            end
        end
    end
    
end
